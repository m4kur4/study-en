# データの初回投入手順

表現の取り込みは `scripts/import-notes.ps1` が行う。このワークスペースに最初から入っている学習データの一覧は、ここには書かない。ユーザーが用意したファイルだけを取り込む。

## 用意するファイル

再利用できる表現は、1見出し1ファイルの Markdown にして、一つのフォルダへ置く。ファイル名は何でもよい。中身は次の形にする。

```markdown
# 英語の見出し

## 意味

意味と用法を、日本語で2〜3文。

## 例

短い英語の例文。

## 場面

casual
```

`## 意味` と `## 例` は必須である。`## 場面` を書くときは、最初の語を casual、neutral、formal のどれかにする。省略したときは neutral になる。

一度きりの文は、そのフォルダの `once` サブフォルダへ、1文1ファイルで置く。最初の `# 見出し` を見出しにする。見出しが無ければ、ファイル名を見出しにする。

非公開にしたい文字列は、このフォルダへ入れない。`notes/private-mask.txt` へ、取り込みの前に書いておく。

## 実行

リポジトリのルートで、次を実行する。`SourceDir` は用意したフォルダである。`SourceLabel` は日次ログの出典で、省略すると「投入」になる。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/import-notes.ps1 -SourceDir "用意したフォルダ" -SourceLabel "投入"
```

スクリプトは次を行う。

1. 見出しが索引にあれば、新しいファイルは作らず、同じパスの中身を更新し、日次ログへ update と書く。
2. 無ければ、見出しから `notes/phrases/` のファイル名を作り、索引へ1行足し、日次ログへ new と書く。
3. `once` があれば、日本時間の今日の `notes/once/YYYY-MM-DD.md` へ足し、索引の種別を once にする。
4. commit も push もしない。出題ファイルも、このスクリプトでは作り直さない。

日付をまたいだ次のチャットが、先に `scripts/check-notebook.ps1` と `scripts/check-setup.ps1` を実行し、通過したら索引合わせ、同じ表現の索引行のまとめ、`scripts/build-quiz.ps1` を行う。日本時間の前日の日次ログがあれば、続けて `scripts/build-review.ps1 -Date 前日` を実行する。ログが無いときは、その Markdown は作らない。近いだけの別表現はまとめない。過去の文は読み直さない。同じ日の質問では、この検査は繰り返さない。今日の出題へすぐ反映するときは、取り込みのあとで次を実行する。復習 Markdown は、この出題だけの作り直しでは作らない。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build-quiz.ps1
```

失敗したときは `notes/optimize.md` の日付を進めない。

## 確認

取り込みのあと、`scripts/check-notebook.ps1` を実行する。失敗したら、表示された検査の名前とファイルを直し、もう一度実行する。`scan-public.ps1` は、`notes/private-mask.txt` にコメント以外の行が1行以上あるときだけ成功する。空のまま通すために仮の行は足さない。

このスクリプトは commit しない。最初の commit と push は、ユーザーが非公開文字列を書き終えて指示したときだけ行う。それ以降は、日付を進めたとき、または直前の commit から1時間以上たっているとき、変更があれば commit し、成功したら push する。
