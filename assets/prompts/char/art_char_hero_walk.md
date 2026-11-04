---
id: art_char_hero_walk
category: char
purpose: "主角 4 向 × 4 帧行走 sheet：炼金术士学徒，Demo 里替换白色圆点"
status: draft
workflow: 无参考生图.json
ref: null
canvas: 768x768
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients 1:2.5 head-to-body ratio, big head and thin limbs, blank expressionless face with two dot eyes and a single line mouth, full body game sprite a 4 by 4 sprite sheet of one young alchemist apprentice, four rows for down, left, right and up facing directions, four columns of a four-frame walk cycle in each row, the same character repeated in every cell at identical size and identical ground alignment, worn dark leather apron over a faded grey linen shirt, sleeves rolled to the elbows, a small leather tool pouch on a belt, dark trousers, scuffed brown boots, short messy dark hair, bare head, isolated on a completely plain flat solid mid-grey background, each cell evenly spaced, feet aligned to the bottom edge of each cell
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources detailed facial features, cartoon smile, expressive face, realistic human proportions, multiple characters, character sheet grid lines
```

## 备注

- 一张图出 4×4 共 16 帧；后处理按 768/4 = 192 等分切格，格内角色脚底对齐每格底边。
- 行序约定：第 1 行朝下（正面）、第 2 行朝左、第 3 行朝右、第 4 行朝上（背面）；每行 4 帧循环。
- 游戏内目标精灵约 128×192（美术文档 §14.1）；Demo 可先取「朝下」行循环，接入行走动画后再用整张 sheet。
- 主角碰撞仍按脚底圆形处理（`Player.RADIUS`），接入贴图后只改绘制，不改业务逻辑。
- 纯灰底，出图后抠底；不要背景场景与投影。
