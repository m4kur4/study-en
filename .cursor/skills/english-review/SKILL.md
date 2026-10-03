---
name: english-review
description: Builds a same-format HTML review of one day's notes. Use when the user asks to turn a specified date's notes into HTML, 指定した日付のnoteのサマリをHTMLにして, or a review page for a named day.
---

# 日付の復習

ユーザーが日付を指定して、その日のノートのサマリを HTML にするときだけ使う。クイズの出題とは別である。

日付が無いときは、今日とは決めず、日付を聞く。

`scripts/build-review.ps1 -Date yyyy-MM-dd` を実行する。成功したら `review/YYYY-MM-DD.html` を既定のブラウザで開く。チャットには HTML 本文を貼らない。失敗したらファイルは残さない。手で HTML を書かない。`notes/optimize.md` の日付は進めない。
