# RimWorld 角色工作系统

基于反编译源码整理的 RimWorld 角色工作/任务系统完整架构。

## 系统总览

角色工作系统分为 **4 个层级**，从上到下依次为：

```
┌─────────────────────────────────────────────┐
│          Layer 1: AI 决策层 (ThinkTree)       │
│  ThinkTreeDef → ThinkNode_Priority           │
│  → ThinkNode_Subtree → ThinkNode_JobGiver    │
├─────────────────────────────────────────────┤
│       Layer 2: 工作分配层 (Work Assignment)    │
│  JobGiver_Work → WorkTypeDef → WorkGiverDef  │
│  → WorkGiver / WorkGiver_Scanner             │
├─────────────────────────────────────────────┤
│        Layer 3: 任务执行层 (Job Execution)     │
│  Pawn_JobTracker → Job → JobDriver → Toil    │
├─────────────────────────────────────────────┤
│        Layer 4: 设置层 (Player Settings)       │
│  Pawn_WorkSettings (优先级 1-4)               │
└─────────────────────────────────────────────┘
```

## 核心流程（一句话版）

**每 Tick**：`Pawn_JobTracker` 检查当前是否有 Job → 没有则调用 ThinkTree 的 `TryIssueJobPackage` → ThinkTree 按优先级遍历子节点 → `JobGiver_Work` 根据玩家设定的工作优先级遍历 `WorkGiver` 列表 → 找到可做的工作后创建 `Job` → `JobDriver` 将 Job 分解为 `Toil` 序列逐步执行。

## 文件索引

| 文件 | 类 | 层级 | 简述 |
|------|-----|------|------|
| [01-ThinkTree.md](01-ThinkTree.md) | ThinkTreeDef, ThinkNode, ThinkNode_Priority, ThinkNode_Subtree, ThinkNode_JobGiver | L1 | AI 思考树结构与遍历 |
| [02-WorkAssignment.md](02-WorkAssignment.md) | JobGiver_Work, WorkTypeDef, WorkGiverDef, WorkGiver, WorkGiver_Scanner | L2 | 工作发现与分配 |
| [03-JobExecution.md](03-JobExecution.md) | JobDef, Job, JobDriver, Toil, Pawn_JobTracker | L3 | 任务执行与生命周期 |
| [04-WorkSettings.md](04-WorkSettings.md) | Pawn_WorkSettings | L4 | 玩家优先级设置 |
| [05-FlowChart.md](05-FlowChart.md) | — | — | 完整调用流程图 |

## 对应源码文件

```
decompiled/
├── ThinkTreeDef.cs          # 思考树定义
├── ThinkNode.cs             # 思考节点基类
├── ThinkNode_Priority.cs    # 优先级节点（按序尝试子节点）
├── ThinkNode_Subtree.cs     # 子树引用节点
├── ThinkNode_JobGiver.cs    # 末端节点（产出 Job）
├── JobGiver_Work.cs         # 核心：遍历 WorkGiver 分配工作
├── WorkTypeDef.cs           # 工作大类定义（建造、挖掘、烹饪…）
├── WorkGiverDef.cs          # 具体工作定义
├── WorkGiver.cs             # 工作提供者基类
├── WorkGiver_Scanner.cs     # 扫描式工作提供者
├── JobDef.cs                # Job 类型定义
├── JobDriver.cs             # Job 执行驱动器
├── Toil.cs                  # 单步操作
├── Pawn_JobTracker.cs       # Pawn 的 Job 管理器
└── Pawn_WorkSettings.cs     # 工作优先级设置
```
