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

function Escape-Html([string]$Value) {
  if ($null -eq $Value) { return "" }
  $Value = $Value -replace '&', '&amp;'
  $Value = $Value -replace '<', '&lt;'
  $Value = $Value -replace '>', '&gt;'
  $Value = $Value -replace '"', '&quot;'
  return $Value
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
  $safeHeading = Escape-Html $heading
  $safeScene = Escape-Html $scene
  $safeMeaning = Escape-Html $meaning
  $safeExample = Escape-Html $example
  $safeSound = Escape-Html $sound
  $card = "<article class=`"card`">$nl<h2>$safeHeading</h2>$nl"
  $card += "<section><h3>場面</h3><p>$safeScene</p></section>$nl"
  $card += "<section><h3>意味</h3><p>$safeMeaning</p></section>$nl"
  $card += "<section><h3>例</h3><p>$safeExample</p></section>$nl"
  $card += "<section><h3>発音</h3><p>$safeSound</p></section>$nl"
  $card += "</article>"
  $cards.Add($card)
}

$style = @'
body{font-family:sans-serif;line-height:1.5;max-width:40rem;margin:2rem auto;padding:0 1rem;}
h1{font-size:1.5rem;}
.count{margin:0 0 1.5rem;}
.card{border-top:1px solid #ccc;padding:1rem 0;}
.card h2{font-size:1.25rem;margin:0 0 0.75rem;}
.card h3{font-size:0.9rem;margin:0.75rem 0 0.25rem;}
.card p{margin:0;white-space:pre-wrap;}
'@
$title = "復習 $Date"
$body = $cards -join $nl
$html = @"
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
$style
</style>
</head>
<body>
<h1>$title</h1>
<p class="count">件数: $($cards.Count)</p>
$body
</body>
</html>
"@

$reviewDir = Join-Path $root "review"
if (-not (Test-Path -LiteralPath $reviewDir)) {
  New-Item -ItemType Directory -Path $reviewDir | Out-Null
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $reviewDir "$Date.html"), $html, $utf8)
exit 0
