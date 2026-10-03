$ErrorActionPreference = "Continue"
$repo = Split-Path $PSScriptRoot -Parent
$pass = 0
$fail = 0

function Check([string]$Name, [bool]$Ok) {
  if ($Ok) {
    $script:pass++
    Write-Output "PASS $Name"
  } else {
    $script:fail++
    Write-Output "FAIL $Name"
  }
}

function New-Fixture {
  $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("en-notebook-" + [guid]::NewGuid().ToString("n"))
  New-Item -ItemType Directory -Path @(
    "$dir\notes\phrases", "$dir\notes\once", "$dir\notes\log", "$dir\.git\hooks"
  ) -Force | Out-Null
  Push-Location $dir
  git init --quiet
  Pop-Location
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText("$dir\.git\hooks\pre-commit", "#!/bin/sh`n", $utf8)
  $tz = [TimeZoneInfo]::FindSystemTimeZoneById("Tokyo Standard Time")
  $today = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).Date
  $opt = "索引: $($today.AddDays(-1).ToString('yyyy-MM-dd'))`nクイズ: $($today.ToString('yyyy-MM-dd'))`n最終チャット: $($today.ToString('yyyy-MM-dd'))`n"
  [System.IO.File]::WriteAllText("$dir\notes\optimize.md", $opt, $utf8)
  [System.IO.File]::WriteAllText("$dir\notes\index.md", "# 索引`n`npath | heading | register | ja | kind`n", $utf8)
  [System.IO.File]::WriteAllText("$dir\notes\private-mask.txt", "", $utf8)
  return $dir
}

function Invoke-Tool([string]$File, [string[]]$ArgList) {
  $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $File @ArgList 2>&1 | Out-String
  return @{ Code = $LASTEXITCODE; Text = $output.Trim() }
}

function Set-Index([string]$Dir, [string]$Line) {
  $utf8 = New-Object System.Text.UTF8Encoding $false
  $text = "# 索引`n`npath | heading | register | ja | kind`n$Line`n"
  [System.IO.File]::WriteAllText("$Dir\notes\index.md", $text, $utf8)
}

$check = Join-Path $repo "scripts\check-notebook.ps1"
$setup = Join-Path $repo "scripts\check-setup.ps1"
$scan = Join-Path $repo "scripts\scan-public.ps1"
$quiz = Join-Path $repo "scripts\build-quiz.ps1"
$import = Join-Path $repo "scripts\import-notes.ps1"
$utf8 = New-Object System.Text.UTF8Encoding $false

$dir = New-Fixture
$result = Invoke-Tool $check @("-Root", $dir)
Check "empty notebook passes" ($result.Code -eq 0)
Remove-Item "$dir\.git\hooks\pre-commit" -Force
$result = Invoke-Tool $setup @("-Root", $dir)
Check "setup reports empty mask" ($result.Code -eq 0 -and $result.Text -match "setup: mask-empty" -and $result.Text -match "仮の1行は足さない")
Check "setup reports missing phrases" ($result.Text -match "setup: phrases-empty" -and $result.Text -match "import-notes.ps1")
Check "setup reports missing files" ($result.Text -match "setup: file-missing notes/ask.md" -and $result.Text -match "setup: file-missing notes/quiz.md")
Check "setup reports missing hook" ($result.Text -match "setup: hook-missing" -and $result.Text -match "install-hook.ps1")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\private-mask.txt", "mask-sample`n", $utf8)
[System.IO.File]::WriteAllText("$dir\notes\ask.md", "# ask`n", $utf8)
[System.IO.File]::WriteAllText("$dir\notes\quiz.md", "# quiz`n", $utf8)
[System.IO.File]::WriteAllText("$dir\notes\phrases\one.md", "# One`n", $utf8)
$result = Invoke-Tool $setup @("-Root", $dir)
Check "complete setup is quiet" ($result.Code -eq 0 -and $result.Text -notmatch "setup:")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\.git\hooks\pre-commit", "#!/bin/sh`r`n", $utf8)
$result = Invoke-Tool $check @("-Root", $dir)
Check "CR in hook fails" ($result.Code -ne 0 -and $result.Text -match "hook-cr")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\optimize.md", "索引: 2099-01-01`nクイズ: 2099-01-01`n最終チャット: 2099-01-01`n", $utf8)
$result = Invoke-Tool $check @("-Root", $dir)
Check "future date fails" ($result.Code -ne 0 -and $result.Text -match "optimize-future")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
Set-Index $dir "notes/phrases/missing.md | Missing | neutral | 無い。 | phrase"
$result = Invoke-Tool $check @("-Root", $dir)
Check "missing phrase file fails" ($result.Code -ne 0 -and $result.Text -match "index-missing-file")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
$body = "# Sample`n`n## 意味`n`n見本です。`n"
[System.IO.File]::WriteAllText("$dir\notes\phrases\sample.md", $body, $utf8)
Set-Index $dir "notes/phrases/sample.md | Sample | neutral | 見本です。 | phrase"
Push-Location $dir
git add -- "notes/phrases/sample.md" | Out-Null
Pop-Location
$result = Invoke-Tool $check @("-Root", $dir)
Check "missing example section fails" ($result.Code -ne 0 -and $result.Text -match "phrase-section")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
$result = Invoke-Tool $scan @("-Root", $dir, "-Mode", "staged")
Check "empty mask fails" ($result.Code -ne 0 -and $result.Text -match "mask-file")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\private-mask.txt", "Placeholder`n", $utf8)
[System.IO.File]::WriteAllText("$dir\notes\log\sample.md", "hello`n", $utf8)
Push-Location $dir
git add -- "notes/log/sample.md" | Out-Null
Pop-Location
$result = Invoke-Tool $scan @("-Root", $dir, "-Mode", "staged")
Check "clean text passes scan" ($result.Code -eq 0)
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\private-mask.txt", "Placeholder`n", $utf8)
$sampleAddress = "person" + "@" + "example.com"
[System.IO.File]::WriteAllText("$dir\notes\log\sample.md", "write to $sampleAddress`n", $utf8)
Push-Location $dir
git add -- "notes/log/sample.md" | Out-Null
Pop-Location
$result = Invoke-Tool $scan @("-Root", $dir, "-Mode", "staged")
Check "email fails scan" ($result.Code -ne 0 -and $result.Text -match "email")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\private-mask.txt", "Placeholder`n", $utf8)
[System.IO.File]::WriteAllText("$dir\notes\log\sample.md", "the word Placeholder is here`n", $utf8)
Push-Location $dir
git add -- "notes/log/sample.md" | Out-Null
Pop-Location
$result = Invoke-Tool $scan @("-Root", $dir, "-Mode", "staged")
Check "mask list fails scan" ($result.Code -ne 0 -and $result.Text -match "mask-list" -and $result.Text -notmatch "Placeholder")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
$index = "# 索引`n`npath | heading | register | ja | kind`n"
$log = "# day`n"
1..6 | ForEach-Object {
  $index += "notes/phrases/item$_.md | Item $_ | neutral | 意味$_。 | phrase`n"
  $log += "Item $_ | phrase | test | new`n"
}
[System.IO.File]::WriteAllText("$dir\notes\index.md", $index, $utf8)
[System.IO.File]::WriteAllText("$dir\notes\log\day.md", $log, $utf8)
$result = Invoke-Tool $quiz @("-Root", $dir)
$quizText = [System.IO.File]::ReadAllText("$dir\notes\quiz.md")
$pathCount = ([regex]::Matches($quizText, "(?m)^- path: ")).Count
$doneCount = ([regex]::Matches($quizText, "(?m)^  done: no$")).Count
Check "quiz keeps a short pool" ($result.Code -eq 0 -and $pathCount -eq 6 -and $doneCount -eq 6 -and $quizText -match "ja: 意味")
Check "quiz hides the heading line" ($quizText -notmatch "(?m)^# Item")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
$index = "# 索引`n`npath | heading | register | ja | kind`n"
$log = "# day`n"
1..105 | ForEach-Object {
  $index += "notes/phrases/item$_.md | Item $_ | neutral | 意味$_。 | phrase`n"
  $log += "Item $_ | phrase | test | new`n"
}
[System.IO.File]::WriteAllText("$dir\notes\index.md", $index, $utf8)
[System.IO.File]::WriteAllText("$dir\notes\log\day.md", $log, $utf8)
$result = Invoke-Tool $quiz @("-Root", $dir)
$quizText = [System.IO.File]::ReadAllText("$dir\notes\quiz.md")
$paths = @([regex]::Matches($quizText, "(?m)^- path: (\S+)") | ForEach-Object { $_.Groups[1].Value })
$unique = @($paths | Select-Object -Unique).Count
$doneCount = ([regex]::Matches($quizText, "(?m)^  done: no$")).Count
Check "quiz caps at one hundred" ($result.Code -eq 0 -and $paths.Count -eq 100 -and $unique -eq 100 -and $doneCount -eq 100)
Check "quiz cap hides headings" ($quizText -notmatch "(?m)^# Item")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
[System.IO.File]::WriteAllText("$dir\notes\log\day.md", "Missing item | phrase | test | new`n", $utf8)
$result = Invoke-Tool $quiz @("-Root", $dir)
Check "quiz misses index" ($result.Code -ne 0 -and $result.Text -match "quiz-index-miss")
Remove-Item $dir -Recurse -Force

$dir = New-Fixture
$src = Join-Path $dir "incoming"
New-Item -ItemType Directory -Path "$src\once" | Out-Null
$phrase = "# Sample phrase`n`n## 意味`n`n見本の意味です。`n`n## 例`n`nThis is a sample.`n`n## 場面`n`ncasual`n"
[System.IO.File]::WriteAllText("$src\sample.md", $phrase, $utf8)
$result = Invoke-Tool $import @("-Root", $dir, "-SourceDir", $src, "-SourceLabel", "test")
$indexText = [System.IO.File]::ReadAllText("$dir\notes\index.md")
$phraseRows = ([regex]::Matches($indexText, "sample-phrase.md")).Count
Check "import adds one phrase" ($result.Code -eq 0 -and $phraseRows -eq 1)
$updated = "# Sample phrase`n`n## 意味`n`n更新した意味です。`n`n## 例`n`nThis is a sample.`n`n## 場面`n`ncasual`n"
[System.IO.File]::WriteAllText("$src\sample.md", $updated, $utf8)
$result2 = Invoke-Tool $import @("-Root", $dir, "-SourceDir", $src, "-SourceLabel", "test")
$indexText = [System.IO.File]::ReadAllText("$dir\notes\index.md")
$phraseRows = ([regex]::Matches($indexText, "sample-phrase.md")).Count
$logText = @(Get-ChildItem "$dir\notes\log\*.md" | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
Check "import does not duplicate" ($result2.Code -eq 0 -and $phraseRows -eq 1 -and $indexText.Contains("更新した意味です。") -and $logText.Contains("| update"))
Remove-Item $dir -Recurse -Force

$hook = [System.IO.File]::ReadAllBytes((Join-Path $repo ".git\hooks\pre-commit"))
Check "installed hook has no CR" (-not ($hook -contains 13))
$phrases = @(Get-ChildItem (Join-Path $repo "notes\phrases\*.md") -ErrorAction SilentlyContinue)
Check "seed phrases exist" ($phrases.Count -ge 28)
$indexText = [System.IO.File]::ReadAllText((Join-Path $repo "notes\index.md"))
$missing = @($phrases | Where-Object {
  $rel = "notes/phrases/$($_.Name)"
  $indexText -notmatch [regex]::Escape($rel)
})
Check "every phrase is indexed" ($missing.Count -eq 0)
$ask = [System.IO.File]::ReadAllText((Join-Path $repo "notes\ask.md"))
Check "ask templates exist" ($ask.Contains("What does ___ mean?") -and $ask.Contains("How do you ___?"))
Check "once file exists" (Test-Path (Join-Path $repo "notes\once\2026-10-03.md"))

Write-Output "passed=$pass failed=$fail"
if ($fail -gt 0) { exit 1 }
exit 0
