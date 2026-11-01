---
id: art_prop_crucible_clay
category: prop
purpose: "陶土坩埚：圆厚陶锅，内部余烬暖光，透明背景"
status: draft
workflow: generate img.json
ref: null
canvas: 1024x1024
seed: null
tier: demo
---

## 正向

```
hand-drawn 2D game asset, Don't Starve ink illustration style, Rusty Lake moody atmosphere, thick dark ink outlines in #1A1714 (never pure black), rough hand-drawn linework, visible dry-brush stroke edges, subtle canvas paper texture overlay, heavily desaturated cold muted palette (aged wood #5C4B3A, grey stone #6E6A63, moss green #4A5240, faded blue #3E4A55, bone white #C9BFA8), dark chiaroscuro composition with 60-70% of the frame in shadow, a single warm amber light source (#D98C3F) as the only highlight, scratch-out watercolor highlights instead of white, hand-painted look, no gradients orthographic top-down view at a 45-degree angle, flat 2D object cutout, centered single object, no background scenery a single round clay crucible with a thick soot-blackened terracotta rim, wide open mouth, dark interior with a faint warm amber ember glow, rough hand-built clay body, small cracks and soot stains, isolated game prop, no ground shadow
```

## 负向

```
pixel art, 8-bit, retro game sprite, 3D render, CGI, octane render, photorealism, realistic photo, perspective, vanishing point, isometric 3D, near-big-far-small, depth of field, tilt-shift, bright daylight, high-key lighting, evenly lit, saturated candy colors, neon colors, bright pastel, pure black #000000, pure white #FFFFFF, soft bloom, glow blur, blurry, smooth airbrush, plastic look, glossy, modern UI, rounded corners, drop shadow, gradient, flat design, text, letters, watermark, signature, logo, cluttered composition, multiple light sources scene background, room interior, landscape, multiple objects, hands, fire, flames, tripod, cauldron stand, room background
```

## 备注

- 用于坩埚交互点，游戏内位置 (560, 360)；透明背景，主体居中。
- 游戏内建议后处理到 256~384px；当前代码按图片中心放置。
- 内部只有余烬暖光，不画明火；气泡/蒸气由 `art_fx_bubbles` 以后单独做。
- 后处理时保留锅口内部一圈暖光，方便在工坊背景上成为焦点。
