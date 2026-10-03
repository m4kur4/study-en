param([string]$Root = "")

$ErrorActionPreference = "Continue"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root

function Report([string]$Name, [string]$File, [string]$Fix) {
  Write-Output "setup: $Name $File"
  Write-Output "fix: $Fix"
}

$maskPath = Join-Path $root "notes\private-mask.txt"
$maskFix = "氏名、学校名、勤務先、非公開のアカウント名を、notes/private-mask.txt へ1行ずつ自分で書く。チャットには書かない。仮の1行は足さない。空のあいだは commit しない。"
if (-not (Test-Path -LiteralPath $maskPath)) {
  Report "mask-missing" "notes/private-mask.txt" ("空の notes/private-mask.txt を作る。" + $maskFix)
} else {
  $maskLines = @(Get-Content -LiteralPath $maskPath -Encoding UTF8 | Where-Object {
    $_ -match '\S' -and -not $_.TrimStart().StartsWith("#")
  })
  if ($maskLines.Count -eq 0) {
    Report "mask-empty" "notes/private-mask.txt" $maskFix
  }
}

$files = @(
  "notes/index.md",
  "notes/optimize.md",
  "notes/quiz.md",
  "notes/ask.md"
)
foreach ($rel in $files) {
  $full = Join-Path $root ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $full)) {
    Report "file-missing" $rel "Readme.md の手順で $rel を用意する。学習者の表現は作らない。"
  }
}

$dirs = @("notes/phrases", "notes/once", "notes/log")
foreach ($rel in $dirs) {
  $full = Join-Path $root ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $full)) {
    Report "dir-missing" $rel "Readme.md の手順で $rel を作る。"
  }
}

$phraseDir = Join-Path $root "notes\phrases"
if ((Test-Path -LiteralPath $phraseDir) -and -not (Get-ChildItem -LiteralPath $phraseDir -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
  Report "phrases-empty" "notes/phrases" "docs/initial-load.md の形で表現ファイルを用意し、scripts/import-notes.ps1 を実行する。続けて scripts/build-quiz.ps1 を実行する。学習者の表現は作らない。"
}

$optPath = Join-Path $root "notes\optimize.md"
if (Test-Path -LiteralPath $optPath) {
  $opt = Get-Content -LiteralPath $optPath -Encoding UTF8
  foreach ($label in @("索引", "クイズ", "最終チャット")) {
    $found = $false
    foreach ($line in $opt) {
      if ($line -match "^${label}:\s*\d{4}-\d{2}-\d{2}\s*$") { $found = $true }
    }
    if (-not $found) {
      Report "optimize-date" "notes/optimize.md" "索引、クイズ、最終チャットを YYYY-MM-DD で書く。読めないときだけ、索引は日本時間の前日、クイズと最終チャットは今日にする。未来の日付は入れない。"
      break
    }
  }
}

$hook = Join-Path $root ".git\hooks\pre-commit"
if (-not (Test-Path -LiteralPath (Join-Path $root ".git"))) {
  Report "git-missing" ".git" "clone したこのフォルダを、Cursor のワークスペースとして開く。"
} elseif (-not (Test-Path -LiteralPath $hook)) {
  Report "hook-missing" ".git/hooks/pre-commit" "リポジトリのルートで、powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-hook.ps1 を実行する。"
} else {
  $hookBytes = [System.IO.File]::ReadAllBytes($hook)
  if ($hookBytes -contains 13) {
    Report "hook-cr" ".git/hooks/pre-commit" "scripts/install-hook.ps1 を再実行する。CR が残る起動ファイルは消してから作る。"
  }
}

exit 0
