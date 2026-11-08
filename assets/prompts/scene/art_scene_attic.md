---
id: art_scene_attic
category: scene
purpose: "阁楼室内背景：斜屋顶、木梁、尘埃；左侧留空给旧木箱，右墙留楼梯口"
status: draft
workflow: 无参考生图.json
ref: null
canvas: 1024x576
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients directly overhead top-down view looking straight down, flat 2D floor plan filling the entire frame edge to edge, walkable game scene layout a cramped attic interior seen from directly above, bare wide wooden floorboards, heavy dark roof beams crossing the ceiling diagonally, a small skylight in the roof casting one narrow pool of dusty amber light, cobwebs and dust motes in the dark corners, scattered old crates and bundled cloth along the left and back edges, an empty patch of floor on the left side where a wooden chest will be placed separately, an open stairwell hatch on the right wall with a ladder going down, deep shadow under the roof slopes, the center kept as open floor, a full-frame interior view filling the entire canvas edge to edge, walls and floor running past the frame borders, the room extending beyond the edges of the image, quiet forgotten atmosphere
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources characters, people, creatures, UI overlay, HUD, wooden chest, ladder, loose foreground props, centered clutter
```

## 备注

- 游戏内尺寸 1280×720；本图铺满阁楼场景。
- 旧木箱独立叠加，位置 (480, 420)，代码不画背景箱子。
- 下楼梯子在右墙 (1080, 420)，用 `art_prop_ladder` 独立叠加；背景只留一个暗色开口。
- 与工坊同样的俯视规则：交互物件不要烤进背景，避免和独立贴图重复。
