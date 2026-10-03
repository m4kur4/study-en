param(
  [ValidateSet("staged", "push")]
  [string]$Mode = "staged",
  [string]$Root = ""
)

$ErrorActionPreference = "Continue"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root
Set-Location $root

function Fail([string]$Category, [string]$File) {
  Write-Output "scan-public: $Category $File"
  exit 1
}

$maskPath = Join-Path $root "notes\private-mask.txt"
if (-not (Test-Path -LiteralPath $maskPath)) { Fail "mask-file" "notes/private-mask.txt" }
$maskLines = @(Get-Content -LiteralPath $maskPath -Encoding UTF8 | Where-Object {
  $_ -match '\S' -and -not $_.TrimStart().StartsWith("#")
})
if ($maskLines.Count -eq 0) { Fail "mask-file" "notes/private-mask.txt" }

function Get-ScanFiles {
  if ($Mode -eq "staged") {
    return @(git diff --cached --name-only --diff-filter=ACMR)
  }
  git rev-parse --verify origin/HEAD 1>$null 2>$null
  if ($LASTEXITCODE -eq 0) {
    return @(git diff --name-only origin/HEAD...HEAD)
  }
  return @(git ls-files)
}

$files = Get-ScanFiles | Where-Object { $_ -and ($_ -notmatch '(?i)private-mask\.txt$') }
$drive = '[A-Z]:\\' + 'Users\\'
$profileDir = '/' + 'Users/'
$patterns = @(
  @{ Name = "email"; Regex = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' },
  @{ Name = "phone"; Regex = '(?:\+\d[\d\-\s()]{8,}\d|\b0\d{1,3}[- ]\d{2,4}[- ]\d{3,4}\b)' },
  @{ Name = "card"; Regex = '(?<!\d)\d{13,19}(?!\d)' },
  @{ Name = "private-key"; Regex = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
  @{ Name = "token"; Regex = '\b(?:ghp_|github_pat_|AKIA|xox[baprs]-|sk-)[A-Za-z0-9_\-]{8,}' },
  @{ Name = "path"; Regex = ('(?i)(?:' + $drive + '|' + $profileDir + ')') },
  @{ Name = "private-url"; Regex = 'https?://\S*[?&/=][A-Za-z0-9_\-]{20,}' }
)

foreach ($rel in $files) {
  $full = Join-Path $root ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $full)) { continue }
  $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
  if ($null -eq $text) { continue }
  foreach ($pattern in $patterns) {
    if ($text -match $pattern.Regex) { Fail $pattern.Name ($rel -replace '\\', '/') }
  }
  foreach ($secret in $maskLines) {
    if ($text.Contains($secret)) { Fail "mask-list" ($rel -replace '\\', '/') }
  }
}

exit 0
