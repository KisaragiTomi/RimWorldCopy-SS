"""
Extract terrain textures from RimWorld's Unity asset bundles.
Saves them to RimWorldLandscape/Texture/
"""
import UnityPy
import os
import sys

RIMWORLD_DIR = r"d:\SteamLibrary\steamapps\common\RimWorld"
ASSETS_DIR = os.path.join(RIMWORLD_DIR, "RimWorldWin64_Data")
OUTPUT_DIR = os.path.join(RIMWORLD_DIR, "RimWorldLandscape", "Texture")

TERRAIN_KEYWORDS = [
    "terrain", "soil", "sand", "gravel", "water", "marsh",
    "snow", "ice", "rock", "stone", "mud", "mossy", "rich",
    "concrete", "floor", "carpet", "tile", "bridge",
]

os.makedirs(OUTPUT_DIR, exist_ok=True)

def extract_terrain_textures():
    asset_files = [
        os.path.join(ASSETS_DIR, f) for f in os.listdir(ASSETS_DIR)
        if f.endswith(".assets")
    ]
    
    print(f"Scanning {len(asset_files)} asset files...")
    
    extracted = 0
    seen_names = set()
    
    for asset_path in asset_files:
        filename = os.path.basename(asset_path)
        print(f"\n--- {filename} ---")
        
        try:
            env = UnityPy.load(asset_path)
        except Exception as e:
            print(f"  Failed to load: {e}")
            continue
        
        for obj in env.objects:
            if obj.type.name == "Texture2D":
                try:
                    data = obj.read()
                    name = data.m_Name.lower()
                    
                    is_terrain = any(kw in name for kw in TERRAIN_KEYWORDS)
                    
                    if is_terrain and name not in seen_names:
                        seen_names.add(name)
                        img = data.image
                        if img.width > 0 and img.height > 0:
                            safe_name = data.m_Name.replace("/", "_").replace("\\", "_")
                            out_path = os.path.join(OUTPUT_DIR, f"{safe_name}.png")
                            img.save(out_path)
                            extracted += 1
                            print(f"  [OK] {safe_name} ({img.width}x{img.height})")
                except Exception as e:
                    pass
    
    print(f"\n===== Extracted {extracted} terrain textures to {OUTPUT_DIR} =====")

if __name__ == "__main__":
    extract_terrain_textures()
