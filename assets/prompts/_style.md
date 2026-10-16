# 全局风格前缀与通用负向（唯一出处）

> 契约：`docs/contracts/04-art-assets.md` §5 · 依据：`03-表现/美术风格.md`
> **本文是一切素材提示词的公共部分。改动本文 = 全库事件**（见 04 契约 §6）。

---

## 1. 风格前缀（STYLE PREFIX · 正向，所有素材共用）

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients
```

## 2. 通用负向（COMMON NEGATIVE）

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources
```

## 3. 类别修饰段（按 category 追加）

| category | 正向追加 |
|---|---|
| `scene` | `orthographic top-down view at a 45-degree angle, flat 2D rendering, no perspective distortion, no vanishing point, walkable game scene layout` |
| `prop` | `orthographic top-down view at a 45-degree angle, flat 2D object cutout, centered single object, no background scenery` |
| `char` | `1:2.5 head-to-body ratio, big head and thin limbs, blank expressionless face with two dot eyes and a single line mouth, full body game sprite` |
| `ui` | `flat 2D game UI element, aged torn parchment, hand-drawn ink line borders, no perspective` |
| `mob` | `orthographic top-down view at a 45-degree angle, full body creature game sprite` |
| `fx` | `hand-drawn effect animation, loopable, flat 2D` |

**类别负向（按 category 追加）**

| category | 负向追加 |
|---|---|
| `char` | `detailed facial features, cartoon smile, expressive face, realistic human proportions, multiple characters, character sheet grid lines` |
| `mob` | `cute, chibi, fluffy, friendly` |
| `ui` | `3D bezel, skeuomorphic frame, neon glow` |
| `prop` | `scene background, room interior, landscape` |

> **幻影怪专用追加**（将来用）：正向 `no ground shadow, outline not closed, translucent body`；负向 `ground shadow, solid opaque body`。

## 4. 拼装规则

```
正向 = STYLE PREFIX + " " + 类别正向追加 + " " + 本素材内容描述
负向 = COMMON NEGATIVE + " " + 类别负向追加
```

**素材文件里的「正向 / 负向」必须写拼好的完整字符串**（复制即用）。
