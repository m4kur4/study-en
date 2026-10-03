# プロンプト

別の環境へ clone したあと、Agent モードのチャットへこの文書の「手順」をそのまま渡す。学習者ごとの表現一覧は作らない。最初の commit と push は、ユーザーが非公開文字列を書き終えて指示するまで行わない。

## 手順

このフォルダは英語学習ノートである。次を実行し、終わったら結果だけを短く報告する。

1. リポジトリのルートで作業する。`git config` は変更しない。`--force` と `--no-verify` は使わない。origin が既にあれば、それを使う。無ければ remote を足さず、その旨を報告する。
2. `scripts/install-hook.ps1` を `powershell.exe -NoProfile -ExecutionPolicy Bypass -File` で実行する。`.git/hooks/pre-commit` を BOM なし UTF-8、改行 LF のみで作る。`Set-Content` と `Out-File` は使わない。実行後、そのファイルに CR が無いことを確認する。CR があればファイルを消して止める。
3. `notes/private-mask.txt` が無ければ、空のファイルを作る。中身は書かない。このファイルは `.gitignore` に入っている。仮の1行を足さない。
4. 次が揃っていることを確認する。欠けていれば、`docs/spec.md` と `docs/design.md` に従って作る。既存のファイルは、欠けの修復以外では書き換えない。
   - `.cursor/rules/english-study.mdc`
   - `.cursor/rules/english-quality.mdc`
   - `.cursor/rules/public-repo-privacy.mdc`
   - `.cursor/agents/english-expert.md`
   - `.cursor/skills/notebook-maintain/SKILL.md`
   - `.cursor/skills/english-quiz/SKILL.md`
   - `.cursor/hooks.json`
   - `.cursor/hooks/block-git.ps1`
   - `scripts/check-notebook.ps1`
   - `scripts/check-setup.ps1`
   - `scripts/scan-public.ps1`
   - `scripts/build-quiz.ps1`
   - `scripts/import-notes.ps1`
   - `scripts/git-hooks/pre-commit`
   - `scripts/install-hook.ps1`
   - `.gitattributes` に `scripts/git-hooks/pre-commit text eol=lf`
   - `.vscode/settings.json`
   - `notes/index.md`
   - `notes/optimize.md`
   - `notes/quiz.md`
   - `notes/ask.md`
   - `notes/phrases/`
   - `notes/once/`
   - `notes/log/`
   - `Readme.md`
5. `notes/optimize.md` に、`索引`、`クイズ`、`最終チャット` の三つの日付が `YYYY-MM-DD` で入っていることを確認する。読めないときだけ、索引を日本時間の前日、クイズと最終チャットを日本時間の今日にする。未来の日付は入れない。
6. `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check-notebook.ps1` を実行する。失敗したら、検査の名前とファイルを報告して止める。ノートは更新しない。
7. `scripts/scan-public.ps1` が `mask-file` で失敗することは、非公開文字列がまだ空であるときの正常な結果である。成功させようとして文字列を書かない。
8. commit しない。push しない。学習者の表現ファイルは、この手順では作らない。表現を入れるときは `docs/initial-load.md` に従い、ユーザーが渡したファイルだけを使う。

## 修復するときの契約

規則は `alwaysApply: true` で、それぞれ50行以内である。english-expert は `readonly: true` と `model: inherit` で、使う場面は詳しく、クイズ、声に出して、会話練習だけと説明文に書く。

`scripts/git-hooks/pre-commit` は sh で、リポジトリのルートへ移ってから `check-notebook.ps1` と `scan-public.ps1 -Mode staged` を、`powershell.exe -NoProfile -ExecutionPolicy Bypass -File` で順に実行する。どちらかが 0 以外なら commit を拒否する。このファイルの改行は LF だけにする。

`.cursor/hooks.json` の `beforeShellExecution` は `block-git.ps1` を同じ起動方法で呼ぶ。`failClosed` は true である。`git commit` と `git push` 以外は許可する。`--no-verify`、`--force`、push の `-f`、`core.hooksPath` は拒否する。

索引の1行は `path | heading | register | ja | kind` である。日次ログの1行は `heading | kind | source | status` である。kind は phrase か once、register は casual か neutral か formal、status は new か update である。
