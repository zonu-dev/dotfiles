# Post-processing

生成後はそのまま使わず、Apple Icon Composer に渡せる状態まで整える。

## Recommended order

1. 背景透過と defringe
2. 透かし除去
3. 必要なら色の量子化または色差し替え
4. 必要なら回転
5. 配置先へ保存

## Background transparency with defringe

単純な色域選択だけだと、エッジにグレーのフリンジが残る。以下の defringe を使う。

```python
from PIL import Image
import math

img = Image.open("input.png").convert("RGBA")
pixels = img.load()
w, h = img.size
bg = (128, 128, 128)

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        dist = math.sqrt((r - bg[0])**2 + (g - bg[1])**2 + (b - bg[2])**2)
        if dist < 45:
            pixels[x, y] = (0, 0, 0, 0)
        elif dist < 70:
            alpha_ratio = (dist - 45) / 25.0
            new_a = int(alpha_ratio * 255)
            if alpha_ratio > 0:
                nr = min(255, max(0, int((r - bg[0] * (1 - alpha_ratio)) / alpha_ratio)))
                ng = min(255, max(0, int((g - bg[1] * (1 - alpha_ratio)) / alpha_ratio)))
                nb = min(255, max(0, int((b - bg[2] * (1 - alpha_ratio)) / alpha_ratio)))
            else:
                nr, ng, nb = 0, 0, 0
            pixels[x, y] = (nr, ng, nb, new_a)

img.save("output.png")
```

- `dist < 45`: 背景として完全透明化
- `45 <= dist < 70`: 半透明エッジを維持しつつ背景色成分を除去
- どの背景に乗せてもグレーの滲みが出にくくなる

## Watermark removal

Nano Banana は右下に透かしを入れることがある。右下隅だけを限定的に消す。

```python
for y in range(int(h * 0.88), h):
    for x in range(int(w * 0.85), w):
        r, g, b, a = pixels[x, y]
        if a > 0:
            pixels[x, y] = (0, 0, 0, 0)
```

- 範囲を広げすぎると本体を削る
- モチーフが右下に寄っている場合は、色判定を追加して本体を除外する

## Optional flat-color cleanup

`no gradients` を入れても微妙な色ムラが残る場合は、全不透明ピクセルだけターゲット色へ量子化する。

```python
import math

TARGET_COLORS = [
    (52, 211, 153),   # #34D399
    (255, 255, 255),  # #FFFFFF
    (55, 65, 81),     # #374151
]

def color_dist(c1, c2):
    return math.sqrt((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2)

def nearest_target(r, g, b):
    return min(TARGET_COLORS, key=lambda tc: color_dist((r, g, b), tc))

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a >= 200:
            nearest = nearest_target(r, g, b)
            pixels[x, y] = (nearest[0], nearest[1], nearest[2], a)
```

- `TARGET_COLORS` は使うパレットに合わせて差し替える
- 半透明エッジは維持したいので `a >= 200` のみ対象にする

## Recolor

生成後にアクセント色だけ差し替えたい場合は、色相や RGB 条件で置換する。

```python
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 0 and b > 180 and r < 120 and g > 100:
            pixels[x, y] = (253, 224, 71, a)
```

## Rotation

傾きはプロンプトではなく後処理で付ける。

```python
rotated = img.rotate(10, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
```

- `expand=True` で切れを防ぐ
- `BICUBIC` で品質を保つ
- 角度の目安は 5〜10 度

## File management

- 生成元画像: `~/Downloads/`
- 透過処理済み: `/tmp/[AppName]_icon_transparent.png`
- 傾き付き: `/tmp/[AppName]_icon_tilted.png`
- サイト表示用: `assets/[app-name]-icon.png`
- Icon Composer 用: 各アプリリポジトリの `Support/` ディレクトリ
