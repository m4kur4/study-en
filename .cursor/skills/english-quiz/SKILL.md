---
name: english-quiz
description: Runs an English study quiz or a speak-aloud drill from notes/quiz.md. Use when the user asks for クイズ, クイズして, 声に出して, or a quiz for a named day or source.
---

# 出題

日付や出典の指定が無い「クイズして」は、`notes/quiz.md` の `done: no` から1件を無作為に選ぶ。日本語だけを見せる。出題中は、パスも英語も出さない。ユーザーが答えたあとで、そのパスの表現ファイルを開き、英語と和訳を見せる。英文の質は english-expert に確認させる。

正解したときだけ、その項目の `done` を `yes` にする。不正解は `no` のまま残す。`done: no` が無くなったら、`scripts/build-quiz.ps1` を実行して作り直す。この作り直しでは `notes/optimize.md` の日付を進めない。

日付や出典の指定があるときは、その日次ログの見出しを索引で引き、1件だけ同じ手順で出す。この出題は `notes/quiz.md` の `done` を変えない。

「声に出して」は、その日の日次ログから復唱する文を3つ選ぶ。ログが空のときは `notes/quiz.md` から3つ選び、答える前に表現ファイルを開いて英文を見せる。`done` は変えない。文を見せるとき、音のつながりで気を付ける点があれば一つか二つ短く足す。無いときは足さない。出題中は足さない。正解を見せたあとも、同じように一つか二つまで足す。

クイズと復唱は、表現ファイルへ保存しない。
