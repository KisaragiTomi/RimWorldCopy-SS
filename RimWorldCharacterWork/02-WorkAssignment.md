# Layer 2: 工作分配层 — Work Assignment

## 概述

当 ThinkTree 遍历到 `JobGiver_Work` 节点时，进入工作分配流程。此层负责：
1. 根据玩家设定的优先级排序工作列表
2. 遍历 WorkGiver 寻找可做的工作
3. 找到最佳目标后创建 Job

## 类关系

```
JobGiver_Work (extends ThinkNode)
  ├── 读取 Pawn_WorkSettings 获取排序后的 WorkGiver 列表
  ├── 遍历 WorkGiver 列表
  │     ├── WorkGiver.NonScanJob()     ← 非扫描类工作
  │     └── WorkGiver_Scanner          ← 扫描类工作
  │           ├── scanThings → 扫描 Thing 列表
  │           └── scanCells  → 扫描 Cell 列表
  └── 返回 ThinkResult(Job)

WorkTypeDef (工作大类)
  └── workGiversByPriority: List<WorkGiverDef> (具体工作，按优先级排序)
        └── WorkGiverDef.Worker → WorkGiver 实例
```

## JobGiver_Work

**命名空间**: `RimWorld`  
**文件**: `JobGiver_Work.cs`  
**继承**: `ThinkNode`（不是 ThinkNode_JobGiver）

这是工作系统最核心的类。在 ThinkTree 中通常有两个实例：
- `emergency = true` — 紧急工作（如灭火、救治）
- `emergency = false` — 常规工作

### 优先级与时间安排

`GetPriority()` 根据 Pawn 当前的时间表返回不同权重：

| 时间安排 | 工作优先级 | 含义 |
|---------|----------|------|
| Work | 9.0 | 工作时段，最高优先 |
| Anything | 5.5 | 自由时段 |
| Sleep | 3.0 | 睡眠时段（但仍可能工作） |
| Joy | 2.0 | 娱乐时段 |
| Meditate | 2.0 | 冥想时段 |

### 核心流程：TryIssueJobPackage

```
1. 如果 Pawn 在分娩中 → 跳过
2. 如果是紧急模式且有玩家指定的优先工作：
   → 在指定位置尝试指定 WorkGiver → 标记 playerForced
3. 获取工作列表：
   - emergency=true → WorkGiversInOrderEmergency
   - emergency=false → WorkGiversInOrderNormal
4. 遍历工作列表：
   for each WorkGiver:
     a. 检查 PawnCanUseWorkGiver()（能力、标签、跳过条件）
     b. 尝试 NonScanJob()（非扫描工作）
     c. 如果是 WorkGiver_Scanner：
        - scanThings: 搜索最近/最优先的 Thing
        - scanCells: 搜索最近/最优先的 Cell
     d. 找到目标后调用 JobOnThing/JobOnCell 创建 Job
5. 同优先级的 WorkGiver 会比较目标距离/优先级
```

### PawnCanUseWorkGiver 检查

```
- 非殖民者且工作不允许非殖民者 → false
- Pawn 的 WorkTag 被禁用 → false
- WorkType 被禁用 → false
- WorkGiver.ShouldSkip() 返回 true → false
- 缺少必需能力 → false
- 机械体且工作不允许机械体 → false
```

## WorkTypeDef

**命名空间**: `Verse`  
**文件**: `WorkTypeDef.cs`

工作**大类**定义，对应 UI 中的工作标签列。

关键字段：
- `naturalPriority: int` — 自然优先级（0-10000），决定同玩家优先级下的排序
- `relevantSkills: List<SkillDef>` — 关联技能
- `workGiversByPriority: List<WorkGiverDef>` — 此类下的所有具体工作（按 priorityInType 降序）
- `alwaysStartActive: bool` — 新 Pawn 是否默认启用
- `visible: bool` — UI 是否显示

示例：
| WorkType | naturalPriority | 示例 WorkGiver |
|----------|----------------|---------------|
| Firefighter | 很高 | 灭火 |
| Doctor | 高 | 救治、手术 |
| Construction | 中 | 建造、维修 |
| Hauling | 低 | 搬运物品 |

## WorkGiverDef

**命名空间**: `RimWorld`  
**文件**: `WorkGiverDef.cs`

具体工作的定义。

关键字段：
- `giverClass: Type` — WorkGiver 实现类
- `workType: WorkTypeDef` — 所属工作大类
- `priorityInType: int` — 在大类内的优先级
- `scanThings: bool` — 是否扫描 Thing（默认 true）
- `scanCells: bool` — 是否扫描 Cell
- `emergency: bool` — 是否为紧急工作
- `requiredCapacities` — 要求的身体能力
- `tagToGive: JobTag` — 产出 Job 的标签

## WorkGiver（抽象基类）

**文件**: `WorkGiver.cs`

最简单的工作提供者接口：
- `ShouldSkip(Pawn)` — 快速跳过检查
- `NonScanJob(Pawn)` — 不需要扫描目标的工作
- `MissingRequiredCapacity(Pawn)` — 能力检查

## WorkGiver_Scanner（抽象类）

**文件**: `WorkGiver_Scanner.cs`  
**继承**: `WorkGiver`

大多数工作使用此类，通过扫描场景中的 Thing 或 Cell 来找工作。

关键虚方法：
- `PotentialWorkThingsGlobal(Pawn)` — 候选 Thing 集合
- `PotentialWorkCellsGlobal(Pawn)` — 候选 Cell 集合
- `HasJobOnThing(Pawn, Thing)` — 是否能对此 Thing 工作
- `HasJobOnCell(Pawn, IntVec3)` — 是否能在此 Cell 工作
- `JobOnThing(Pawn, Thing)` → Job — 创建针对 Thing 的 Job
- `JobOnCell(Pawn, IntVec3)` → Job — 创建针对 Cell 的 Job
- `Prioritized: bool` — 是否有自定义优先级（否则按距离排序）
- `GetPriority(Pawn, TargetInfo)` — 自定义优先级值
- `MaxPathDanger(Pawn)` — 最大路径危险等级
- `AllowUnreachable: bool` — 是否允许不可达目标

### 目标搜索策略

**非优先级模式**（默认）：找**最近的**有效目标
```
scanThings → GenClosest.ClosestThingReachable()
scanCells  → 遍历 + 比较距离平方
```

**优先级模式**（Prioritized = true）：找**优先级最高**的目标（相同优先级取最近）
```
scanThings → GenClosest.ClosestThing_Global_Reachable() with priority
scanCells  → 遍历 + 比较 (priority, distance)
```
