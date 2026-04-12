"""
Extract UI textures from RimWorld's Unity asset bundles.
Saves to the Godot project's assets/textures/ui/ directory.
"""
import UnityPy
import os
import sys

RIMWORLD_DIR = r"D:\SteamLibrary\steamapps\common\RimWorld"
ASSETS_DIR = os.path.join(RIMWORLD_DIR, "RimWorldWin64_Data")
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "RimWorldUI", "assets", "textures", "ui")

UI_KEYWORDS = [
    "ui/", "ui\\", "icon", "button", "tab", "widget",
    "gizmo", "command", "designat", "colonistbar",
    "mood", "need", "skill", "health", "research",
    "menu", "close", "arrow", "speed", "pause",
]

DLC_BUNDLE_DIRS = [
    os.path.join(RIMWORLD_DIR, "Data", "Biotech", "AssetBundles"),
    os.path.join(RIMWORLD_DIR, "Data", "Royalty", "AssetBundles"),
    os.path.join(RIMWORLD_DIR, "Data", "Ideology", "AssetBundles"),
    os.path.join(RIMWORLD_DIR, "Data", "Anomaly", "AssetBundles"),
]


def is_ui_texture(name: str, container_path: str = "") -> bool:
    combined = (name + " " + container_path).lower()
    return any(kw in combined for kw in UI_KEYWORDS)


def extract_from_assets(asset_path: str, output_dir: str, seen: set) -> int:
    count = 0
    try:
        env = UnityPy.load(asset_path)
    except Exception as e:
        print(f"  Failed to load {asset_path}: {e}")
        return 0

    for obj in env.objects:
        if obj.type.name == "Texture2D":
            try:
                data = obj.read()
                name = data.m_Name
                container = getattr(obj, "container", "") or ""

                if is_ui_texture(name, container) and name.lower() not in seen:
                    seen.add(name.lower())
                    img = data.image
                    if img.width > 0 and img.height > 0:
                        safe_name = name.replace("/", "_").replace("\\", "_")
                        out_path = os.path.join(output_dir, f"{safe_name}.png")
                        img.save(out_path)
                        count += 1
                        print(f"  [OK] {safe_name} ({img.width}x{img.height})")
            except Exception:
                pass
    return count


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    seen_names = set()
    total = 0

    print("=== Extracting UI textures from main assets ===")
    asset_files = []
    if os.path.isdir(ASSETS_DIR):
        asset_files = [
            os.path.join(ASSETS_DIR, f) for f in os.listdir(ASSETS_DIR)
            if f.endswith(".assets")
        ]

    print(f"Scanning {len(asset_files)} main asset files...")
    for af in asset_files:
        fname = os.path.basename(af)
        print(f"\n--- {fname} ---")
        total += extract_from_assets(af, OUTPUT_DIR, seen_names)

    print("\n=== Extracting UI textures from DLC bundles ===")
    for dlc_dir in DLC_BUNDLE_DIRS:
        if not os.path.isdir(dlc_dir):
            continue
        dlc_name = os.path.basename(os.path.dirname(dlc_dir))
        dlc_out = os.path.join(OUTPUT_DIR, dlc_name.lower())
        os.makedirs(dlc_out, exist_ok=True)

        bundle_files = [
            os.path.join(dlc_dir, f) for f in os.listdir(dlc_dir)
            if not f.endswith(".manifest")
        ]
        print(f"\n--- DLC: {dlc_name} ({len(bundle_files)} bundles) ---")
        for bf in bundle_files:
            total += extract_from_assets(bf, dlc_out, seen_names)

    print(f"\n===== Extracted {total} UI textures to {OUTPUT_DIR} =====")


if __name__ == "__main__":
    main()
