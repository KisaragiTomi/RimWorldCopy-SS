---
name: rimworld-autotest
description: >-
  自动化运行 RimWorld 复刻游戏并进行测试验证。通过 TCP 接口控制游戏、注入数据日志、
  分析运行结果。触发词: 运行测试、自动测试、监控游戏、autotest。
---

# RimWorld 自动化测试

## 连接

游戏内 McpInteractionServer 监听 127.0.0.1:9090，JSON 行协议，每条命令一个 TCP 连接。

| 命令 | 参数 | 用途 |
|------|------|------|
| eval | code (GDScript) | 执行代码，return 返回结果 |
| screenshot | 无 | 截图，返回 base64 PNG |
| pause | paused (bool) | 暂停/恢复 |

eval 代码用 tab 缩进，最后一行必须 return。可访问 autoload：TickManager, PawnManager, ThingManager, GameState, IncidentManager, SaveLoad, ZoneManager, RaidManager, ColonyLog。

## 游戏启动

    Godot: D:/Godot/godot-source/bin/godot.windows.editor.x86_64.exe
    参数:  --path d:/MyProject/RimWorldCopy

启动后 eval 切换场景：`get_tree().root.get_node("Main").switch_to_game()\nreturn "ok"`

## 目标化数据日志验证（首选）

截图验证成本高且不精确。优先用数据日志：先明确要验证什么修改，注入脚本只记录相关数据。

### 流程

1. 明确修改目标和预期行为
2. 用 eval 注入 `_DataLogger` 节点，每 60 tick（1 游戏秒）记录一次
3. 设置速度，运行指定时长
4. eval 拉取日志数据，分析是否符合预期

### 注入日志 (eval)

默认模板：300 条环形缓冲区，每游戏秒采集角色属性 + 所在 cell 内容。

    var existing = get_tree().root.get_node_or_null("_DataLogger")
    if existing:
    	existing.queue_free()
    var logger = Node.new()
    logger.name = "_DataLogger"
    logger.set_meta("log", [])
    logger.set_meta("max_entries", 300)
    logger.set_meta("interval", 60)
    logger.set_meta("counter", 0)
    get_tree().root.add_child(logger)
    TickManager.tick.connect(func(_t):
    	var c = logger.get_meta("counter") + 1
    	logger.set_meta("counter", c)
    	if c % logger.get_meta("interval") != 0:
    		return
    	var pawns_data = []
    	for p in PawnManager.pawns:
    		if p.dead:
    			continue
    		var pi = {"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], "job": p.current_job_name, "food": p.get_need("Food"), "rest": p.get_need("Rest"), "mood": p.get_need("Mood"), "drafted": p.drafted, "downed": p.downed, "gear": p.equipment.slots if p.equipment else {}}
    		var cell = GameState.active_map.get_cell_v(p.grid_pos)
    		if cell:
    			var ct = []
    			for t in cell.things:
    				ct.append({"def": t.def_name, "type": t.get_class()})
    			pi["cell"] = {"terrain": cell.terrain_def, "roof": cell.roof, "building": cell.building.def_name if cell.building else null, "zone": str(cell.zone) if cell.zone else null, "things": ct}
    		pawns_data.append(pi)
    	var entry = {"tick": TickManager.current_tick, "sec": c / 60, "pawns": pawns_data}
    	var log = logger.get_meta("log")
    	if log.size() >= logger.get_meta("max_entries"):
    		log.pop_front()
    	log.append(entry)
    )
    return "logger_installed_300"

精简模板（不采集角色，只记录自定义字段）：

    var existing = get_tree().root.get_node_or_null("_DataLogger")
    if existing:
    	existing.queue_free()
    var logger = Node.new()
    logger.name = "_DataLogger"
    logger.set_meta("log", [])
    logger.set_meta("max_entries", 300)
    logger.set_meta("interval", 60)
    logger.set_meta("counter", 0)
    get_tree().root.add_child(logger)
    TickManager.tick.connect(func(_t):
    	var c = logger.get_meta("counter") + 1
    	logger.set_meta("counter", c)
    	if c % logger.get_meta("interval") != 0:
    		return
    	var entry = {"tick": TickManager.current_tick, "sec": c / 60}
    	# === 添加要采集的字段 ===
    	var log = logger.get_meta("log")
    	if log.size() >= logger.get_meta("max_entries"):
    		log.pop_front()
    	log.append(entry)
    )
    return "logger_installed_300"

### 拉取日志 (eval)

    var logger = get_tree().root.get_node_or_null("_DataLogger")
    if not logger:
    	return {"error": "no_logger"}
    return logger.get_meta("log")

### 停止日志 (eval)

    var logger = get_tree().root.get_node_or_null("_DataLogger")
    if logger:
    	var data = logger.get_meta("log")
    	logger.queue_free()
    	return {"entries": data.size(), "stopped": true}
    return {"error": "no_logger"}

### 常用采集字段

| 目标 | 表达式 |
|------|--------|
| 敌人数 | `PawnManager.pawns.filter(func(p): return p.has_meta("faction") and p.get_meta("faction") == "enemy" and not p.dead).size()` |
| 死亡/倒地 | `{"dead": PawnManager.pawns.filter(func(p): return p.dead).size(), "downed": PawnManager.pawns.filter(func(p): return p.downed).size()}` |
| Job 分布 | 遍历 pawns 统计 current_job_name |
| 温度 | `GameState.temperature` |
| 物品数 | `ThingManager.things.size()` |
| 植物数 | `ThingManager.things.filter(func(t): return t is Plant).size()` |
| 物品位置 | `item.grid_pos` (非 cell)，`item.hit_points` (非 hp) |
| 工作优先级 | Think tree 按 work_types.json order 值排序: Cook(70)→Hunt(80)→Construct(90)→Sow(100)→Mine(110)→Haul(160) |
| 物品颜色 | map_viewport.gd ITEM_COLORS: Steel=蓝灰, Wood=棕, Silver=银白, Gold=金黄, Medicine=红, RawFood=棕黄 (共21种) |
| 植物颜色 | map_viewport.gd PLANT_COLORS: Potato=深绿, Rice=黄绿, Corn=暗绿, Cotton=灰绿, Healroot=青绿, Tree=墨绿 |

|| 殖民者详情 | 遍历 pawns: `p.pawn_name, p.grid_pos, p.current_job_name, p.get_need("Food"), p.get_need("Rest"), p.get_need("Mood")` |
|| Cell 内容（方法1） | `ThingManager.get_things_at(pos)` 返回该格所有 Thing |
|| Cell 内容（方法2） | `GameState.active_map.get_cell_v(p.grid_pos)` 返回 Cell 对象 |
|| Cell 属性 | cell.terrain_def, cell.roof, cell.is_mountain, cell.elevation, cell.fertility, cell.building, cell.things, cell.feature, cell.ore, cell.zone |
|| Pawn 属性 | p.pawn_name, p.grid_pos, p.current_job_name, p.health(RefCounted), p.skills, p.traits, p.needs, p.equipment, p.drafted, p.downed, p.dead, p.inventory, p.facing, p.gender, p.age |
|| 注意 | Pawn 是 RefCounted (非Node2D)，无 position 属性，用 grid_pos；health 是 RefCounted 对象，查 'hp' 字段 |
|| 殖民者装备 | `p.equipment.slots` → Dictionary {Weapon:"Revolver", BodyArmor:"FlakVest"} |
|| 植物详情 | `plant.def_name, plant.growth, plant.growth_stage, plant.grid_pos` |
|| 渲染信息 | Thing tile 键: `tx_<file>_<state>` (原版贴图) 或 `t_<def_name>_<shape><state>` (程序化回退) |
|| 原版贴图 | `assets/textures/tiles/` terrain(52), `sprites/plants/` 30种(48×48树/32×32灌木), `sprites/items/` 14种(32×32) |
|| 植物渲染 | Tree→Sprite2D(48×48→3格宽), 其他植物→Sprite2D(32×32→2格), 回退→TileMap |
|| 物品渲染 | 有贴图→Sprite2D(32×32→1格), 回退→TileMap shaped tile |
|| 树种分配 | 7种: Oak/Pine/Birch/Poplar/Maple/Cypress/Willow, 按位置hash分配 |
|| 地面装饰 | `_spawn_ground_clutter()` 土壤上6%散布GrassA/Dandelion精灵, z_index=0 |
|| 野生植被 | `_spawn_natural_vegetation()` 按肥力概率: SoilRich 10-16%, Soil 6-10%, Gravel 1.5%, 中心15格内留空 |

### 配置说明

| 参数 | 默认值 | 含义 |
|------|--------|------|
| max_entries | 300 | 环形缓冲区上限，满后覆盖最早条目 |
| interval | 60 | 采样间隔（tick），60=每游戏秒 |

修改上限示例：`logger.set_meta("max_entries", 600)` 改为 10 游戏分钟。

### 分析规则

拉取数据后：检查条数是否足够（≥30秒），对关键字段做 min/max/avg，与预期范围断言比较，异常时定位到具体 tick。环形缓冲区下最多 300 条（5 游戏分钟），超出部分已被覆盖。

## 常用 eval 片段

设置速度：`TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"`

殖民者详细状态：

    var result = []
    for p in PawnManager.pawns:
    	if p.dead: continue
    	var cell_things = ThingManager.get_things_at(p.grid_pos)
    	var cell_info = []
    	for t in cell_things:
    		cell_info.append({"type": t.get_class(), "def": t.def_name})
    	result.append({"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], "job": p.current_job_name, "food": p.get_need("Food"), "rest": p.get_need("Rest"), "mood": p.get_need("Mood"), "cell_things": cell_info, "gear": p.equipment.slots if p.equipment else {}})
    return result

状态查询：

    var d = TickManager.get_date()
    var dead_c = PawnManager.pawns.filter(func(p): return p.dead).size()
    return {"tick": TickManager.current_tick, "year": d.year, "quadrum": d.quadrum, "day": d.day, "pawns": PawnManager.pawns.size(), "dead": dead_c, "fps": Engine.get_frames_per_second()}

触发 Raid：`RaidManager.spawn_raid(5)\nreturn "ok"`

征召：

    var drafted = 0
    for p in PawnManager.pawns:
    	if drafted >= 20: break
    	if not p.dead and not p.downed and not p.drafted:
    		if not p.has_meta("faction") or p.get_meta("faction") != "enemy":
    			PawnManager.toggle_draft(p)
    			drafted += 1
    return {"drafted": drafted}

存档：`SaveLoad.save_game("<name>", GameState.get_map())\nreturn "saved"`

## 脚本化方案

    . "d:\MyProject\RimWorldCopy\tools\autotest.ps1"

| 函数 | 用途 |
|------|------|
| Send-Eval | 执行 GDScript |
| Get-GameStatus | 查询状态 |
| Set-GameSpeed -TPF 30 | 设置速度 |
| Switch-ToGame | 切换到游戏 |
| Invoke-Raid -Count 5 | 触发入侵 |
| Invoke-Draft / Invoke-Undraft | 征召/取消 |
| Save-Game / Test-SaveLoad | 存档/验证 |
| Run-AutoTest | 完整测试流程 |
| Start-MonitorLoop | 监控循环 |

## 已知限制

- 热重载: script.reload() 无法替换运行中方法，需重启
- 存档: load_map() 不恢复 pawns/things
- 截图: key 兼容 data 和 result.image
