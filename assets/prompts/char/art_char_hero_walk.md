---
id: art_char_hero_walk
category: char
purpose: "主角：炼金术士学徒，逐帧生成（4 向 × 4 帧）后拼成 sheet"
status: generated
workflow: 无参考生图.json
ref: null
canvas: 768x768
seed: 20261104
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients 1:2.5 head-to-body ratio, big head and thin limbs, blank expressionless face with two dot eyes and a single line mouth, full body game sprite a single young alchemist apprentice standing alone, full body from head to boots, worn dark leather apron over a faded grey linen shirt, sleeves rolled to the elbows, a small leather tool pouch on a belt, dark trousers, scuffed brown boots, short messy dark hair, bare head, isolated on a completely plain flat solid mid-grey background, empty background, nothing else in the frame, clean sharp cutout edges
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources detailed facial features, cartoon smile, expressive face, realistic human proportions, multiple characters, character sheet grid lines
```

## 帧

每行是 `帧名 | 追加到正向末尾的姿态描述`；所有帧**共用同一个 seed**（`run --seed`），否则每个都会变成不同的人。

```
left_1 | facing left in side profile, standing idle, arms relaxed at the sides
left_2 | facing left in side profile, a wide walking stride, legs clearly apart, left boot lifted off the ground
left_3 | facing left in side profile, walking, legs passing close together, body upright
left_4 | facing left in side profile, a wide walking stride, legs clearly apart, right boot lifted off the ground
right_1 | facing right in side profile, standing idle, arms relaxed at the sides
right_2 | facing right in side profile, a wide walking stride, legs clearly apart, right boot lifted off the ground
right_3 | facing right in side profile, walking, legs passing close together, body upright
right_4 | facing right in side profile, a wide walking stride, legs clearly apart, left boot lifted off the ground
```

## 备注

- **只做左右两向**（8 帧）。上下移动不单独出图，复用左右贴图：
  - 有水平分量 → 取水平分量的方向（`dx < 0` 用 left 行，`dx > 0` 用 right 行）；
  - 纯垂直移动（`dx == 0`、`dy != 0`）→ **沿用上一帧朝向**，不要切回正面。
- 一次 `run` 出 8 张原图：`raw/char/art_char_hero_walk__<帧名>__s<seed>.png`。
- 拼图：`artgen.py sheet art_char_hero_walk --cols 4`，2 列 4 行 → 768×384（每格 192）。
- 行序：第 1 行朝左、第 2 行朝右。
- 游戏内目标精灵约 128×192（美术文档 §14.1）；Demo 用 `AnimatedSprite2D` + SpriteFrames，8 帧循环。
- 主角碰撞仍按脚底圆形处理（`Player.RADIUS`），接入贴图只改绘制，不改业务逻辑。
- 为什么没有背面：t2i 对“角色正面”有强先验（换 3 种提示词、加兜帽都仍是正脸），i2i 只能锁构图不能锁身份（换参考图＝换角色）。详见工作会话记录，结论记录在 04 契约 §1。
