---
id: art_scene_shop
category: scene
purpose: "小店室内背景：木地板、货架、公告板；柜台位置留空，供柜台独立叠加"
status: draft
workflow: generate img.json
ref: null
canvas: 1024x576
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients orthographic top-down view at a 45-degree angle, flat 2D rendering, no perspective distortion, no vanishing point, walkable game scene layout a single small walkable village shop interior, worn dark wooden floor, shelves with clay jars and folded cloth along the back wall, a blank wooden notice board on the right wall, a shuttered window on the left wall letting in cold grey light, one warm oil lamp above an empty counter area in the center-right, a doorway opening on the left wall, deep shadow in the corners, no characters, no counter, no merchandise on the floor, empty floor space ready for a separate wooden counter
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources characters, people, creatures, UI overlay, HUD, counter, merchandise piles on the floor, centered clutter
```

## 备注

- 游戏内尺寸 1280×720；本图会铺满小店房间，代码不画地形网格与墙线。
- 柜台位置在 (720, 360)，用 `art_prop_counter` 单独叠加；背景留空。
- 门在左墙 (48, 560)，通往工坊。
- 公告板/货架可以画进背景；柜台不要画进背景，避免重复。
