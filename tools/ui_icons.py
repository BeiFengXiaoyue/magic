"""UI 图标后处理：裁掉画面四角的装饰，再抠底。

生成图的四角常带边框装饰；图标主体在中心，裁中心 56% 区域即可去掉角饰。
面板框不走这里（整张保留，交给 NinePatchRect）。
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
from cutout import cutout  # noqa: E402

ROOT = TOOLS.parent
TEXTURE_DIR = ROOT / "assets" / "textures" / "ui"
KEEP_RATIO = 0.56


def main() -> int:
    files = sorted(TEXTURE_DIR.glob("art_ui_icon_*.png"))
    if not files:
        print("没有找到 UI 图标")
        return 1
    for path in files:
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            width, height = rgba.size
            side = int(min(width, height) * KEEP_RATIO)
            left = (width - side) // 2
            top = (height - side) // 2
            center = rgba.crop((left, top, left + side, top + side))
            result, bg, removed = cutout(center, trim=True)
        result.save(path)
        print(f"{path.name}: crop={side} bg={bg} removed={removed:.1%}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
