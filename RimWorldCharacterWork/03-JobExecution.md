# Layer 3: 任务执行层 — Job Execution

## 概述

一旦工作分配层产出了一个 Job，任务执行层负责：
1. 管理 Job 的生命周期（启动、中断、完成、排队）
2. 将 Job 分解为 Toil 序列
3. 每 Tick 驱动 Toil 执行

## 类关系

```
Pawn_JobTracker           ← Pawn 的 Job 管理器
  ├── curJob: Job         ← 当前正在执行的 Job
  ├── curDriver: JobDriver ← 当前 Job 的执行器
  ├── jobQueue: JobQueue   ← 排队中的 Job
  └── 调用 ThinkTree 获取新 Job

Job (数据对象)
  ├── def: JobDef          ← 类型定义
  ├── targetA/B/C          ← 最多 3 个目标
  └── 各种参数

JobDriver (执行器)
  ├── MakeNewToils() → List<Toil>  ← 定义执行步骤
  ├── DriverTick()                  ← 每 Tick 驱动
  └── toils: List<Toil>            ← 步骤序列

Toil (单步操作)
  ├── initAction         ← 开始时执行
  ├── tickAction         ← 每 Tick 执行
  ├── endConditions      ← 结束条件
  ├── finishActions      ← 完成时执行
  └── defaultCompleteMode ← 完成模式
```

## JobDef

**命名空间**: `Verse`  
**文件**: `JobDef.cs`

Job 类型的 XML 定义。

关键字段：
| 字段 | 类型 | 默认值 | 含义 |
|------|------|--------|------|
| `driverClass` | Type | — | JobDriver 实现类 |
| `reportString` | string | "Doing something." | UI 显示文本 |
| `playerInterruptible` | bool | true | 玩家能否中断 |
| `suspendable` | bool | true | 能否暂停（被更高优先级中断后恢复） |
| `casualInterruptible` | bool | true | 能否被休闲中断 |
| `allowOpportunisticPrefix` | bool | false | 允许顺路搬运 |
| `collideWithPawns` | bool | false | 移动时碰撞 Pawn |
| `isIdle` | bool | false | 是否为空闲任务 |
| `checkOverrideOnDamage` | enum | Always | 受伤时是否重新评估 |

## Pawn_JobTracker

**命名空间**: `Verse.AI`  
**文件**: `Pawn_JobTracker.cs`

Pawn 的 Job 管理器，是整个系统的**调度中心**。

### 关键方法

#### JobTrackerTick() — 每 Tick 调用
```
curDriver?.DriverTick()     ← 驱动当前 Job
```

#### JobTrackerTickInterval(delta) — 间隔 Tick
```
1. 每 30 Tick 检查 ConstantThinkTree（高优先级中断）
2. 检查 Job 过期（expiryInterval）
3. 调用 curDriver.DriverTickInterval(delta)
4. 如果 curJob == null → TryFindAndStartJob()
```

#### TryFindAndStartJob()
```
1. 调用 DetermineNextJob()
   a. 先查 ConstantThinkTree（紧急事件）
   b. 再查 MainThinkTree（常规决策）
2. 得到 ThinkResult → StartJob()
```

#### StartJob() — 启动新 Job
参数极多（13个），核心流程：
```
1. 安全检查（每 Tick 不超过 10 个 Job）
2. 如果有 curJob：
   - suspendable → 暂停并入队
   - 否则 → CleanupCurrentJob
3. 设置 curJob = newJob
4. 创建 curDriver = curJob.MakeDriver(pawn)
5. TryMakePreToilReservations()（预留资源）
6. 尝试顺路搬运（TryOpportunisticJob）
7. SetupToils() → ReadyForNextToil()
```

#### EndCurrentJob(condition)
```
1. CleanupCurrentJob（释放资源、通知 Lord）
2. 根据 condition 决定下一步：
   - Errored → Wait 250 tick
   - Succeeded → Wait_MaintainPosture 1 tick（保持姿势过渡）
   - 其他 → TryFindAndStartJob()
```

### 顺路搬运机制（Opportunistic Hauling）

`TryOpportunisticJob()` 在 Pawn 前往工作地点的路上，检查是否有顺路可搬运的物品：

条件：
- Pawn 未被征召、未倒地、非精神崩溃
- Job 允许 `allowOpportunisticPrefix`
- 目标距离 > 3 格
- 物品距 Pawn < 30 格且 < 目标距离的 50%
- 搬运后总路径 < 直接路径的 1.7 倍

## JobDriver（抽象类）

**命名空间**: `Verse.AI`  
**文件**: `JobDriver.cs`

Job 的执行引擎。每个 JobDef 对应一个 JobDriver 子类。

### 核心抽象方法

```csharp
protected abstract IEnumerable<Toil> MakeNewToils();  // 定义执行步骤
public abstract bool TryMakePreToilReservations(bool errorOnFailed);  // 预留资源
```

### Toil 执行引擎：DriverTick()

每 Tick 调用一次，驱动当前 Toil：

```
1. 如果 CurToil == null：
   - 不在忙碌姿态 → ReadyForNextToil()
2. 检查全局/Toil 失败条件
3. 根据 CompleteMode 决定是否完成：
   - Instant → 立即完成，进入下一个 Toil
   - Delay → ticksLeftThisToil 倒计时
   - PatherArrival → 到达目的地时完成
   - FinishedBusy → 忙碌姿态结束时完成
4. 执行 preTickActions → tickAction
```

### Toil 跳转

```csharp
ReadyForNextToil()  // 进入下一个 Toil（顺序）
JumpToToil(toil)    // 跳转到指定 Toil（循环/分支）
EndJobWith(cond)    // 结束整个 Job
```

### 目标访问器

JobDriver 提供便捷属性访问 Job 的 3 个目标：
- `TargetA/B/C` — LocalTargetInfo
- `TargetThingA/B/C` — Thing
- `TargetPawnA/B/C` — Pawn

## Toil

**命名空间**: `Verse.AI`  
**文件**: `Toil.cs`

Job 的**最小执行单元**。一个 Job 由多个 Toil 按序组成。

### 关键字段

| 字段 | 类型 | 含义 |
|------|------|------|
| `initAction` | Action | Toil 开始时执行一次 |
| `tickAction` | Action | 每 Tick 执行 |
| `endConditions` | List<Func<JobCondition>> | 结束条件列表 |
| `finishActions` | List<Action> | Toil 结束时执行 |
| `preInitActions` | List<Action> | initAction 之前执行 |
| `preTickActions` | List<Action> | tickAction 之前执行 |
| `defaultCompleteMode` | ToilCompleteMode | 完成模式 |
| `defaultDuration` | int | Delay 模式的持续 Tick |
| `atomicWithPrevious` | bool | 与前一个 Toil 原子性（可在忙碌时启动） |
| `activeSkill` | Func<SkillDef> | 此 Toil 使用的技能（影响经验） |
| `socialMode` | RandomSocialMode | 社交模式 |

### ToilCompleteMode

| 模式 | 完成条件 |
|------|---------|
| `Instant` | 立即完成（同 Tick 进入下一个 Toil） |
| `Delay` | `defaultDuration` Tick 后完成 |
| `PatherArrival` | Pawn 到达路径终点时完成 |
| `FinishedBusy` | Pawn 不再处于忙碌姿态时完成 |

### 典型 Toil 序列示例

以建造为例（概念性）：
```
Toil 1: 走向建造位置   (PatherArrival)
Toil 2: 面向建造物     (Instant)
Toil 3: 执行建造工作   (Delay, 有 tickAction 递增工作量)
Toil 4: 完成建造       (Instant)
```
