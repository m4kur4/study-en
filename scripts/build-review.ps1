param(
  [string]$Root = "",
  [Parameter(Mandatory = $true)][string]$Date
)

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root
Set-Location $root

function Fail([string]$Name, [string]$File) {
  Write-Output "build-review: $Name $File"
  exit 1
}

try {
  [void][datetime]::ParseExact($Date, "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
} catch {
  Fail "date" $Date
}

$logPath = Join-Path $root "notes\log\$Date.md"
if (-not (Test-Path -LiteralPath $logPath)) { Fail "log-missing" "notes/log/$Date.md" }

$indexPath = Join-Path $root "notes\index.md"
if (-not (Test-Path -LiteralPath $indexPath)) { Fail "index-missing" "notes/index.md" }

function As-Text([string]$Value) {
  if ($null -eq $Value) { return "" }
  return $Value.Trim()
}

function Get-Section([string]$Text, [string]$Name) {
  if ([string]::IsNullOrEmpty($Text)) { return $null }
  $pattern = '(?ms)^## ' + [regex]::Escape($Name) + '\r?\n(.*?)(?=^## |\z)'
  $match = [regex]::Match($Text, $pattern)
  if (-not $match.Success) { return $null }
  return $match.Groups[1].Value.Trim()
}

$byHeading = @{}
foreach ($line in (Get-Content -LiteralPath $indexPath -Encoding UTF8)) {
  if ($line -notmatch '^notes\/.+ \| .+ \| (casual|neutral|formal) \| .+ \| (phrase|once)$') { continue }
  $parts = $line -split ' \| '
  $byHeading[$parts[1].Trim()] = @{
    Path = $parts[0].Trim()
    Register = $parts[2].Trim()
    Ja = $parts[3].Trim()
    Kind = $parts[4].Trim()
  }
}

$nl = "`n"
$seen = @{}
$cards = New-Object System.Collections.Generic.List[string]
foreach ($line in (Get-Content -LiteralPath $logPath -Encoding UTF8)) {
  if ($line -notmatch '^.+ \| (phrase|once) \| .+ \| (new|update)$') { continue }
  $heading = ($line -split ' \| ')[0].Trim()
  if ($seen.ContainsKey($heading)) { continue }
  $seen[$heading] = $true
  if (-not $byHeading.ContainsKey($heading)) { Fail "review-index-miss" $heading }
  $item = $byHeading[$heading]
  $full = Join-Path $root ($item.Path -replace '/', '\')
  if (-not (Test-Path -LiteralPath $full)) { Fail "review-missing-file" $item.Path }
  $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
  $meaning = Get-Section $text "意味"
  $example = Get-Section $text "例"
  $sound = Get-Section $text "発音"
  $scene = Get-Section $text "場面"
  if ($null -eq $meaning) {
    if ($item.Kind -eq "once") {
      $meaning = $item.Ja
      $example = ""
      $sound = ""
    } else {
      Fail "review-section" $heading
    }
  }
  if ($null -eq $example) { $example = "" }
  if ($null -eq $sound) { $sound = "" }
  if ([string]::IsNullOrWhiteSpace($scene)) { $scene = $item.Register }
  $safeHeading = As-Text $heading
  $safeScene = As-Text $scene
  $safeMeaning = As-Text $meaning
  $safeExample = As-Text $example
  $safeSound = As-Text $sound
  $card = "## $safeHeading$nl$nl"
  $card += "### 場面$nl$nl$safeScene$nl$nl"
  $card += "### 意味$nl$nl$safeMeaning$nl$nl"
  $card += "### 例$nl$nl$safeExample$nl$nl"
  $card += "### 発音$nl$nl$safeSound"
  $cards.Add($card)
}

$body = $cards -join "$nl$nl"
$md = "# 復習 $Date$nl$nl" + "件数: $($cards.Count)$nl$nl" + $body + $nl

$reviewDir = Join-Path $root "review"
if (-not (Test-Path -LiteralPath $reviewDir)) {
  New-Item -ItemType Directory -Path $reviewDir | Out-Null
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $reviewDir "$Date.md"), $md, $utf8)
$htmlPath = Join-Path $reviewDir "$Date.html"
if (Test-Path -LiteralPath $htmlPath) {
  Remove-Item -LiteralPath $htmlPath -Force
}
exit 0
