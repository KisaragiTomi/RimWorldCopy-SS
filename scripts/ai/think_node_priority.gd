class_name ThinkNodePriority
extends ThinkNode

## Tries child nodes in order. Returns the first valid result.

func try_issue_job(pawn: Pawn) -> Dictionary:
	for node: ThinkNode in sub_nodes:
		var result := node.try_issue_job(pawn)
		if not result.is_empty():
			return result
	return {}
