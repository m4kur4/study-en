# 英語学習ノート

clone したあと、このフォルダを Cursor のワークスペースにして使う。学習者ごとの表現一覧は、この文書には書かない。

## 1. フォルダを開く

1. このリポジトリの URL で clone する。アカウント名そのものは、ファイルへ書かない。

```powershell
git clone <リポジトリの URL>
```

2. Cursor で **File > Open Folder** を選び、clone したフォルダ自体を開く。親フォルダを開くと、このフォルダの規則は有効にならない。
3. チャットは **Agent** モードにする。Ask や Plan ではノートファイルを更新できない。チャットは、このフォルダに対して一つだけ開く。
4. 音声で質問するときは、Windows の設定で Cursor にマイクを許可する。マイクは質問文の書き起こしである。答えはテキストで返り、読み上げはしない。書き起こしを見てから送信する。

開いたフォルダの `.vscode/settings.json` と `.cursor/rules` は、このワークスペースだけで使われる。

## 2. commit 前の検査を有効にする

リポジトリのルートで、次を実行する。`.git/hooks/pre-commit` が作られる。Git の設定は変えない。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-hook.ps1
```

## 3. 非公開にする文字列を書く

`notes/private-mask.txt` が無ければ、空のファイルを作る。中身はユーザーが自分で書く。1行に1つ。

- 自分の氏名
- 学校名
- 勤務先
- 非公開のアカウント名

このファイルは commit されない。空のあいだは commit できない。検査を通すための仮の1行は書かない。文字列そのものはチャットに書かない。

## 4. 初期の表現を登録する

`notes/phrases/` に表現ファイルが既にある clone では、この手順は不要である。

無いときは、自分のメモを一つのフォルダへ用意する。形は `docs/initial-load.md` に従う。非公開の文字列は、そのフォルダへ入れない。リポジトリのルートで、次を実行する。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/import-notes.ps1 -SourceDir "用意したフォルダ" -SourceLabel "初期メモ"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build-quiz.ps1
```

1件目は、チャットで表現を尋ねて作ることもできる。エージェントは、頼まれていない表現を作らない。

## 5. 不足がないか確認する

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check-notebook.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check-setup.ps1
```

`check-notebook.ps1` が失敗したら、表示された検査の名前とファイルを直してから、もう一度実行する。ノートの中身は、その前に推測で埋めない。

`check-setup.ps1` が `setup:` を出したら、続く `fix:` の手順で直す。マスクが空なときは、上の「非公開にする文字列を書く」を行う。表現が無いときは、上の「初期の表現を登録する」を行う。

## 6. 最初の commit と push

非公開の文字列を書き終えたあと、チャットで commit と push を指示する。指示があるまで、エージェントは commit も push もしない。

## 毎日の使い方

Agent モードのチャットへ、音声の書き起こしか、日本語または英語の文を送る。同じ日の質問では、ノート全体の検査はしない。文が来たときは意味を答え、残すのはその中の単語か言い回しを1つだけである。文そのものは、残すと言ったときだけ残る。日本語を英語にするにはどうすればよいか、という質問は残さない。

日付をまたいだ最初のチャットで、ノート全体の検査と設定の不足を見てから、前日までの索引を揃え、同じ表現の行を1件にまとめ、出題ファイルを最大100件で作り直す。近いだけの別表現はまとまらない。

「クイズして」と言うと、未回答から1問出る。正解した問題は、その出題ファイルを作り直すまで出ない。

最初の commit と push のあと、日付を進めたとき、または直前の commit から1時間以上たっているときは、変更があれば commit し、成功したら push する。

詳細は `docs/spec.md`、`docs/design.md`、`docs/initial-load.md` にある。別の環境でファイルが欠けたときの修復は `docs/reproduce-prompt.md` を Agent モードへ渡す。
