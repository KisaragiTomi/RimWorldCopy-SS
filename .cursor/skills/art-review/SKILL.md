---
name: art-review
description: >-
  对比 video_frames 和参考截图，分析美术和交互的不足，输出改进清单。
  优先使用环世界原版贴图，覆盖地形、建筑、角色、物品、UI、光照六大维度。
  触发词: 美术检查、美术对比、art review、视觉对比、贴图检查。
---

# 美术检查 Skill

## 参考资源路径

| 资源 | 路径 |
|------|------|
| 原版 RimWorld | `D:\SteamLibrary\steamapps\common\RimWorld` |
| 游戏 sprites | `assets/textures/sprites/` (plants 30种/items 14种/pawns/animals) |
| 游戏 tiles | `assets/textures/tiles/` (terrain 52种) |
| 建筑贴图 | `assets/textures/buildings/` |
| 参考截图 | `D:\MyProject\RimWorldCopy-Surpervisor\screenshots` |
| 参考 video_frames | `D:\MyProject\RimWorldCopy-Surpervisor\video_frames` |
| 当前截图 | `d:\MyProject\RimWorldCopy\screenshots` |

## 工具脚本

| 文件 | 用途 |
|------|------|
| `take_screenshot.py` | TCP 截图工具：`python .cursor/skills/art-review/take_screenshot.py [输出路径]` |

## 检查流程

1. **采集当前画面** — 运行 `take_screenshot.py` 或读取已有截图
2. **加载参考图** — 读取 video_frames 或 supervisor screenshots
3. **六维度对比** — 每个维度输出：当前状态 → 原版表现 → 差距 → 改进方案

## 六维度检查清单

### A: 地形 (Terrain)
- 纹理变体 (4 个 _v0~_v3)、地形过渡混合、矿脉颜色、水域渲染

### B: 建筑 (Buildings)
- 墙体 Wall_Atlas 自动拼接、门开关、家具方向变体、蓝图半透明

### C: 角色 (Pawns)
- 体型×方向贴图、发型、服装叠加、倒地/征召/睡眠状态、朝向切换

### D: 物品与植物 (Items & Plants)
- 14 种物品贴图、堆叠视觉、7 种树×2 阶段、作物生长、地面装饰

### E: UI 界面
- 殖民者头像栏、资源面板、速度控制、底部菜单、小地图、通知

### F: 光照与效果
- 昼夜循环、室内灯光（Campfire/TorchLamp 光晕）、天气粒子、选中框

## 原版贴图优先级

1. `sprites/` → 渲染精灵（直接可用）
2. `tiles/` → TileMap 地形（已切好）
3. `buildings/` → 建筑贴图（已就绪）
4. `extracted/` → 完整提取集（补充用）

从原版提取：`D:\SteamLibrary\steamapps\common\RimWorld\Data\Core\Textures\`

## 输出格式

```markdown
## 美术检查报告 RXXX

### 总评
整体风格匹配度: X/10 | 最大差距: [维度名]

### 各维度评分
| 维度 | 评分 | 关键问题 |

### 优先修复项（按影响排序）
1. [问题] — 修复方案

### 资产缺失清单
| 缺失资产 | 原版路径 | 建议操作 |
```

## 交互检查

| 检查项 | 预期行为 |
|--------|---------|
| 点击地面 | 显示 cell 信息 |
| 点击殖民者 | 选中并显示详情 |
| 缩放/平移 | 滚轮缩放，中键拖拽 |
| 建造 | Architect 菜单放置 |
