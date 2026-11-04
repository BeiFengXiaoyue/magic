---
id: art_prop_door_wood
category: prop
purpose: "室内旧木门：嵌在墙上，供工坊两扇门与小店左墙门共用"
status: draft
workflow: 无参考生图.json
ref: null
canvas: 768x768
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients orthographic top-down view at a 45-degree angle, flat 2D object cutout, centered single object, isolated on a completely plain flat solid mid-grey background, empty background, nothing else in the frame, clean sharp cutout edges a single heavy timber door standing inside a dark plank door frame, aged vertical boards, two long iron strap hinges, a round iron ring handle, a small iron keyhole plate, weathered wood grain and chipped paint, the frame slightly wider than the door leaf, the door leaf centered in the frame
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources scene background, room interior, landscape, multiple objects, wall section, floor, doorway opening
```

## 备注

- 工坊底墙两扇门（`SceneLayout.WORKSHOP_DOOR_SHOP` / `WORKSHOP_DOOR_FOREST`）与小店左墙门（`SHOP_DOOR_WORKSHOP`）共用这一张；门的交互热区见 `scene_layout.gd`。
- 45° 俯视下单门带门框，门板与墙线平行；左墙门在引擎里旋转 90° 复用。
- 游戏内显示边长约 96px，门板占贴图中间竖向区域；抠底后保留门框，不要保留地面/墙体。
- 工坊底部门洞在背景图上约宽 170px（游戏坐标 x 544~759），门贴图先按 96px 放中间，后续可调。
