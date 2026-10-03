$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$gitDir = Join-Path $root ".git"
if (-not (Test-Path -LiteralPath $gitDir)) { throw "install-hook: git repository is missing" }
$hookDir = Join-Path $gitDir "hooks"
if (-not (Test-Path -LiteralPath $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
$hook = Join-Path $hookDir "pre-commit"
$content = "#!/bin/sh`nexec sh scripts/git-hooks/pre-commit`n"
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($hook, $content, $utf8)
$bytes = [System.IO.File]::ReadAllBytes($hook)
if ($bytes -contains 13) {
  Remove-Item -LiteralPath $hook -Force
  throw "install-hook: CR found in .git/hooks/pre-commit"
}
Write-Output "install-hook: ok"
exit 0
