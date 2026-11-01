---
id: art_scene_forest
category: scene
purpose: "晨暮森林地图底图：土路、苔藓空地、树丛与雾；道路属于地图，不画采集物/角色"
status: draft
workflow: generate img.json
ref: null
canvas: 1024x576
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients orthographic top-down view at a 45-degree angle, flat 2D rendering, no perspective distortion, no vanishing point, walkable game scene layout a single wide walkable twilight forest ground map, a winding dirt path entering from the left edge and branching into two faint trails, mossy clearings among gnarled tree roots, dense dark trees framing the outer edges, low drifting fog, scattered ferns and dry leaves, cold grey-blue ambient light with one faint warm lantern glow near the left entrance, empty clearings where collectible herbs will be placed separately, no characters, no collectible plants, no creatures, no UI, quiet overgrown atmosphere
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources characters, people, creatures, UI overlay, HUD, collectible herbs, resource nodes, room interior, close-up
```

## 备注

- 游戏内森林尺寸 3200×2400；本图会作为地图底图铺满，代码不画道路、不画常规网格。
- 道路、地形、雾必须画进底图；资源点用独立 prop 叠加，不要烤进地图。
- 空地对应 `forest.json` 的 `spawn_zones`：湿地、水边、山脊等区域；后续按这张图调整区域坐标。
- 左侧入口对应 (64, 1200)，玩家出生点 (420, 1200)；树丛/岩石位置后续由 `forest.json` 的 scenery 控制。
- 1024×576 是契约画布；如用于 3200×2400 大地图，建议放大生成或分块，避免拉伸模糊。
