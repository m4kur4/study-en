param([string]$Root = "")

$ErrorActionPreference = "Continue"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root
Set-Location $root

function Fail([string]$Name, [string]$File) {
  Write-Output "check-notebook: $Name $File"
  exit 1
}

$hook = Join-Path $root ".git\hooks\pre-commit"
if (-not (Test-Path $hook)) {
  Fail "hook-missing" ".git/hooks/pre-commit"
}
$hookBytes = [System.IO.File]::ReadAllBytes($hook)
if ($hookBytes -contains 13) {
  Fail "hook-cr" ".git/hooks/pre-commit"
}

$optPath = Join-Path $root "notes\optimize.md"
if (-not (Test-Path $optPath)) { Fail "optimize-missing" "notes/optimize.md" }
$opt = Get-Content -LiteralPath $optPath -Encoding UTF8
function Read-Date([string]$Label) {
  foreach ($line in $opt) {
    if ($line -match "^${Label}:\s*(\d{4}-\d{2}-\d{2})\s*$") {
      return [datetime]::ParseExact($Matches[1], "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
    }
  }
  return $null
}
$indexDate = Read-Date "索引"
$quizDate = Read-Date "クイズ"
$chatDate = Read-Date "最終チャット"
if (-not $indexDate) { Fail "optimize-date" "notes/optimize.md" }
if (-not $quizDate) { Fail "optimize-date" "notes/optimize.md" }
if (-not $chatDate) { Fail "optimize-date" "notes/optimize.md" }
$tz = [TimeZoneInfo]::FindSystemTimeZoneById("Tokyo Standard Time")
$today = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).Date
if ($indexDate.Date -gt $today -or $quizDate.Date -gt $today -or $chatDate.Date -gt $today) {
  Fail "optimize-future" "notes/optimize.md"
}

git rev-parse --verify HEAD 1>$null 2>$null
if ($LASTEXITCODE -eq 0) {
  git fsck --no-progress 1>$null 2>$null
  if ($LASTEXITCODE -ne 0) { Fail "git-fsck" ".git" }
}

$indexPath = Join-Path $root "notes\index.md"
if (-not (Test-Path $indexPath)) { Fail "index-missing" "notes/index.md" }
$rowPattern = '^notes\/.+ \| .+ \| (casual|neutral|formal) \| .+ \| (phrase|once)$'
$indexed = @{}
$lineNo = 0
foreach ($line in (Get-Content -LiteralPath $indexPath -Encoding UTF8)) {
  $lineNo++
  if ($line -match '^\s*$' -or $line.StartsWith("#") -or $line.StartsWith("path |")) { continue }
  if ($line -notmatch $rowPattern) { Fail "index-row" "notes/index.md:$lineNo" }
  $path = ($line -split ' \| ')[0].Trim()
  if (-not (Test-Path -LiteralPath (Join-Path $root ($path -replace '/', '\')))) {
    Fail "index-missing-file" $path
  }
  $indexed[$path] = $true
}

$tracked = @(git ls-files -- "notes/phrases/*.md")
foreach ($rel in $tracked) {
  $rel = ($rel -replace '\\', '/')
  if (-not $indexed.ContainsKey($rel)) { Fail "phrase-not-indexed" $rel }
  $full = Join-Path $root ($rel -replace '/', '\')
  $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($text)) { Fail "phrase-empty" $rel }
  if ($text -notmatch '(?m)^## 意味\s*$' -or $text -notmatch '(?m)^## 例\s*$') {
    Fail "phrase-section" $rel
  }
}

exit 0
