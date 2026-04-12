"""
RimWorld Landscape Generator - 复刻环世界区域尺度地形生成
========================================================

RimWorld 的地形生成管线(GenStep pipeline):
1. GenStep_Terrain      → 海拔噪声 + 肥力噪声 → 分配基础地形
2. GenStep_Caves        → 在山体内挖洞穴
3. GenStep_RocksFromGrid → 在高海拔区域放置岩石块
4. GenStep_Scatterer    → 散布矿脉(钢铁/铀/黄金/翡翠等)
5. GenStep_Plants       → 根据肥力种植植物
6. GenStep_Rivers       → 生成河流(Perlin蠕虫)
7. GenStep_Roads        → 如果有道路则铺设
8. GenStep_FindPlayerStartSpot → 寻找出生点

核心噪声层:
- elevation (海拔):   决定山/丘陵/平地/水域
- fertility (肥力):   决定土壤类型和植被密度
- caves    (洞穴):   在山体内部挖空
- ore      (矿脉):   各种矿物分布

地形分配规则:
  elevation < 0.0        → 深水 (WaterDeep)
  elevation < 0.12       → 浅水 (WaterShallow)
  elevation < 0.40       → 沙地/土壤/肥沃土壤 (由fertility决定)
  elevation < 0.70       → 碎石/粗糙石地 (Gravel)
  elevation >= 0.70      → 山体岩石 (Rock/Mountain)

在平地区域(0.12~0.40), fertility决定:
  fertility < 0.30       → 沙地 (Sand)
  fertility < 0.55       → 土壤 (Soil)
  fertility >= 0.55      → 肥沃土壤 (RichSoil)
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import os
import sys
import json
from dataclasses import dataclass
from enum import IntEnum


# ========== Configuration ==========

@dataclass
class MapConfig:
    width: int = 275         # RimWorld standard: 250~325
    height: int = 275
    seed: int = 42
    
    # Biome parameters
    biome: str = "TemperateForest"  # 温带森林
    base_temperature: float = 15.0
    rainfall: float = 600.0         # mm/year
    
    # Generation tuning
    mountain_density: float = 0.35  # 0~1, higher = more mountains
    river_count: int = 1
    ore_richness: float = 1.0
    cave_density: float = 0.4
    
    # Guide image (RGB: R=elevation, G=fertility, B=water)
    guide_image_path: str = ""
    guide_blend: float = 0.6        # 0=ignore guide, 1=only guide


class TerrainType(IntEnum):
    WaterDeep = 0
    WaterShallow = 1
    Marsh = 2
    Sand = 3
    SoftSand = 4
    Soil = 5
    MossyTerrain = 6
    RichSoil = 7
    Gravel = 8
    RoughStone = 9
    SmoothStone = 10
    Ice = 11


# RimWorld-faithful color palette
TERRAIN_COLORS = {
    TerrainType.WaterDeep:    (40, 65, 110),
    TerrainType.WaterShallow: (75, 105, 145),
    TerrainType.Marsh:        (85, 110, 90),
    TerrainType.Sand:         (180, 165, 130),
    TerrainType.SoftSand:     (195, 180, 145),
    TerrainType.Soil:         (115, 100, 75),
    TerrainType.MossyTerrain: (90, 110, 75),
    TerrainType.RichSoil:     (80, 70, 45),
    TerrainType.Gravel:       (130, 125, 115),
    TerrainType.RoughStone:   (100, 95, 88),
    TerrainType.SmoothStone:  (120, 115, 108),
    TerrainType.Ice:          (200, 215, 225),
}

# Overlay colors
ORE_COLORS = {
    "Steel":       (140, 155, 165),
    "Compacted":   (130, 130, 125),
    "Gold":        (200, 180, 60),
    "Uranium":     (100, 170, 100),
    "Jade":        (80, 160, 110),
    "Plasteel":    (160, 190, 210),
}

FEATURE_COLORS = {
    "Cave":        (50, 45, 40),
    "SteamGeyser": (180, 180, 200),
    "AncientDanger":(140, 40, 40),
    "Tree":        (55, 85, 45),
    "Bush":        (75, 100, 60),
    "Rock":        (90, 85, 80),
}


# ========== Noise Functions ==========

class PerlinNoise:
    """Simplex-like noise using numpy for RimWorld-style terrain"""
    
    def __init__(self, seed: int = 0):
        self.rng = np.random.RandomState(seed)
        self.perm = np.arange(256, dtype=np.int32)
        self.rng.shuffle(self.perm)
        self.perm = np.tile(self.perm, 2)
        
        # Gradient vectors
        self.grad = self.rng.randn(256, 2).astype(np.float32)
        norms = np.sqrt((self.grad ** 2).sum(axis=1, keepdims=True))
        self.grad /= np.where(norms > 0, norms, 1)
    
    def _noise2d(self, x: np.ndarray, y: np.ndarray) -> np.ndarray:
        """2D Perlin noise"""
        xi = np.floor(x).astype(np.int32)
        yi = np.floor(y).astype(np.int32)
        xf = x - xi
        yf = y - yi
        
        # Fade curves
        u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
        v = yf * yf * yf * (yf * (yf * 6 - 15) + 10)
        
        # Hash corners
        aa = self.perm[(self.perm[xi & 255] + yi) & 255]
        ab = self.perm[(self.perm[xi & 255] + yi + 1) & 255]
        ba = self.perm[(self.perm[(xi + 1) & 255] + yi) & 255]
        bb = self.perm[(self.perm[(xi + 1) & 255] + yi + 1) & 255]
        
        # Gradients
        g_aa = self.grad[aa & 255]
        g_ab = self.grad[ab & 255]
        g_ba = self.grad[ba & 255]
        g_bb = self.grad[bb & 255]
        
        # Dot products
        d_aa = g_aa[..., 0] * xf + g_aa[..., 1] * yf
        d_ab = g_ab[..., 0] * xf + g_ab[..., 1] * (yf - 1)
        d_ba = g_ba[..., 0] * (xf - 1) + g_ba[..., 1] * yf
        d_bb = g_bb[..., 0] * (xf - 1) + g_bb[..., 1] * (yf - 1)
        
        # Bilinear interpolation
        x1 = d_aa + u * (d_ba - d_aa)
        x2 = d_ab + u * (d_bb - d_ab)
        
        return x1 + v * (x2 - x1)
    
    def fbm(self, x: np.ndarray, y: np.ndarray, octaves: int = 6,
            lacunarity: float = 2.0, persistence: float = 0.5) -> np.ndarray:
        """Fractal Brownian Motion - multi-octave noise"""
        result = np.zeros_like(x, dtype=np.float32)
        amplitude = 1.0
        frequency = 1.0
        max_val = 0.0
        
        for _ in range(octaves):
            result += amplitude * self._noise2d(x * frequency, y * frequency)
            max_val += amplitude
            amplitude *= persistence
            frequency *= lacunarity
        
        return result / max_val


# ========== Map Generator ==========

class RimWorldMapGenerator:
    """
    Replicates RimWorld's GenStep pipeline for map-level terrain generation.
    """
    
    def __init__(self, config: MapConfig):
        self.config = config
        self.w = config.width
        self.h = config.height
        
        # Noise generators with different seeds
        self.noise_elevation = PerlinNoise(config.seed)
        self.noise_fertility = PerlinNoise(config.seed + 1000)
        self.noise_caves     = PerlinNoise(config.seed + 2000)
        self.noise_ore       = PerlinNoise(config.seed + 3000)
        self.noise_detail    = PerlinNoise(config.seed + 4000)
        self.noise_river     = PerlinNoise(config.seed + 5000)
        
        # Guide image channels (None if no guide)
        self.guide_elevation = None  # R channel → elevation
        self.guide_fertility = None  # G channel → fertility
        self.guide_water     = None  # B channel → water/river
        self._load_guide_image()
        
        # Output layers
        self.elevation = np.zeros((self.h, self.w), dtype=np.float32)
        self.fertility = np.zeros((self.h, self.w), dtype=np.float32)
        self.cave_map  = np.zeros((self.h, self.w), dtype=np.float32)
        self.terrain   = np.full((self.h, self.w), TerrainType.Soil, dtype=np.int32)
        self.features  = np.full((self.h, self.w), "", dtype=object)
        self.ores      = np.full((self.h, self.w), "", dtype=object)
        self.is_mountain = np.zeros((self.h, self.w), dtype=bool)
        self.is_river  = np.zeros((self.h, self.w), dtype=bool)
        self.roofed    = np.zeros((self.h, self.w), dtype=bool)
        
        self.rng = np.random.RandomState(config.seed)
    
    def _load_guide_image(self):
        """Load RGB guide image and split into control channels"""
        if not self.config.guide_image_path:
            return
        
        path = self.config.guide_image_path
        if not os.path.exists(path):
            print(f"[Guide] Warning: guide image not found: {path}")
            return
        
        guide = Image.open(path).convert("RGB")
        guide = guide.resize((self.w, self.h), Image.BILINEAR)
        guide_arr = np.array(guide, dtype=np.float32) / 255.0
        
        self.guide_elevation = guide_arr[:, :, 0]  # R → elevation
        self.guide_fertility = guide_arr[:, :, 1]   # G → fertility
        self.guide_water     = guide_arr[:, :, 2]   # B → water/river
        
        print(f"[Guide] Loaded guide image: {path} ({guide.width}x{guide.height})")
        print(f"[Guide] Blend weight: {self.config.guide_blend}")
        print(f"[Guide]   R(elevation) range: {self.guide_elevation.min():.2f} ~ {self.guide_elevation.max():.2f}")
        print(f"[Guide]   G(fertility) range: {self.guide_fertility.min():.2f} ~ {self.guide_fertility.max():.2f}")
        print(f"[Guide]   B(water)     range: {self.guide_water.min():.2f} ~ {self.guide_water.max():.2f}")
    
    def generate(self):
        """Full generation pipeline"""
        print("[GenStep] Starting map generation...")
        self._gen_elevation()
        self._gen_fertility()
        self._gen_terrain_from_grids()
        self._gen_caves()
        self._gen_rivers()
        self._gen_ores()
        self._gen_features()
        self._gen_plants()
        print("[GenStep] Map generation complete!")
    
    # --- Step 1: Elevation ---
    def _gen_elevation(self):
        """GenStep_ElevationFertility - Elevation layer"""
        print("[GenStep] Generating elevation...")
        x = np.arange(self.w, dtype=np.float32)
        y = np.arange(self.h, dtype=np.float32)
        xx, yy = np.meshgrid(x, y)
        
        # Main terrain noise (low frequency for large features)
        scale = 0.012
        elev = self.noise_elevation.fbm(
            xx * scale, yy * scale,
            octaves=6, lacunarity=2.0, persistence=0.5
        )
        
        # Add medium-scale detail
        detail = self.noise_detail.fbm(
            xx * 0.04, yy * 0.04,
            octaves=4, lacunarity=2.0, persistence=0.45
        )
        elev = elev * 0.7 + detail * 0.3
        
        # Normalize to 0~1
        elev = (elev - elev.min()) / (elev.max() - elev.min() + 1e-8)
        
        # Apply mountain density bias
        mountain_thresh = 1.0 - self.config.mountain_density
        elev = np.power(elev, 1.2 + self.config.mountain_density * 0.3)
        
        # Edge fade - prevent mountains at map edges (RimWorld behavior)
        edge_dist = np.minimum(
            np.minimum(xx, self.w - 1 - xx),
            np.minimum(yy, self.h - 1 - yy)
        )
        edge_fade = np.clip(edge_dist / 15.0, 0.0, 1.0)
        elev *= edge_fade
        
        # Blend with guide image R channel (elevation)
        if self.guide_elevation is not None:
            b = self.config.guide_blend
            elev = elev * (1.0 - b) + self.guide_elevation * b
            print(f"[Guide] Blended R→elevation (weight={b})")
        
        self.elevation = elev
        self.is_mountain = elev >= 0.70
    
    # --- Step 2: Fertility ---
    def _gen_fertility(self):
        """GenStep_ElevationFertility - Fertility layer"""
        print("[GenStep] Generating fertility...")
        x = np.arange(self.w, dtype=np.float32)
        y = np.arange(self.h, dtype=np.float32)
        xx, yy = np.meshgrid(x, y)
        
        scale = 0.018
        fert = self.noise_fertility.fbm(
            xx * scale, yy * scale,
            octaves=5, lacunarity=2.0, persistence=0.5
        )
        
        # Normalize to 0~1
        fert = (fert - fert.min()) / (fert.max() - fert.min() + 1e-8)
        
        # Biome rainfall affects base fertility
        rainfall_factor = np.clip(self.config.rainfall / 800.0, 0.3, 1.0)
        fert *= rainfall_factor
        
        # Add detail variation
        x = np.arange(self.w, dtype=np.float32)
        y_arr = np.arange(self.h, dtype=np.float32)
        xx2, yy2 = np.meshgrid(x, y_arr)
        fert_detail = self.noise_detail.fbm(xx2 * 0.05, yy2 * 0.05, octaves=3)
        fert_detail = (fert_detail - fert_detail.min()) / (fert_detail.max() - fert_detail.min() + 1e-8)
        fert = fert * 0.7 + fert_detail * 0.3
        
        # Mountains have zero fertility
        fert[self.is_mountain] = 0.0
        
        # Blend with guide image G channel (fertility)
        if self.guide_fertility is not None:
            b = self.config.guide_blend
            fert_guided = fert * (1.0 - b) + self.guide_fertility * b
            fert_guided[self.is_mountain] = 0.0
            fert = fert_guided
            print(f"[Guide] Blended G→fertility (weight={b})")
        
        self.fertility = fert
    
    # --- Step 3: Terrain Assignment ---
    def _gen_terrain_from_grids(self):
        """GenStep_Terrain - Assign terrain types from elevation + fertility"""
        print("[GenStep] Assigning terrain types...")
        
        elev = self.elevation
        fert = self.fertility
        
        # Deep water
        self.terrain[elev < 0.03] = TerrainType.WaterDeep
        
        # Shallow water
        mask_shallow = (elev >= 0.03) & (elev < 0.10)
        self.terrain[mask_shallow] = TerrainType.WaterShallow
        
        # Marsh (near water, high fertility)
        mask_marsh = (elev >= 0.10) & (elev < 0.15) & (fert > 0.5)
        self.terrain[mask_marsh] = TerrainType.Marsh
        
        # Flat terrain zone
        mask_flat = (elev >= 0.10) & (elev < 0.55)
        
        # Sand (low fertility)
        mask_sand = mask_flat & (fert < 0.20)
        self.terrain[mask_sand] = TerrainType.Sand
        
        # Soft sand
        mask_ssand = mask_flat & (fert >= 0.20) & (fert < 0.30)
        self.terrain[mask_ssand] = TerrainType.SoftSand
        
        # Soil (medium fertility)
        mask_soil = mask_flat & (fert >= 0.30) & (fert < 0.50)
        self.terrain[mask_soil] = TerrainType.Soil
        
        # Mossy terrain
        mask_mossy = mask_flat & (fert >= 0.50) & (fert < 0.65)
        self.terrain[mask_mossy] = TerrainType.MossyTerrain
        
        # Rich soil (high fertility)
        mask_rich = mask_flat & (fert >= 0.65)
        self.terrain[mask_rich] = TerrainType.RichSoil
        
        # Gravel (transition to mountain)
        mask_gravel = (elev >= 0.55) & (elev < 0.70)
        self.terrain[mask_gravel] = TerrainType.Gravel
        
        # Mountain rock
        self.terrain[self.is_mountain] = TerrainType.RoughStone
        self.roofed[self.is_mountain] = True
    
    # --- Step 4: Caves ---
    def _gen_caves(self):
        """GenStep_Caves - Carve caves inside mountains"""
        print("[GenStep] Generating caves...")
        x = np.arange(self.w, dtype=np.float32)
        y = np.arange(self.h, dtype=np.float32)
        xx, yy = np.meshgrid(x, y)
        
        cave_noise = self.noise_caves.fbm(
            xx * 0.06, yy * 0.06,
            octaves=4, lacunarity=2.5, persistence=0.5
        )
        
        cave_noise = (cave_noise - cave_noise.min()) / (cave_noise.max() - cave_noise.min() + 1e-8)
        
        # Only carve inside mountains
        cave_threshold = 1.0 - self.config.cave_density * 0.6
        is_cave = self.is_mountain & (cave_noise > cave_threshold)
        
        # Must be deep enough inside mountain (distance from edge)
        from scipy.ndimage import distance_transform_edt
        mountain_dist = distance_transform_edt(self.is_mountain.astype(np.float32))
        is_cave = is_cave & (mountain_dist > 4)
        
        self.cave_map = is_cave.astype(np.float32)
        self.terrain[is_cave] = TerrainType.Gravel
        self.features[is_cave] = "Cave"
    
    # --- Step 5: Rivers ---
    def _gen_rivers(self):
        """GenStep_Rivers - Perlin worm river generation + guide B channel"""
        print("[GenStep] Generating rivers...")
        
        # If guide has water channel, paint water from B channel first
        if self.guide_water is not None:
            b = self.config.guide_blend
            water_mask = self.guide_water > 0.4
            deep_mask = self.guide_water > 0.7
            
            for y in range(self.h):
                for x in range(self.w):
                    if deep_mask[y, x]:
                        self.terrain[y, x] = TerrainType.WaterDeep
                        self.is_river[y, x] = True
                        self.is_mountain[y, x] = False
                        self.roofed[y, x] = False
                    elif water_mask[y, x]:
                        self.terrain[y, x] = TerrainType.WaterShallow
                        self.is_river[y, x] = True
                        self.is_mountain[y, x] = False
                        self.roofed[y, x] = False
            
            print(f"[Guide] Painted B→water ({np.sum(water_mask)} cells)")
        
        # Also generate procedural rivers
        for river_idx in range(self.config.river_count):
            self._carve_river(river_idx)
    
    def _carve_river(self, river_idx: int):
        """Carve a single river using Perlin worm technique"""
        # Start from a random edge
        edge = self.rng.randint(4)
        if edge == 0:    # Top
            cx, cy = self.rng.randint(self.w // 4, 3 * self.w // 4), 0
            angle = np.pi / 2 + self.rng.randn() * 0.3
        elif edge == 1:  # Bottom
            cx, cy = self.rng.randint(self.w // 4, 3 * self.w // 4), self.h - 1
            angle = -np.pi / 2 + self.rng.randn() * 0.3
        elif edge == 2:  # Left
            cx, cy = 0, self.rng.randint(self.h // 4, 3 * self.h // 4)
            angle = self.rng.randn() * 0.3
        else:            # Right
            cx, cy = self.w - 1, self.rng.randint(self.h // 4, 3 * self.h // 4)
            angle = np.pi + self.rng.randn() * 0.3
        
        river_noise = PerlinNoise(self.config.seed + 7000 + river_idx * 100)
        step = 0
        river_width_base = 3 + self.rng.randint(2)
        
        while 0 <= cx < self.w and 0 <= cy < self.h:
            # River width varies
            width = river_width_base + int(river_noise._noise2d(
                np.array([step * 0.05], dtype=np.float32),
                np.array([0.0], dtype=np.float32)
            )[0] * 2)
            width = max(2, min(width, 6))
            
            # Paint river cells
            for dx in range(-width, width + 1):
                for dy in range(-width, width + 1):
                    if dx * dx + dy * dy <= width * width:
                        rx, ry = int(cx) + dx, int(cy) + dy
                        if 0 <= rx < self.w and 0 <= ry < self.h:
                            dist = np.sqrt(dx * dx + dy * dy)
                            if dist < width * 0.6:
                                self.terrain[ry, rx] = TerrainType.WaterDeep
                            else:
                                if self.terrain[ry, rx] not in (TerrainType.WaterDeep,):
                                    self.terrain[ry, rx] = TerrainType.WaterShallow
                            self.is_river[ry, rx] = True
                            self.is_mountain[ry, rx] = False
                            self.roofed[ry, rx] = False
            
            # Advance along direction with noise perturbation
            noise_val = river_noise._noise2d(
                np.array([step * 0.02], dtype=np.float32),
                np.array([river_idx * 10.0], dtype=np.float32)
            )[0]
            angle += noise_val * 0.4
            
            # Bias toward center of map
            to_center_x = (self.w / 2 - cx) / self.w
            to_center_y = (self.h / 2 - cy) / self.h
            angle += to_center_x * 0.05 + to_center_y * 0.05
            
            cx += np.cos(angle) * 1.5
            cy += np.sin(angle) * 1.5
            step += 1
            
            if step > self.w + self.h:
                break
    
    # --- Step 6: Ores ---
    def _gen_ores(self):
        """GenStep_ScatterLumps - Place ore veins in mountains"""
        print("[GenStep] Generating ore deposits...")
        
        ore_types = [
            ("Compacted", 0.45, (8, 20)),   # (name, density, lump_size_range)
            ("Steel",     0.30, (6, 16)),
            ("Gold",      0.05, (3, 8)),
            ("Uranium",   0.04, (3, 6)),
            ("Jade",      0.03, (2, 5)),
            ("Plasteel",  0.02, (2, 4)),
        ]
        
        mountain_cells = np.argwhere(self.is_mountain & (self.cave_map < 0.5))
        if len(mountain_cells) == 0:
            return
        
        for ore_name, density, size_range in ore_types:
            count = int(len(mountain_cells) * density * self.config.ore_richness * 0.01)
            
            for _ in range(count):
                # Pick random mountain cell as lump center
                idx = self.rng.randint(len(mountain_cells))
                cy, cx = mountain_cells[idx]
                lump_size = self.rng.randint(size_range[0], size_range[1] + 1)
                
                # Grow lump organically
                for __ in range(lump_size):
                    ox = cx + self.rng.randint(-2, 3)
                    oy = cy + self.rng.randint(-2, 3)
                    if 0 <= ox < self.w and 0 <= oy < self.h:
                        if self.is_mountain[oy, ox] and self.ores[oy, ox] == "":
                            self.ores[oy, ox] = ore_name
    
    # --- Step 7: Features ---
    def _gen_features(self):
        """GenStep_SteamGeysers + GenStep_AncientShrines"""
        print("[GenStep] Placing features...")
        
        # Steam geysers (3~6 per map, on non-mountain flat terrain)
        flat_cells = np.argwhere(
            ~self.is_mountain & ~self.is_river & 
            (self.elevation > 0.15) & (self.elevation < 0.50)
        )
        
        if len(flat_cells) > 0:
            geyser_count = self.rng.randint(3, 7)
            for _ in range(geyser_count):
                idx = self.rng.randint(len(flat_cells))
                gy, gx = flat_cells[idx]
                self.features[gy, gx] = "SteamGeyser"
        
        # Ancient danger (0~1 per map, inside mountain)
        mountain_cave_cells = np.argwhere(self.cave_map > 0.5)
        if len(mountain_cave_cells) > 10 and self.rng.random() > 0.3:
            idx = self.rng.randint(len(mountain_cave_cells))
            ay, ax = mountain_cave_cells[idx]
            # Mark a rectangular area
            for dx in range(-4, 5):
                for dy in range(-3, 4):
                    nx, ny = ax + dx, ay + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h:
                        self.features[ny, nx] = "AncientDanger"
    
    # --- Step 8: Plants ---
    def _gen_plants(self):
        """GenStep_Plants - scatter trees and bushes based on fertility"""
        print("[GenStep] Planting vegetation...")
        
        for y in range(self.h):
            for x in range(self.w):
                if self.is_mountain[y, x] or self.is_river[y, x]:
                    continue
                if self.terrain[y, x] in (TerrainType.WaterDeep, TerrainType.WaterShallow):
                    continue
                if self.features[y, x] != "":
                    continue
                
                fert = self.fertility[y, x]
                rand = self.rng.random()
                
                # Tree probability based on fertility and biome
                tree_chance = fert * 0.25
                bush_chance = fert * 0.15
                
                if self.config.biome == "TemperateForest":
                    tree_chance *= 1.5
                    bush_chance *= 1.2
                elif self.config.biome == "BorealForest":
                    tree_chance *= 1.2
                elif self.config.biome == "Arid":
                    tree_chance *= 0.3
                    bush_chance *= 0.5
                
                if rand < tree_chance:
                    self.features[y, x] = "Tree"
                elif rand < tree_chance + bush_chance:
                    self.features[y, x] = "Bush"
    
    # --- Rendering ---
    def render(self, show_ores: bool = True, show_features: bool = True) -> Image.Image:
        """Render the map to a PIL Image"""
        img = Image.new("RGB", (self.w, self.h))
        pixels = img.load()
        
        for y in range(self.h):
            for x in range(self.w):
                terrain_type = TerrainType(self.terrain[y, x])
                r, g, b = TERRAIN_COLORS[terrain_type]
                
                # Elevation shading
                shade = 0.85 + self.elevation[y, x] * 0.15
                r = int(r * shade)
                g = int(g * shade)
                b = int(b * shade)
                
                # Cave darkening
                if self.cave_map[y, x] > 0.5 and self.features[y, x] == "Cave":
                    r, g, b = FEATURE_COLORS["Cave"]
                
                # Ore overlay
                if show_ores and self.ores[y, x] != "":
                    ore_color = ORE_COLORS.get(self.ores[y, x], (128, 128, 128))
                    r = (r + ore_color[0]) // 2
                    g = (g + ore_color[1]) // 2
                    b = (b + ore_color[2]) // 2
                
                # Feature overlay
                if show_features and self.features[y, x] != "":
                    feat = self.features[y, x]
                    if feat in FEATURE_COLORS and feat != "Cave":
                        fc = FEATURE_COLORS[feat]
                        alpha = 0.7 if feat in ("Tree", "Bush") else 0.9
                        r = int(r * (1 - alpha) + fc[0] * alpha)
                        g = int(g * (1 - alpha) + fc[1] * alpha)
                        b = int(b * (1 - alpha) + fc[2] * alpha)
                
                pixels[x, y] = (
                    max(0, min(255, r)),
                    max(0, min(255, g)),
                    max(0, min(255, b)),
                )
        
        return img
    
    def get_terrain_distribution(self) -> dict:
        total = self.w * self.h
        unique, counts = np.unique(self.terrain, return_counts=True)
        return {TerrainType(t).name: round(c / total * 100, 2) for t, c in zip(unique, counts)}

    def get_mountain_coverage(self) -> float:
        return round(float(np.mean(self.is_mountain)) * 100, 2)

    def get_water_coverage(self) -> float:
        water_mask = (self.terrain == TerrainType.WaterDeep) | (self.terrain == TerrainType.WaterShallow)
        return round(float(np.mean(water_mask)) * 100, 2)

    def get_terrain_entropy(self) -> float:
        total = self.w * self.h
        _, counts = np.unique(self.terrain, return_counts=True)
        probs = counts / total
        entropy = -float(np.sum(probs * np.log2(probs + 1e-10)))
        return round(entropy, 2)

    def get_resource_concentration_pct(self) -> float:
        total_cells = self.w * self.h
        ore_cells = int(np.sum(self.ores != ""))
        tree_cells = int(np.sum(self.features == "Tree"))
        return round((ore_cells + tree_cells) / max(total_cells, 1) * 100, 1)

    def get_habitability_score(self) -> float:
        flat_mask = ~self.is_mountain & ~self.is_river
        flat_pct = float(np.mean(flat_mask))
        avg_fertility = float(np.mean(self.fertility[flat_mask])) if np.any(flat_mask) else 0.0
        return round(flat_pct * avg_fertility * 100, 1)

    def get_summary(self) -> dict:
        return {
            "map_size": f"{self.w}x{self.h}",
            "seed": self.config.seed,
            "terrain_distribution": self.get_terrain_distribution(),
            "mountain_pct": self.get_mountain_coverage(),
            "water_pct": self.get_water_coverage(),
            "ore_deposits": int(np.sum(self.ores != "")),
            "tree_count": int(np.sum(self.features == "Tree")),
            "cave_cells": int(np.sum(self.cave_map > 0.5)),
            "river_cells": int(np.sum(self.is_river)),
            "terrain_entropy": self.get_terrain_entropy(),
            "resource_concentration_pct": self.get_resource_concentration_pct(),
            "habitability_score": self.get_habitability_score(),
        }

    def render_layers(self) -> dict:
        """Render individual layers for debugging"""
        layers = {}
        
        # Elevation
        elev_img = Image.new("L", (self.w, self.h))
        elev_pixels = elev_img.load()
        for y in range(self.h):
            for x in range(self.w):
                elev_pixels[x, y] = int(self.elevation[y, x] * 255)
        layers["elevation"] = elev_img
        
        # Fertility
        fert_img = Image.new("L", (self.w, self.h))
        fert_pixels = fert_img.load()
        for y in range(self.h):
            for x in range(self.w):
                fert_pixels[x, y] = int(self.fertility[y, x] * 255)
        layers["fertility"] = fert_img
        
        return layers


# ========== Main ==========

def main():
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
    
    print("=" * 60)
    print("  RimWorld Landscape Generator")
    print("  Replicating GenStep terrain pipeline")
    print("=" * 60)
    
    # Parse arguments
    seed = 42
    guide_path = ""
    guide_blend = 0.6
    
    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == "--guide" and i + 1 < len(sys.argv):
            guide_path = sys.argv[i + 1]
            if not os.path.isabs(guide_path):
                guide_path = os.path.join(output_dir, guide_path)
            i += 2
        elif arg == "--blend" and i + 1 < len(sys.argv):
            guide_blend = float(sys.argv[i + 1])
            i += 2
        elif arg.isdigit():
            seed = int(arg)
            i += 1
        else:
            i += 1
    
    config = MapConfig(
        width=275,
        height=275,
        seed=seed,
        biome="TemperateForest",
        base_temperature=15.0,
        rainfall=600.0,
        mountain_density=0.35,
        river_count=1,
        ore_richness=1.0,
        cave_density=0.4,
        guide_image_path=guide_path,
        guide_blend=guide_blend,
    )
    
    print(f"\nConfig: {config.width}x{config.height}, seed={config.seed}")
    print(f"Biome: {config.biome}, Mountains: {config.mountain_density}")
    if guide_path:
        print(f"Guide: {guide_path} (blend={guide_blend})")
    print()
    
    gen = RimWorldMapGenerator(config)
    gen.generate()
    
    # Render full map
    print("\n[Render] Rendering terrain map...")
    img = gen.render(show_ores=True, show_features=True)
    
    # Scale up for visibility (4x)
    scale = 4
    img_scaled = img.resize((config.width * scale, config.height * scale), Image.NEAREST)
    
    # Save
    full_path = os.path.join(output_dir, f"landscape_seed{seed}.png")
    img_scaled.save(full_path)
    print(f"[Render] Saved: {full_path}")
    
    # Render individual layers
    layers = gen.render_layers()
    for name, layer_img in layers.items():
        layer_scaled = layer_img.resize((config.width * scale, config.height * scale), Image.NEAREST)
        layer_path = os.path.join(output_dir, f"layer_{name}_seed{seed}.png")
        layer_scaled.save(layer_path)
        print(f"[Render] Saved layer: {layer_path}")
    
    # Statistics
    unique, counts = np.unique(gen.terrain, return_counts=True)
    print("\n--- Terrain Statistics ---")
    for t, c in zip(unique, counts):
        name = TerrainType(t).name
        pct = c / (config.width * config.height) * 100
        print(f"  {name:20s}: {c:6d} cells ({pct:.1f}%)")
    
    ore_count = np.sum(gen.ores != "")
    cave_count = np.sum(gen.cave_map > 0.5)
    tree_count = np.sum(gen.features == "Tree")
    print(f"\n  Ore deposits: {ore_count}")
    print(f"  Cave cells:   {cave_count}")
    print(f"  Trees:        {tree_count}")
    print(f"\nDone!")


if __name__ == "__main__":
    main()
