# 完整调用流程图

## 主循环：从 Tick 到 Job 执行

```
GameTick
  │
  ▼
Pawn_JobTracker.JobTrackerTick()
  │
  ├── curDriver.DriverTick()          ← 有 Job 时：驱动 Toil
  │     │
  │     ├── CheckCurrentToilEndOrFail()
  │     ├── 根据 CompleteMode 判断完成
  │     ├── preTickActions → tickAction
  │     └── ReadyForNextToil() → TryActuallyStartNextToil()
  │           │
  │           ├── curToilIndex++
  │           ├── 无更多 Toil → EndJobWith(Succeeded)
  │           └── preInitActions → initAction
  │
  ▼
Pawn_JobTracker.JobTrackerTickInterval(delta)   ← 间隔 Tick
  │
  ├── [每30 Tick] DetermineNextConstantThinkTreeJob()  ← 紧急检查
  │     └── 有更高优先级 → StartJob(中断当前)
  │
  ├── [Job 过期检查]
  │     └── 过期 → EndCurrentJob / CheckForJobOverride
  │
  ├── curDriver.DriverTickInterval(delta)
  │
  └── [curJob == null]
        └── TryFindAndStartJob()
              │
              ▼
          DetermineNextJob()
              │
              ├── 1. ConstantThinkTree.TryIssueJobPackage()
              │
              └── 2. MainThinkTree.TryIssueJobPackage()
                    │
                    ▼
              ThinkNode_Priority.TryIssueJobPackage()
                    │
                    ├── [子节点按序尝试]
                    │   ├── 逃离危险
                    │   ├── 满足需求
                    │   ├── JobGiver_Work (emergency=true)  ──┐
                    │   ├── 娱乐/休息                         │
                    │   ├── JobGiver_Work (emergency=false) ──┤
                    │   └── 闲逛                               │
                    │                                          │
                    ▼                                          ▼
```

## JobGiver_Work 内部流程

```
JobGiver_Work.TryIssueJobPackage(pawn)
  │
  ├── [紧急模式 + 玩家指定优先工作]
  │     └── GiverTryGiveJobPrioritized(指定WorkGiver, 指定Cell)
  │           └── 找到 → return ThinkResult(job, playerForced=true)
  │
  ├── 获取 WorkGiver 列表
  │     ├── emergency=true  → WorkGiversInOrderEmergency
  │     └── emergency=false → WorkGiversInOrderNormal
  │
  └── for each WorkGiver in list:
        │
        ├── PawnCanUseWorkGiver() 检查
        │     ├── 非殖民者限制
        │     ├── WorkTag 禁用
        │     ├── WorkType 禁用
        │     ├── ShouldSkip()
        │     ├── MissingRequiredCapacity()
        │     └── 机械体限制
        │
        ├── NonScanJob(pawn) → 有 Job → return
        │
        └── [WorkGiver_Scanner]
              │
              ├── scanThings:
              │     ├── PotentialWorkThingsGlobal()
              │     ├── [Prioritized]
              │     │     └── ClosestThing_Global_Reachable(优先级+距离)
              │     └── [非 Prioritized]
              │           └── ClosestThingReachable(仅距离)
              │     └── Validator: !IsForbidden && HasJobOnThing
              │
              ├── scanCells:
              │     ├── PotentialWorkCellsGlobal()
              │     └── for each Cell:
              │           └── !IsForbidden && HasJobOnCell && CanReach
              │
              └── bestTarget 找到:
                    ├── JobOnThing(pawn, thing) 或 JobOnCell(pawn, cell)
                    └── return ThinkResult(job)
```

## Job 启动流程

```
StartJob(newJob, condition, ...)
  │
  ├── 安全检查（10 jobs/tick 限制）
  │
  ├── 处理旧 Job:
  │     ├── suspendable → SuspendCurrentJob（入队，不释放资源）
  │     └── 否则 → CleanupCurrentJob（释放资源、执行 finishActions）
  │
  ├── curJob = newJob
  ├── curDriver = curJob.MakeDriver(pawn)
  │
  ├── TryMakePreToilReservations()  ← 预留目标资源
  │     └── 失败 → EndCurrentJob(Errored)
  │
  ├── TryOpportunisticJob()         ← 尝试顺路搬运
  │     └── 有机会 → 将 newJob 入队，先执行搬运
  │
  ├── 处理携带物品
  ├── SetInitialPosture()
  ├── Notify_Starting()
  ├── SetupToils()                  ← 调用 MakeNewToils()
  └── ReadyForNextToil()            ← 开始第一个 Toil
```

## Job 结束与过渡

```
EndCurrentJob(condition)
  │
  ├── CleanupCurrentJob()
  │     ├── Lord.Notify_PawnJobDone()
  │     ├── TaleRecorder（成功时）
  │     ├── 释放资源预留
  │     ├── curDriver.Cleanup() → finishActions
  │     └── curJob = null
  │
  └── 决定下一步:
        ├── Errored → Wait(250)
        ├── Succeeded + 不在移动 → Wait_MaintainPosture(1)
        └── 其他 → TryFindAndStartJob() ← 回到主循环
```

## 关键数据流

```
[玩家 UI]
    │ SetPriority(WorkType, 1-4)
    ▼
Pawn_WorkSettings
    │ CacheWorkGiversInOrder()
    ▼
WorkGiver 排序列表
    │ 被 JobGiver_Work 读取
    ▼
JobGiver_Work
    │ 遍历 → 找到工作 → 创建 Job
    ▼
Pawn_JobTracker.StartJob()
    │ 创建 JobDriver → SetupToils
    ▼
JobDriver.DriverTick()
    │ 逐 Toil 执行
    ▼
[Pawn 在世界中行动]
```
