"""
Generate a sample guide image for the RimWorld landscape generator.

RGB channels:
  R = elevation (white=mountain, black=low)
  G = fertility (white=rich soil, black=sand)
  B = water     (white=deep water, black=no water)
"""
from PIL import Image, ImageDraw
import os

w, h = 275, 275
img = Image.new("RGB", (w, h), (0, 0, 0))
draw = ImageDraw.Draw(img)

# R channel: draw mountains in top-right and bottom-left corners
r_layer = Image.new("L", (w, h), 30)
r_draw = ImageDraw.Draw(r_layer)
r_draw.ellipse([160, 20, 260, 120], fill=220)    # top-right mountain cluster
r_draw.ellipse([20, 180, 100, 260], fill=200)     # bottom-left mountain
r_draw.ellipse([100, 100, 170, 170], fill=180)    # center-ish hill

# G channel: fertile band through the middle
g_layer = Image.new("L", (w, h), 80)
g_draw = ImageDraw.Draw(g_layer)
g_draw.rectangle([30, 100, 245, 200], fill=200)   # fertile strip across middle
g_draw.ellipse([80, 60, 200, 140], fill=220)      # extra fertile patch

# B channel: river from top-center to bottom-left
b_layer = Image.new("L", (w, h), 0)
b_draw = ImageDraw.Draw(b_layer)
b_draw.line([(140, 0), (130, 50), (100, 100), (60, 160), (30, 220), (10, 275)],
            fill=220, width=8)
b_draw.ellipse([50, 50, 90, 90], fill=200)        # small lake

img = Image.merge("RGB", [r_layer, g_layer, b_layer])

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "guide_sample.png")
img.save(out_path)

# Also save a 4x scaled version for viewing
img_big = img.resize((w * 4, h * 4), Image.NEAREST)
img_big.save(out_path.replace(".png", "_preview.png"))

print(f"Saved guide image: {out_path}")
print("  R(red)   = elevation → mountains where bright")
print("  G(green) = fertility → rich soil where bright")
print("  B(blue)  = water     → river/lake where bright")
