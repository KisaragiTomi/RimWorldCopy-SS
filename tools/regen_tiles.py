"""从 1024x1024 原版贴图重新生成 16x16 tile variants，使用区域平均保留纹理细节"""
import os
from PIL import Image
import random

SRC_DIR = r"D:\MyProject\RimWorldCopy\assets\textures\extracted\terrain"
DST_DIR = r"D:\MyProject\RimWorldCopy\assets\textures\tiles\terrain"
CELL = 16
VARIANTS = 4
PATCH = 64  # 从源图中采样 64x64 区域然后缩小到 16x16

TERRAINS = [
    "Soil", "SoilRich", "Sand", "Gravel", "MarshyTerrain", "Mud",
    "Ice", "RoughStone", "Concrete", "WoodFloor", "Carpet",
]

random.seed(42)

os.makedirs(DST_DIR, exist_ok=True)
generated = 0

for tname in TERRAINS:
    src_path = os.path.join(SRC_DIR, f"{tname}.png")
    if not os.path.exists(src_path):
        print(f"SKIP {tname} (no source)")
        continue
    src = Image.open(src_path).convert("RGBA")
    sw, sh = src.size
    max_x = sw - PATCH
    max_y = sh - PATCH
    if max_x < 0 or max_y < 0:
        print(f"SKIP {tname} (too small: {sw}x{sh})")
        continue

    for v in range(VARIANTS):
        ox = random.randint(0, max_x)
        oy = random.randint(0, max_y)
        crop = src.crop((ox, oy, ox + PATCH, oy + PATCH))
        tile = crop.resize((CELL, CELL), Image.LANCZOS)
        out_path = os.path.join(DST_DIR, f"{tname}_v{v}.png")
        tile.save(out_path)
        generated += 1

print(f"Generated {generated} tiles")
