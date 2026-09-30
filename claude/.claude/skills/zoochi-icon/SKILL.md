---
name: zoochi-icon
description: ZOOCHI系アプリのアイコン生成ガイドライン。アプリアイコンの作成、画像生成AIへのプロンプト設計、背景透過などの後処理、Apple Icon Composerへの組み込みを行う際に使用する。
---

# ZOOCHI Icon

ZOOCHI 系アプリのアイコン生成作業で使う。

## Read as needed

- プロンプト設計、禁止スタイル、テンプレートを確認するときは [prompting.md](references/prompting.md) を読む
- 背景透過、透かし除去、色調整、回転、保存先を確認するときは [post-processing.md](references/post-processing.md) を読む
- アプリ別の色メモや失敗しやすい構図を確認するときは [app-presets.md](references/app-presets.md) を読む

必要なファイルだけ読むこと。全部を一度に読み込まない。

## Working rules

- Apple Icon Composer 前提で foreground symbol layer だけを作る。完成済みアイコン枠や squircle は生成しない
- 色数は 3〜4 色以内に絞り、Hex を明記し、グレースケール変換後も判読できる明度差を確保する
- 傾きや色差し替えは、プロンプトで無理に誘導するより後処理を優先する
- 透過後は gray fringe と watermark を残さない
