---
name: notebook-maintain
description: Restores a damaged English study notebook and writes commit messages. Use when check-notebook fails, the user asks to restore or 復元 or 破損, or a commit message for notes/optimize.md is being written.
---

# ノートの保守

`scripts/check-notebook.ps1` が失敗したときは、ノートをそれ以上変更せず、commit しない。検査名が hook-missing、hook-cr、optimize-missing、index-missing のときは、過去の commit へ戻さない。`scripts/check-setup.ps1` の `fix:`、または `Readme.md` の該当手順を提案する。それ以外の失敗は、壊れた検査の名前、対象ファイル、戻し先の commit の日時とハッシュを伝える。

戻し先は、作業ツリーだけが失敗しているときは直前の commit である。その commit 自身が同じ検査に失敗するときだけ、最大20件さかのぼり、通過する最も新しい commit を選ぶ。通過するものが無ければ、復元は提案しない。

`git fsck` が失敗しているときは、過去の commit へ戻さない。失敗内容だけを通知する。

復元は、ユーザーが同じチャットで認めたあとだけ行う。戻すのは、検査に失敗したファイルだけである。まだ commit されていない健全なファイルは残す。失敗がファイルに分けられないときだけ、捨てるファイル名を示して、全体を戻すかをもう一度確認する。全体を戻したあとも `--force` は使わない。通常の push が拒否されたら、そのことだけを伝える。

commit メッセージは、索引を揃えたときは、どの日本時間の日付まで揃えたかを書く。1時間ルールだけのときは、その時点のノートの記録であることを書く。
