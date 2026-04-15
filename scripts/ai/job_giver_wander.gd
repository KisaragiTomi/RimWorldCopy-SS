class_name JobGiverWander
extends ThinkNode

## Fallback behavior: wander to a random nearby passable cell.

var _rng := RandomNumberGenerator.new()

func try_issue_job(pawn: Pawn) -> Dictionary:
	var map: MapData = _get_map()
	if map == null:
		return {}

	var attempts: int = 10
	for _i: int in attempts:
		var dx: int = _rng.randi_range(-4, 4)
		var dy: int = _rng.randi_range(-4, 4)
		var target := Vector2i(pawn.grid_pos.x + dx, pawn.grid_pos.y + dy)
		if not map.in_bounds(target.x, target.y):
			continue
		var cell := map.get_cell_v(target)
		if cell and cell.is_passable():
			var j := Job.new("Wander", target)
			return {"job": j, "source": self}
	return {}


func _get_map() -> MapData:
	if GameState and GameState.has_method("get_map"):
		return GameState.get_map()
	return null
