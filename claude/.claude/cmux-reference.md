# cmux コマンドリファレンス

## ワークスペース構造の確認

```bash
cmux tree                    # 全ワークスペースのペイン・サーフェス構造をツリー表示
cmux tree --workspace <ref>  # 特定ワークスペースのみ表示
cmux identify                # 現在のワークスペース/サーフェスを特定
```

## ブラウザ操作

### 基本操作

```bash
cmux browser open [url]                          # ブラウザペインを開く
cmux browser navigate <url> --surface <ref>      # URL移動
cmux browser url --surface <ref>                 # 現在のURL取得
cmux browser back|forward|reload --surface <ref> # ナビゲーション
cmux browser wait --load-state complete --surface <ref>  # 読み込み完了待ち
```

### ページ内容の読み取り

```bash
cmux browser snapshot --compact --surface <ref>  # アクセシビリティツリー取得（推奨）
cmux browser screenshot --out <path> --surface <ref>  # スクリーンショット保存
```

snapshotの出力には各要素に `[ref=eNN]` が付与され、click等の操作対象として使える。

### インタラクション

```bash
cmux browser click <ref> --surface <ref>              # 要素をクリック
cmux browser dblclick <ref> --surface <ref>           # ダブルクリック
cmux browser hover <ref> --surface <ref>              # ホバー
cmux browser focus <ref> --surface <ref>              # フォーカス
cmux browser scroll-into-view <ref> --surface <ref>   # 要素までスクロール
cmux browser type <selector> <text> --surface <ref>   # テキスト入力
cmux browser fill <selector> <text> --surface <ref>   # フォーム入力（空文字でクリア）
cmux browser press <key> --surface <ref>              # キー送信
cmux browser select <selector> <value> --surface <ref> # セレクト要素の選択
cmux browser check|uncheck <selector> --surface <ref> # チェックボックス操作
```

`--snapshot-after` を付けると操作後のスナップショットも同時に取得できる。

### 要素情報の取得

```bash
cmux browser get title --surface <ref>                       # ページタイトル
cmux browser get text --selector "h1" --surface <ref>        # 要素のテキスト
cmux browser get html --selector "div" --surface <ref>       # 要素のHTML
cmux browser get attr "a" --attr "href" --surface <ref>      # 属性値
cmux browser get value "input" --surface <ref>               # input/selectの値
cmux browser get count --selector "a" --surface <ref>        # 要素数（JS依存）
cmux browser get box "h1" --surface <ref>                    # バウンディングボックス
cmux browser get styles --selector "body" --property "color" --surface <ref>  # 計算済みスタイル
cmux browser is visible "h1" --surface <ref>                 # 可視性判定（JS依存）
cmux browser highlight "h1" --surface <ref>                  # 要素をハイライト表示
cmux browser find text "keyword" --surface <ref>             # テキスト検索（JS依存）
cmux browser find role "heading" --surface <ref>             # ロール検索（JS依存）
```

### JS実行

```bash
cmux browser eval "document.title" --surface <ref>    # JavaScript実行
cmux browser addscript "console.log('hi')" --surface <ref>  # JSスクリプト注入
cmux browser addstyle "body { color: red; }" --surface <ref> # CSS注入
```

### フレーム・ダイアログ・ダウンロード

```bash
cmux browser frame "iframe-selector" --surface <ref>  # iframe内に切り替え
cmux browser frame main --surface <ref>               # 最上位ドキュメントに戻す
cmux browser dialog accept --surface <ref>            # ダイアログをOK
cmux browser dialog dismiss --surface <ref>           # ダイアログをキャンセル
cmux browser download wait --path /tmp --surface <ref> # ダウンロード待ち（デフォルト30秒）
```

### セッション保存・復元

```bash
cmux browser state save /tmp/session.json --surface <ref>  # ブラウザ状態をJSON保存
cmux browser state load /tmp/session.json --surface <ref>  # 状態を復元
```

### Cookie・ストレージ

```bash
cmux browser cookies get --surface <ref>              # Cookie一覧
cmux browser cookies set --name "k" --value "v" --surface <ref>
cmux browser cookies clear --surface <ref>
cmux browser storage local get --surface <ref>        # localStorage取得（JS依存）
cmux browser storage session get --surface <ref>      # sessionStorage取得（JS依存）
```

### タブ管理

```bash
cmux browser tab list --surface <ref>                 # タブ一覧
cmux browser tab new --surface <ref>                  # 新規タブ
cmux browser tab switch <index> --surface <ref>       # タブ切り替え
cmux browser tab close --surface <ref>                # タブを閉じる
```

### エラー・コンソールログ

```bash
cmux browser errors list --surface <ref>    # JSエラー一覧
cmux browser console list --surface <ref>   # コンソールログ一覧
```

### その他

```bash
cmux browser viewport 1280 720 --surface <ref>       # ビューポートサイズ変更
cmux browser focus-webview --surface <ref>            # WebViewにフォーカス
cmux browser is-webview-focused --surface <ref>       # WebViewがフォーカスされているか
```

## ターミナル操作

```bash
cmux read-screen --surface <ref>            # ターミナル画面のテキスト読み取り
cmux send --surface <ref> "command"         # ターミナルにコマンド送信
cmux send-key --surface <ref> "Enter"       # キー送信
```

## ワークスペース管理

```bash
cmux new-workspace [--cwd <path>]           # 新規ワークスペース作成
cmux close-workspace --workspace <ref>      # ワークスペースを閉じる
cmux select-workspace --workspace <ref>     # ワークスペース切り替え
cmux rename-workspace <title>               # リネーム
```

## 通知・ステータス

```bash
cmux notify --title "完了" --body "ビルド成功"  # 通知送信
cmux set-status <key> <value>                   # サイドバーにステータス表示
cmux set-progress 0.5 --label "Building..."     # プログレスバー表示
```
