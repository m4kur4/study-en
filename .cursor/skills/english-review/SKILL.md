---
name: english-review
description: Builds a same-format Markdown review of one day's notes. Use when the user asks to turn a specified date's notes into Markdown or HTML, 指定した日付のnoteのサマリをHTMLにして, or a review page for a named day.
---

# 日付の復習

ユーザーが日付を指定して、その日のノートのサマリを復習ファイルにするときに使う。出力は常に Markdown である。クイズの出題とは別である。日付をまたいだ最適化で前日分を作る手順は english-study にあり、その実行ではこのスキルの「日付を進めない」には従わない。

日付が無いときは、今日とは決めず、日付を聞く。

`scripts/build-review.ps1 -Date yyyy-MM-dd` を実行する。成功したら `review/YYYY-MM-DD.md` のパスだけを伝える。チャットには本文を貼らない。ブラウザでは開かない。失敗したらファイルは残さない。手で復習ファイルを書かない。ユーザーが日付を指定したときは `notes/optimize.md` の日付を進めない。
