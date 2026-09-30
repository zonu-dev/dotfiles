# Prompting

ZOOCHI 系アプリのアイコンを画像生成 AI で作るときのプロンプト設計ルール。
基本は Nano Banana 前提だが、同種の one-prompt 画像生成モデルにもそのまま使える。

## Preconditions

- 画像生成はワンプロンプト前提。ネガティブプロンプトに依存しない
- Apple Icon Composer でレイヤー合成するため、生成するのは foreground symbol layer のみ
- iOS / macOS の Light / Dark / Tinted で潰れないことを優先する

## Required boilerplate

必ず以下を含める。

```text
designed as a foreground symbol layer for Apple Icon Composer.
No app icon frame, no squircle shape.
Only the symbol elements centered on a plain solid gray (#808080) background with generous padding.
1024x1024 pixels.
```

- 背景は `#808080` 固定。透過処理時に明暗どちらの要素も抜きやすい
- 完成済みアイコン枠や squircle を生成させない
- 背景レイヤーは Composer 側で組む

## Style rules

必ず以下を含める。

```text
Flat clean vector style suitable for SVG tracing, toy-like and friendly.
Not photorealistic, not skeuomorphic, no paper textures, no glossy reflections,
no gradients, no metallic effects, no actual readable text,
no watermarks, no sparkle decorations.
Use only thick rounded shapes and solid filled areas,
no outlines, no strokes, no border lines on any element.
```

モデルがまだグラデーションや質感を混ぜる場合は、以下を追加して抑制を強める。

```text
Strictly no gradients anywhere — every single shape must be one flat solid color,
no color transitions, no shading, no highlights, no shadows.
```

葉や花びらなど有機的モチーフで内部線が出る場合は、以下を追加する。

```text
The leaves are completely plain solid filled shapes with no internal details,
no leaf veins, no midrib lines, no dark lines inside the leaves,
just simple solid colored blob shapes.
```

### Avoid

| 指定 | 問題 |
|---|---|
| `metallic` / `shiny` | フラットな ZOOCHI トーンとずれる |
| `outline` / `stroke` / `border` | 枠線アーティファクトが出やすい |
| `thin lines` | Tinted / Liquid Glass で潰れやすい |
| `gradient within cards` | グレースケール時に視認性が落ちる |
| `realistic` / `skeuomorphic` | サイトの toy-like な方向性と合わない |

## Color and contrast

- シンボル内の色は 3〜4 色以内に制限する
- 色は Hex コード付きで明示する
- 白 / ダークチャコール / アクセント色の 3 段階を基本にする
- 背景色と近い色をアクセントに使わない

以下の一文を入れる。

```text
Keep the color count minimal: white, dark charcoal, and [accent color] only.
```

Tinted モード対策として以下も入れる。

```text
Ensure strong brightness contrast between all elements
so the design remains readable when converted to grayscale.
```

## Composition

- 正方形キャンバスに収まる構図にする
- 横長すぎ / 縦長すぎを避ける
- 余白が多すぎる場合は `filling most of the canvas` や `fills at least 80 percent of the canvas area` を追加する
- 傾きはプロンプトではなく後処理で付ける。`tilted` を入れると全体バランスが崩れやすい

## Prompt template

プロンプトは英語で組む。

```text
[シンボルの具体的な描写], designed as a foreground symbol layer for Apple Icon Composer on a [背景色] background. [要素ごとの詳細な描写、色は Hex コード付き]. Use only thick rounded shapes and solid filled areas, no outlines, no strokes, no border lines on any element. Keep the color count minimal: [使用色の列挙] only. Ensure strong brightness contrast between all elements so the design remains readable when converted to grayscale. Flat clean vector style suitable for SVG tracing, toy-like and friendly. Not photorealistic, not skeuomorphic, no paper textures, no glossy reflections, no gradients, no metallic effects, no actual readable text, no watermarks, no sparkle decorations. No app icon frame, no squircle shape. Only the symbol elements centered on a plain solid gray (#808080) background with generous padding. 1024x1024 pixels.
```
