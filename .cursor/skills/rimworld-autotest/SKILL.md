---
name: rimworld-autotest
description: >-
  自动化运行 RimWorld 复刻游戏并进行测试验证。通过 TCP 接口控制游戏、注入数据日志、
  分析运行结果。触发词: 运行测试、自动测试、监控游戏、autotest。
---

# RimWorld 自动化测试

## 连接

游戏内 McpInteractionServer 监听 `127.0.0.1:9090`，JSON 行协议，每条命令一个 TCP 连接。

**协议格式**: `{"command": "<cmd>", "params": {<参数>}}`

### 核心命令

| 命令             | params                                              | 用途                          |
| ---------------- | --------------------------------------------------- | ----------------------------- |
| screenshot       | `{}`                                                | 截图，返回 base64 PNG         |
| click            | `{"x": float, "y": float, "button": 1}`            | 点击屏幕坐标（1=左键 2=右键） |
| pause            | `{"paused": bool}`                                  | 暂停/恢复游戏                 |
| key_press        | `{"key": "Space"}` 或 `{"action": "ui_accept"}`     | 按键/动作模拟                 |
| mouse_move       | `{"x": float, "y": float}`                         | 移动鼠标到坐标                |
| mouse_drag       | `{"from_x","from_y","to_x","to_y","steps":10}`     | 拖拽操作                      |
| scroll           | `{"x": float, "y": float, "direction": "up/down"}` | 滚轮缩放/滚动                 |
| get_ui_elements  | `{}`                                                | 获取所有可见 UI 元素及坐标     |
| eval             | `{"code": "GDScript"}`                              | 执行代码，**仅用于读取数据**   |

eval 代码用 tab 缩进，最后一行必须 return。可访问所有 autoload 单例。

### 屏幕点击操作原则

**所有游戏操作必须通过屏幕点击实现**，eval 仅用于查询/读取数据。

操作流程：
1. `screenshot` → 识别当前画面和目标位置
2. `get_ui_elements` → 获取按钮/标签等 UI 元素的精确坐标
3. `click` → 点击目标位置
4. `screenshot` → 验证操作结果

### 征召/操作角色流程

```
1. pause(paused=true)          # 暂停游戏
2. screenshot                  # 截图定位角色位置
3. click(x, y)                 # 点击选中角色
4. screenshot                  # 确认角色被选中，查看下方 UI 面板
5. get_ui_elements             # 找到"征召"按钮坐标
6. click(btn_x, btn_y)        # 点击征召按钮
7. screenshot                  # 确认角色已征召
8. click(target_x, target_y, button=2)  # 右键点击目标位置下达命令
9. pause(paused=false)         # 恢复游戏
```

### 常用交互模式

| 操作         | 步骤                                                         |
| ------------ | ------------------------------------------------------------ |
| 选中角色     | 暂停 → 截图定位 → 左键点击角色                               |
| 征召角色     | 选中角色 → `get_ui_elements` 找征召按钮 → 点击               |
| 下达移动命令 | 征召后 → 右键点击目标地                                      |
| 建造建筑     | 点击底栏建筑菜单 → 选择建筑类型 → 左键放置位置               |
| 缩放地图     | `scroll` direction=up/down                                   |
| 平移地图     | `mouse_drag` 右键拖拽或 WASD `key_press`                     |
| 设置区域     | 点击区域工具 → `mouse_drag` 左键框选范围                     |

## 视频截取验证

测试时使用视频截取代替单张截图，跟随目标殖民者周围 5 cell 范围录制 60 帧。

```powershell
# 按索引跟随第 0 个殖民者
python tools/capture_pawn_video.py 0 screenshots/pawn_test.mp4

# 按名字跟随
python tools/capture_pawn_video.py --name "Ozzy" screenshots/ozzy.mp4

# 自定义参数
python tools/capture_pawn_video.py 0 screenshots/test.mp4 --frames 60 --radius 5 --fps 20
```

| 参数      | 默认值 | 含义                       |
| --------- | ------ | -------------------------- |
| --frames  | 60     | 捕获帧数                   |
| --radius  | 5      | 殖民者周围 cell 可见半径    |
| --fps     | 20     | 输出视频帧率               |
| --name    | —      | 按名字指定殖民者（替代索引）|

工作原理：eval 查询殖民者位置 → set_camera 跟随 → screenshot 截帧 → FFmpeg 编码 MP4。
结束后自动恢复相机位置。

## 游戏启动

```
Godot:  D:/Godot/godot-source/bin/godot.windows.editor.x86_64.exe
参数:   --path d:/MyProject/RimWorldCopy
```

启动后自动进入游戏场景（`main.gd` 中 `_ready()` 直接调用 `switch_to_game()`），无需手动切换。

## 数据日志

### 自动注入

`_DataLogger` 节点在游戏场景加载 10 秒后自动注入：

- 逻辑脚本: `scripts/utils/auto_logger.gd`
- 采样方式: **每 10 帧轮流记录 1 个殖民者**（round-robin）
- 缓冲区: 300 条环形缓冲区
- 自动保存: 缓冲区满时自动写入 `logs/game_raw_data.json`

### 手动拉取

通过 eval 发送 `templates/fetch_log.gd` 可立即保存日志到 `logs/game_raw_data.json`。

### 配置

| 参数        | 默认值            | 含义                             |
| ----------- | ----------------- | -------------------------------- |
| max_entries | 300               | 环形缓冲区上限                   |
| save_name   | `"game_raw_data"` | 保存文件名（不含扩展名）         |
| 保存路径    | —                 | `项目根目录/logs/game_raw_data.json` |

### GDScript 模板

| 文件                         | 用途                                  |
| ---------------------------- | ------------------------------------- |
| `templates/fetch_log.gd`    | 拉取并保存日志到 `logs/`，返回条数和路径 |
| `templates/stop_log.gd`     | 停止日志并返回条数                     |
| `templates/pawn_status.gd`  | 殖民者详细状态（含 cell 内容和装备）   |
| `templates/game_status.gd`  | 游戏状态查询（tick/日期/人口/FPS）     |

> 征召角色请通过屏幕点击 UI 实现，参考「征召/操作角色流程」。

## 常用 eval（仅用于数据查询）

| 操作         | 代码                                                                  |
| ------------ | --------------------------------------------------------------------- |
| 查询游戏状态 | `var d = TickManager.get_date()\nreturn {"tick": TickManager.current_tick, "year": d.year, "day": d.day}` |
| 查询角色状态 | `var p = PawnManager.pawns[0]\nreturn {"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], "drafted": p.drafted}` |
| 查询 UI 元素 | 用 `get_ui_elements` 命令代替 eval                                    |

> **注意**: 设置速度、触发事件、征召角色等**操作类动作**应通过屏幕点击 UI 实现，不用 eval。

## 关键 API

| 对象         | 常用属性/方法                                                                     |
| ------------ | --------------------------------------------------------------------------------- |
| Pawn         | `pawn_name`, `grid_pos`, `current_job_name`, `get_need("Food"/"Rest"/"Mood")`, `drafted`, `downed`, `dead`, `equipment.slots` |
| Cell         | `terrain_def`, `roof`, `is_mountain`, `elevation`, `fertility`, `building`, `things`, `zone` |
| Thing        | `def_name`, `grid_pos`, `get_class()`, `hit_points`                               |
| ThingManager | `things`, `get_things_at(pos)`, `get_buildings()`, `place_blueprint(def, pos)`    |

> Pawn 是 RefCounted（非 Node2D），用 `grid_pos` 而非 `position`。

## Python 工具脚本

| 脚本                      | 用途                                   |
| ------------------------- | -------------------------------------- |
| `tools/switch_game.py`    | 切换到游戏场景                         |
| `tools/ffwd_noon.py`      | 快进到正午并截图                       |
| `tools/ffwd_night.py`     | 快进到深夜并截图                       |
| `tools/take_screenshot.py`| 简单截图                               |
| `tools/zoom_base.py`      | 放大到基地中心并截图                   |
| `tools/reset_zoom.py`     | 重置相机缩放                           |
| `tools/quick_status.py`   | 快速检查游戏状态                       |
| `tools/check_logger.py`   | 检查 DataLogger 状态                   |
| `tools/save_log.py`       | 注入 DataLogger 并保存                 |

## 渲染信息

| 内容     | 说明                                                          |
| -------- | ------------------------------------------------------------- |
| 原版贴图 | `assets/textures/tiles/` terrain, `sprites/plants/`, `sprites/items/` |
| 植物渲染 | Tree → Sprite2D(48×48 → 3格宽), 其他 → Sprite2D(32×32 → 2格) |
| 物品渲染 | 有贴图 → Sprite2D(32×32 → 1格), 回退 → TileMap               |
| 树种     | 7 种: Oak/Pine/Birch/Poplar/Maple/Cypress/Willow              |
| 地面装饰 | 土壤上 6% 散布 GrassA/Dandelion 精灵                         |

## 已知限制

- 热重载: `script.reload()` 无法替换运行中方法，需重启
- 存档: `load_map()` 不恢复 pawns/things
- 截图: key 兼容 `data` 和 `result.image`
