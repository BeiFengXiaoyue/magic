---
id: art_scene_workshop
category: scene
purpose: "炼药工坊室内背景：石地板、木架、冷壁炉；中央留空暖光池，坩埚作为独立物件叠加"
status: draft
workflow: generate img.json
ref: null
canvas: 1024x576
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients orthographic top-down view at a 45-degree angle, flat 2D rendering, no perspective distortion, no vanishing point, walkable game scene layout a single small walkable alchemy workshop interior, square stone floor, heavy dark wooden shelves along the left and back walls, a cold empty stone hearth on the left wall, a sturdy wooden worktable against the back wall, an empty central floor area with one pool of warm amber light where a clay crucible will be placed separately, a doorway opening on the right wall, deep shadow in the corners, no characters, no crucible, no bed, no loose props in the center, quiet cramped atmosphere
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources characters, people, creatures, UI overlay, HUD, crucible, bed, loose foreground props, centered clutter
```

## 备注

- 游戏内尺寸 1280×720；本图会铺满房间，代码不画地形网格与墙线。
- 中央空地与暖光池对应代码里的坩埚位置 (560, 360)；坩埚用 `art_prop_crucible_clay` 单独叠加。
- 床的位置在 (220, 560)，用 `art_prop_bed` 单独叠加。
- 两扇门在右墙：(1232, 340) 去小店、(1232, 580) 去森林；门可作为独立物件或后续补门贴图。
- 交互物件不要烤进背景，避免和独立贴图重复。
