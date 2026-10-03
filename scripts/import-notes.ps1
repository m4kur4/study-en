param(
  [Parameter(Mandatory = $true)]
  [string]$SourceDir,
  [string]$SourceLabel = "投入",
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root
Set-Location $root

function Get-Slug([string]$Heading) {
  $slug = $Heading.ToLowerInvariant()
  $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-").Trim("-")
  if (-not $slug) { $slug = "phrase" }
  return $slug
}

function Get-Section([string]$Text, [string]$Name) {
  $match = [regex]::Match($Text, "(?ms)^## $Name\s*\r?\n(.*?)(?=^## |\z)")
  if (-not $match.Success) { return "" }
  return $match.Groups[1].Value.Trim()
}

function Get-FirstSentence([string]$Text) {
  $line = ($Text -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -First 1)
  if (-not $line) { return "" }
  $cut = $line.IndexOf("。")
  if ($cut -ge 0) { return $line.Substring(0, $cut + 1).Trim() }
  return $line.Trim()
}

$tz = [TimeZoneInfo]::FindSystemTimeZoneById("Tokyo Standard Time")
$today = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString("yyyy-MM-dd")
$sourceRoot = (Resolve-Path -LiteralPath $SourceDir).Path
$indexPath = Join-Path $root "notes\index.md"
$indexLines = @(Get-Content -LiteralPath $indexPath -Encoding UTF8)
$known = @{}
foreach ($line in $indexLines) {
  if ($line -match '^notes/\S+ \| (.+?) \| ') { $known[$Matches[1].Trim()] = $true }
}

$utf8 = New-Object System.Text.UTF8Encoding $false
$logRows = New-Object System.Collections.Generic.List[string]

foreach ($file in (Get-ChildItem -LiteralPath $sourceRoot -Filter "*.md" -File)) {
  $text = [System.IO.File]::ReadAllText($file.FullName)
  if ($text -notmatch '(?m)^#\s+(.+)$') { throw "import-notes: heading $($file.Name)" }
  $heading = $Matches[1].Trim()
  if ($text -notmatch '(?m)^## 意味\s*$' -or $text -notmatch '(?m)^## 例\s*$') {
    throw "import-notes: section $($file.Name)"
  }
  $register = "neutral"
  $scene = Get-Section $text "場面"
  if ($scene) {
    $token = ($scene -split '\s+')[0].Trim()
    if ($token -notin @("casual", "neutral", "formal")) { throw "import-notes: register $($file.Name)" }
    $register = $token
  }
  $ja = Get-FirstSentence (Get-Section $text "意味")
  if (-not $ja) { throw "import-notes: meaning $($file.Name)" }
  $slug = Get-Slug $heading
  $rel = "notes/phrases/$slug.md"
  $dest = Join-Path $root "notes\phrases\$slug.md"
  [System.IO.File]::WriteAllText($dest, $text.TrimEnd() + "`n", $utf8)
  if (-not $known.ContainsKey($heading)) {
    $indexLines += "$rel | $heading | $register | $ja | phrase"
    $known[$heading] = $true
    $logRows.Add("$heading | phrase | $SourceLabel | new")
  } else {
    for ($i = 0; $i -lt $indexLines.Count; $i++) {
      if ($indexLines[$i] -match ('^notes/\S+ \| ' + [regex]::Escape($heading) + ' \| ')) {
        $indexLines[$i] = "$rel | $heading | $register | $ja | phrase"
        break
      }
    }
    $logRows.Add("$heading | phrase | $SourceLabel | update")
  }
}

$onceDir = Join-Path $sourceRoot "once"
if (Test-Path -LiteralPath $onceDir) {
  $onceRel = "notes/once/$today.md"
  $onceDest = Join-Path $root "notes\once\$today.md"
  $onceBody = ""
  if (Test-Path -LiteralPath $onceDest) {
    $onceBody = [System.IO.File]::ReadAllText($onceDest)
  } else {
    $onceBody = "# $today`n"
  }
  foreach ($file in (Get-ChildItem -LiteralPath $onceDir -Filter "*.md" -File)) {
    $text = [System.IO.File]::ReadAllText($file.FullName).Trim()
    $heading = $file.BaseName
    if ($text -match '(?m)^#\s+(.+)$') { $heading = $Matches[1].Trim() }
    if ($onceBody -notlike "*$heading*") {
      $ja = Get-FirstSentence (Get-Section $text "意味")
      if (-not $ja) { $ja = $heading }
      $onceBody += "`n## $heading`n`n$text`n"
      if (-not $known.ContainsKey($heading)) {
        $indexLines += "$onceRel | $heading | neutral | $ja | once"
        $known[$heading] = $true
        $logRows.Add("$heading | once | $SourceLabel | new")
      }
    }
  }
  [System.IO.File]::WriteAllText($onceDest, $onceBody, $utf8)
}

[System.IO.File]::WriteAllLines($indexPath, $indexLines, $utf8)
if ($logRows.Count -gt 0) {
  $logPath = Join-Path $root "notes\log\$today.md"
  $logBody = ""
  if (Test-Path -LiteralPath $logPath) { $logBody = [System.IO.File]::ReadAllText($logPath) }
  else { $logBody = "# $today`n" }
  foreach ($row in $logRows) { $logBody += "$row`n" }
  [System.IO.File]::WriteAllText($logPath, $logBody, $utf8)
}

Write-Output "import-notes: $($logRows.Count)"
exit 0
