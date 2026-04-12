# Layer 4: 玩家设置层 — Pawn_WorkSettings

## 概述

`Pawn_WorkSettings` 管理玩家为每个 Pawn 设定的工作优先级。这直接决定了 `JobGiver_Work` 遍历 WorkGiver 的顺序。

**命名空间**: `RimWorld`  
**文件**: `Pawn_WorkSettings.cs`

## 优先级系统

| 优先级值 | 含义 |
|---------|------|
| 0 | 禁用（不做此工作） |
| 1 | 最高优先级 |
| 2 | 高优先级 |
| 3 | 默认优先级 |
| 4 | 最低优先级 |

如果玩家未开启手动优先级（`useWorkPriorities = false`），所有启用的工作统一视为优先级 3。

## WorkGiver 排序算法

`CacheWorkGiversInOrder()` 是排序的核心：

### 排序公式

```
排序值 = naturalPriority + (4 - playerPriority) × 100000
```

- `playerPriority` 权重远大于 `naturalPriority`
- 玩家设 1 的工作永远排在设 2 之前，不管 naturalPriority 多大
- 相同玩家优先级内，按 `naturalPriority` 排序

### 紧急/常规分离

排序后分为两个列表：

**Emergency 列表**（`workGiversInOrderEmerg`）：
- `WorkGiverDef.emergency == true`
- 且该 WorkType 的玩家优先级 ≤ 所有非紧急 WorkType 中的最低优先级
- 仅当紧急工作优先级足够高时才进入此列表

**Normal 列表**（`workGiversInOrderNormal`）：
- 非紧急的 WorkGiver
- 或紧急但优先级不够高的 WorkGiver（降级为普通）

## 初始化逻辑

`EnableAndInitialize()` 新 Pawn 首次设置：

```
1. 所有工作设为 0（禁用）
2. 非 alwaysStartActive 的工作：
   - 按 Pawn 技能水平降序排列
   - 取前 6 个启用，优先级设 3
3. alwaysStartActive 的工作：
   - 全部启用，优先级设 3
4. 机械体：使用 mechWorkTypePriorities 特殊配置
5. 禁用 Pawn 无法执行的工作（背景故事/健康限制）
```

## 脏标记机制

每次修改优先级后：
- `workGiversDirty = true`
- 下次 `JobGiver_Work` 获取列表时触发 `CacheWorkGiversInOrder()` 重新排序
- 优先级设 0 时通知 `Pawn_JobTracker.Notify_WorkTypeDisabled()` 中断相关 Job

## 与 UI 的关系

工作标签页 UI：
- 列数 = WorkTypeDef 列表（`visible = true` 且 `VisibleCurrently` = true）
- 行数 = 殖民者列表
- 每格显示优先级数字（1-4）或勾选/禁用
- 修改时调用 `SetPriority(WorkTypeDef, int)`
