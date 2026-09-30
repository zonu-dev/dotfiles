# cmux - AI Agent Terminal

Ghosttyベースのネイティブ macOS ターミナル。複数AIエージェントの同時実行に特化。

## cmux上で起動されているかの判定

環境変数 `CMUX_BUNDLE_ID` が存在すれば cmux 上で動作している。

## 自動設定される環境変数

`CMUX_BUNDLE_ID`, `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`, `CMUX_TAB_ID`, `CMUX_PANEL_ID`, `CMUX_SOCKET_PATH`, `CMUX_PORT`, `CMUX_CLAUDE_PID`

`--workspace` や `--surface` を省略するとこれらがデフォルト値として使われる。

## ⚠️ WKWebView + CSP制限（重要）

ブラウザはWKWebView実装。多くのコマンドは内部でJS注入するため、**CSP厳格サイト（GitHub等）では失敗する**。

**CSP厳格サイトでも動作**: `snapshot`, `screenshot`, `click`, `dblclick`, `hover`, `focus`, `scroll-into-view`, `navigate`, `back`, `forward`, `reload`, `wait`, `url`, `get title/text/html/attr/value/styles`, `highlight`, `cookies get`, `tab list`, `errors list`, `console list`

**CSP厳格サイトで失敗**: `scroll --dy`, `eval`, `get count`, `is visible/enabled/checked`, `find text/role`, `storage local/session`, `addscript`, `addstyle`

**WKWebView未サポート**: `input mouse/keyboard/touch`

**回避策**: スクロール→`scroll-into-view <ref>`, 要素数→`snapshot`解析, 要素検索→`snapshot`+テキスト検索

## ブラウザのスクリーンショット

```bash
# ブラウザを開く
cmux browser open "https://example.com"
# => OK surface=surface:XX pane=pane:YY ...

# 読み込み完了を待ってからスクリーンショットを取得
cmux browser surface:XX wait --load-state complete --timeout 5
cmux browser surface:XX screenshot --out /tmp/screenshot.png
```

- `--out <path>` でファイルパスを指定する（必須）
- `--json` を付けるとJSON形式で出力
- CSP厳格サイトでも動作する

## コマンドリファレンス

詳細は `~/.claude/cmux-reference.md` を参照。`cmux --help` / `cmux browser --help` でも確認可能。
