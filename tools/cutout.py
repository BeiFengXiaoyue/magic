"""抠底工具：把 prop / char 贴图的纯灰背景与投影去掉，写成 RGBA。

用法（ComfyUI 自带 Python 或任何带 Pillow 的 Python）：
    python tools/cutout.py --only art_prop_qinglucao --out-dir tools/_preview/cut
    python tools/cutout.py                 # 处理 assets/textures/prop/ 全部，覆盖原图
    python tools/cutout.py --category char --no-trim   # 角色表：只去背景，保留格位

背景色从四边采样；从边界做 4 邻接洪泛，把背景色与中灰投影设为透明。
黑色描边属于“很暗、低饱和”像素，不进入洪泛，避免吃掉主体轮廓。
物件默认裁到主体并居中；角色表用 --no-trim 保留原画布，切帧才对得上。
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from statistics import median

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
TEXTURE_ROOT = ROOT / "assets" / "textures"


def _sample_bg(px, width: int, height: int) -> tuple[int, int, int]:
    samples: list[tuple[int, int, int]] = []
    step = max(1, min(width, height) // 128)
    for x in range(0, width, step):
        samples.append(px[x, 0])
        samples.append(px[x, height - 1])
    for y in range(0, height, step):
        samples.append(px[0, y])
        samples.append(px[width - 1, y])
    return (
        int(median(s[0] for s in samples)),
        int(median(s[1] for s in samples)),
        int(median(s[2] for s in samples)),
    )


def _removable(r: int, g: int, b: int, bg: tuple[int, int, int]) -> bool:
    br, bgc, bb = bg
    dr, dg, db = r - br, g - bgc, b - bb
    distance = (dr * dr + dg * dg + db * db) ** 0.5
    if distance <= 52.0:
        return True
    # 中灰投影：比背景暗、低饱和、但不到黑描边的亮度
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    bg_lum = 0.299 * br + 0.587 * bgc + 0.114 * bb
    saturation = max(r, g, b) - min(r, g, b)
    return lum < bg_lum - 4.0 and lum > 24.0 and saturation < 36 and distance <= 105.0


def cutout(
    image: Image.Image,
    trim: bool = True,
) -> tuple[Image.Image, tuple[int, int, int], float]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    px = rgba.load()
    bg = _sample_bg(px, width, height)

    mask = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        index = y * width + x
        if mask[index]:
            return
        r, g, b, _ = px[x, y]
        if not _removable(r, g, b, bg):
            return
        mask[index] = 1
        queue.append((x, y))

    for x in range(width):
        push(x, 0)
        push(x, height - 1)
    for y in range(height):
        push(0, y)
        push(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            push(x - 1, y)
        if x + 1 < width:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y + 1 < height:
            push(x, y + 1)

    for y in range(height):
        row = y * width
        for x in range(width):
            if mask[row + x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)

    removed = sum(mask) / float(width * height)

    if trim:
        bbox = rgba.getbbox()
        if bbox:
            left, top, right, bottom = bbox
            content_w = right - left
            content_h = bottom - top
            pad = max(8, int(max(content_w, content_h) * 0.06))
            side = max(content_w, content_h) + pad * 2
            canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            crop = rgba.crop(bbox)
            offset_x = (side - content_w) // 2
            offset_y = (side - content_h) // 2
            canvas.paste(crop, (offset_x, offset_y), crop)
            rgba = canvas

    return rgba, bg, removed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="", help="只处理一个 art_id")
    parser.add_argument("--category", default="prop", choices=["prop", "char"], help="textures 下的子目录")
    parser.add_argument("--no-trim", action="store_true", help="保留原画布与格位（角色表用）")
    parser.add_argument("--out-dir", default="", help="输出目录；默认覆盖 textures/<category>")
    args = parser.parse_args()

    source_dir = TEXTURE_ROOT / args.category
    out_dir = Path(args.out_dir) if args.out_dir else source_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    files = sorted(source_dir.glob("*.png"))
    if args.only:
        files = [p for p in files if p.stem == args.only]
    if not files:
        print(f"没有找到要处理的 {args.category} 贴图")
        return 1

    for source in files:
        with Image.open(source) as image:
            result, bg, removed = cutout(image, trim=not args.no_trim)
        target = out_dir / source.name
        result.save(target)
        print(f"{source.name}: bg={bg} removed={removed:.1%} -> {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
