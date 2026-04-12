# Layer 1: AI 决策层 — ThinkTree

## 概述

ThinkTree 是 RimWorld 角色 AI 的核心决策机制。每个 Pawn 拥有一棵或多棵思考树，树的每个节点负责判断"现在该做什么"。思考树采用**深度优先、优先级排序**的遍历策略。

## 类关系

```
ThinkTreeDef
  └── thinkRoot: ThinkNode          ← 树根节点
        ├── ThinkNode_Priority      ← 按序尝试子节点，返回第一个有效结果
        ├── ThinkNode_Subtree       ← 引用另一棵 ThinkTree（复用）
        └── ThinkNode_JobGiver      ← 叶节点，调用 TryGiveJob() 产出 Job
              └── JobGiver_Work     ← 具体实现：遍历 WorkGiver 分配工作
```

## ThinkTreeDef

**命名空间**: `Verse`  
**文件**: `ThinkTreeDef.cs`

ThinkTree 的 XML 定义容器。每个 Pawn 种族有对应的 ThinkTree（如 `Humanlike_Main`）。

关键字段：
- `thinkRoot` — 根 ThinkNode
- `insertTag` — 允许 Mod 通过 tag 插入子树
- `insertPriority` — 插入优先级

初始化时（`ResolveReferences`）：
1. 递归解析所有子节点
2. 分配唯一 SaveKey（用于存档）
3. 建立 parent 引用链

## ThinkNode（抽象基类）

**命名空间**: `Verse.AI`  
**文件**: `ThinkNode.cs`

所有思考节点的基类。

关键成员：
- `subNodes: List<ThinkNode>` — 子节点列表
- `priority: float` — 节点优先级（-1 表示无优先级）
- `parent: ThinkNode` — 父节点引用
- `TryIssueJobPackage(Pawn, JobIssueParams) → ThinkResult` — **核心方法**，子类必须实现

`ThinkResult` 包含：
- `Job` — 要执行的任务
- `SourceNode` — 产出此 Job 的节点
- `Tag` — JobTag（用于分类）

## ThinkNode_Priority

**文件**: `ThinkNode_Priority.cs`

按顺序遍历子节点，**返回第一个有效结果**：

```csharp
for (int i = 0; i < subNodes.Count; i++)
{
    ThinkResult result = subNodes[i].TryIssueJobPackage(pawn, jobParams);
    if (result.IsValid)
        return result;
}
return ThinkResult.NoJob;
```

这是最常用的分支节点。思考树的根通常就是 `ThinkNode_Priority`，子节点按紧急程度排序（如：逃离危险 > 满足需求 > 工作 > 闲逛）。

## ThinkNode_Subtree

**文件**: `ThinkNode_Subtree.cs`

引用另一棵 ThinkTreeDef 作为子树。用于复用和模块化。

```csharp
protected override void ResolveSubnodes()
{
    subtreeNode = treeDef.thinkRoot.DeepCopy();
    subNodes.Add(subtreeNode);
}
```

注意它会**深拷贝**被引用的树，避免状态共享。

## ThinkNode_JobGiver（抽象类）

**文件**: `ThinkNode_JobGiver.cs`

思考树的**叶节点**，负责产出具体的 Job。

```csharp
protected abstract Job TryGiveJob(Pawn pawn);

public override ThinkResult TryIssueJobPackage(Pawn pawn, JobIssueParams jobParams)
{
    Job job = TryGiveJob(pawn);
    if (job == null) return ThinkResult.NoJob;
    return new ThinkResult(job, this);
}
```

所有具体的 Job 产出逻辑都通过继承此类实现。最重要的子类是 `JobGiver_Work`。

## 执行时机

Pawn 的 `Pawn_JobTracker` 在以下情况调用 ThinkTree：
1. **当前无 Job 时**（`TryFindAndStartJob`）
2. **定期检查中断**（`CheckForJobOverride`）
3. **常量思考树**每 30 tick 检查一次（`DetermineNextConstantThinkTreeJob`）
