class_name ThinkNode
extends RefCounted

## Base class for AI think tree nodes.
## Returns a ThinkResult (job + source node) or null.

var sub_nodes: Array[ThinkNode] = []
var priority: float = -1.0
var parent: ThinkNode


func try_issue_job(pawn: Pawn) -> Dictionary:
	return {}


func add_child_node(node: ThinkNode) -> void:
	node.parent = self
	sub_nodes.append(node)
