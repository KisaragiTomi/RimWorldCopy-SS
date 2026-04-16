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
| 原版 RimWorld 安装目录 | `D:\SteamLibrary\steamapps\common\RimWorld` |
| 原版贴图提取 | `assets/textures/extracted/` (plants/items/pawns/terrain/apparel/animals) |
| 游戏使用 sprites | `assets/textures/sprites/` (plants 30种/items 14种/pawns/animals) |
| 游戏使用 tiles | `assets/textures/tiles/` (terrain 52种/plants/items) |
| 建筑贴图 | `assets/textures/buildings/` |
| UI 贴图 | `assets/textures/ui/` |
| 参考截图（真机） | `D:\MyProject\RimWorldCopy-Surpervisor\screenshots` |
| 参考 video_frames | `D:\MyProject\RimWorldCopy-Surpervisor\video_frames` (v1_frame_01~07, v2_frame_01~10) |
| 当前游戏截图 | `d:\MyProject\RimWorldCopy\screenshots` |

## 检查流程

### 1. 采集当前画面

通过 TCP 截图或用已有截图：

    # TCP 截图（游戏需运行中）
    import socket, json, base64, pathlib
    s = socket.create_connection(("127.0.0.1", 9090), timeout=5)
    s.sendall(json.dumps({"command": "screenshot"}).encode() + b"\n")
    data = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        data += chunk
    s.close()
    result = json.loads(data)
    img_b64 = result.get("data") or result.get("result", {}).get("image", "")
    pathlib.Path("screenshots/art_check.png").write_bytes(base64.b64decode(img_b64))

或直接读取已有截图文件进行分析。

### 2. 加载参考图

读取以下参考图作为对比基准：

- `D:\MyProject\RimWorldCopy-Surpervisor\video_frames\v2_frame_*.png` — 原版 RimWorld 实机画面（中文版，含建筑内部、夜间光照、家具摆放）
- `D:\MyProject\RimWorldCopy-Surpervisor\screenshots\*.png` — 我们游戏的早期截图

### 3. 六维度对比检查

每个维度输出：当前状态 → 原版表现 → 差距 → 改进方案。

#### 维度 A：地形 (Terrain)

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 地形纹理变体 | 每种地形 4 个变体 (_v0~_v3)，随机分布 | 查看 tiles/terrain/ 是否加载、变体是否随机 |
| 地形过渡 | 不同地形边界平滑混合 | 截图对比边界区域 |
| 矿脉颜色 | Steel=蓝灰, Gold=金黄, Jade=翠绿 | 检查矿脉 tile 是否使用原版贴图 |
| 水域 | 湖泊/河流有半透明水面 | 检查 Marsh/Water terrain 渲染 |

相关资产：`assets/textures/tiles/terrain/` (52 种地形 tile)

#### 维度 B：建筑 (Buildings)

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 墙体 | Wall_Atlas 自动拼接，区分材质 (Stone/Wood/Steel) | 检查 buildings/ 中的 Wall_Atlas 是否使用 |
| 门 | 开关动画，Door 贴图区分单双 | 检查 Door*.png 是否加载 |
| 家具 | Bed/Table/Chair/Stove 使用原版贴图，有方向变体 (north/south/east) | 对比 buildings/ 中家具贴图与游戏渲染 |
| 蓝图 | 建造中物体半透明蓝色描边 | 截图检查建造中状态 |

相关资产：`assets/textures/buildings/` (Bed, Door, Shelf, Wall_Atlas 等)

#### 维度 C：角色 (Pawns)

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 身体贴图 | 体型 (Male/Female/Thin/Fat/Hulk) × 方向 (south/north/east) | 检查 sprites/pawns/ 加载情况 |
| 头发 | HairA/B/C 不同发型 | 检查 sprites/pawns/Hair*.png |
| 服装 | 衣服叠加在身体上 (apparel layer) | 对比 extracted/apparel/ 使用情况 |
| 表情/状态 | 倒地、征召、睡眠(Zzz) 视觉反馈 | 运行时截图检查 |
| 朝向 | 4 方向精灵切换 | 检查移动时方向是否变化 |

相关资产：`assets/textures/sprites/pawns/`, `assets/textures/extracted/pawns/`, `assets/textures/extracted/apparel/`

#### 维度 D：物品与植物 (Items & Plants)

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 物品贴图 | Steel/Wood/Silver 等 14 种有独立贴图 (32×32) | 检查 sprites/items/ 是否全部加载 |
| 物品堆叠 | 数量多时视觉变化（小堆→大堆） | eval 检查地面物品渲染 |
| 树木 | 7 种树 × 成熟/幼苗 两阶段，48×48 精灵 | 对比 sprites/plants/Tree*.png |
| 作物 | Potato/Corn/Cotton 等按生长阶段变化 | 检查 growth_stage 对应的贴图切换 |
| 地面装饰 | GrassA/Dandelion 散布在土壤上 (6%) | 截图查看是否有碎草花装饰 |

相关资产：`assets/textures/sprites/items/` (14种), `assets/textures/sprites/plants/` (30种)

#### 维度 E：UI 界面

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 殖民者头像栏 | 顶部居中，绿框包裹头像+名字 | 截图对比位置和样式 |
| 资源面板 | 左侧折叠列表 (Materials/Metals/Food/Medicine) | 检查布局和数值显示 |
| 速度控制 | 右上角暂停/1x/2x/3x 按钮 | 检查按钮样式 |
| 底部菜单 | 双层标签栏 (Architect 子菜单 + 主菜单) | 对比按钮间距和颜色 |
| 小地图 | 右下角 minimap | 检查是否存在和比例 |
| 通知/告警 | 左上角事件消息 | 检查消息样式 |

#### 维度 F：光照与效果

| 检查项 | 原版特征 | 检查方法 |
|--------|---------|---------|
| 昼夜循环 | 白天亮，夜间暗（参考 v2_frame 的夜间效果） | 截图对比 |
| 室内光照 | 有灯火照明的房间内部较亮 | 检查建筑内部渲染 |
| 天气效果 | 雨/雪粒子 | 检查天气系统视觉 |
| 选中框 | 选中物体/区域有白色方框 | 检查选中高亮效果 |

## 原版贴图使用优先级

1. **sprites/** — 渲染用精灵（物品 32×32，树 48×48，角色各方向），已裁剪可直接用
2. **tiles/** — TileMap 地形 tile（含变体），已切好
3. **buildings/** — 建筑贴图（墙体 Atlas、家具方向），已就绪
4. **extracted/** — 从原版 DLL/资源中提取的完整贴图集，sprites/ 和 tiles/ 不够时从这里补充

### 从原版提取新贴图

原版安装路径：`D:\SteamLibrary\steamapps\common\RimWorld`

    # 贴图位置
    Data/Core/Textures/Things/           # 物品、建筑、角色
    Data/Core/Textures/Terrain/          # 地形
    Data/Core/Textures/UI/               # UI 图标

用 Python Pillow 裁剪/缩放后放入对应的 sprites/ 或 tiles/ 目录。

## 输出格式

检查完成后输出结构化报告：

```markdown
## 美术检查报告 RXXX

### 总评
整体风格匹配度: X/10
最大差距领域: [维度名]

### 各维度评分
| 维度 | 评分 | 关键问题 |
|------|------|---------|
| 地形 | X/10 | ... |
| 建筑 | X/10 | ... |
| 角色 | X/10 | ... |
| 物品植物 | X/10 | ... |
| UI | X/10 | ... |
| 光照效果 | X/10 | ... |

### 优先修复项（按影响排序）
1. [最关键问题] — 修复方案
2. ...

### 资产缺失清单
| 缺失资产 | 原版路径 | 建议操作 |
|----------|---------|---------|
| ... | ... | 从原版提取/裁剪 |
```

## 交互检查补充

除美术外，同时关注基础交互：

| 检查项 | 预期行为 |
|--------|---------|
| 点击地面 | 显示 cell 信息面板 |
| 点击殖民者 | 选中并显示详情 |
| 拖拽选框 | 框选多个殖民者 |
| 右键 | 征召后右键移动/攻击 |
| 缩放 | 滚轮缩放地图 |
| 拖拽平移 | 中键/右键拖拽移动视角 |
| 建造 | Architect 菜单选择后放置 |

## 已知参考图说明

| 文件 | 内容 |
|------|------|
| v1_frame_01~07 | 原版 RimWorld 实机第一组（白天，基础建筑） |
| v2_frame_01~10 | 原版 RimWorld 实机第二组（夜间，完整基地，有家具和光照） |
| supervisor_check.png | 我们游戏早期版本（无建筑内部、基础 terrain） |
| f4_architect_menu.png | 建筑菜单展开状态 |
| f8_v2_raid_triggered.png | Raid 触发时画面 |
| round6.png / v2_final.png / v3_final.png | 不同测试轮次最终状态 |
