---
name: english-review
description: Builds a same-format HTML review of one day's notes. Use when the user asks to turn a specified date's notes into HTML, 指定した日付のnoteのサマリをHTMLにして, or a review page for a named day.
---

# 日付の復習

ユーザーが日付を指定して、その日のノートのサマリを HTML にするときに使う。クイズの出題とは別である。日付をまたいだ最適化で前日分を作る手順は english-study にあり、その実行ではこのスキルの「日付を進めない」には従わない。

日付が無いときは、今日とは決めず、日付を聞く。

`scripts/build-review.ps1 -Date yyyy-MM-dd` を実行する。成功したら `review/YYYY-MM-DD.html` を既定のブラウザで開く。チャットには HTML 本文を貼らない。失敗したらファイルは残さない。手で HTML を書かない。ユーザーが日付を指定したときは `notes/optimize.md` の日付を進めない。最適化で前日分を作るときは、ブラウザでは開かない。
