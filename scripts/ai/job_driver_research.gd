class_name JobDriverResearch
extends JobDriver

## Drives the Research job: work at research bench for a period.
## Speed scales with Intellectual skill; higher skill = more XP.

const BASE_TICKS: int = 500
const BASE_XP: float = 50.0


func _make_toils() -> Array[Dictionary]:
	var ticks := _calc_research_ticks()
	return [
		{
			"name": "researching",
			"complete_mode": "delay",
			"delay_ticks": ticks,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"researching":
			_init_research()
		"done":
			_finish_research()


func _on_toil_tick(toil_name: String) -> void:
	match toil_name:
		"researching":
			_tick_research()


func _calc_research_ticks() -> int:
	var skill: int = pawn.get_skill("Intellectual") if pawn else 0
	var factor: float = clampf(1.0 - skill * 0.04, 0.3, 1.0)
	return roundi(BASE_TICKS * factor)


func _init_research() -> void:
	pass


func _tick_research() -> void:
	if ResearchManager and ResearchManager.current_project.is_empty():
		_advance_toil()


func _finish_research() -> void:
	var skill: int = pawn.get_skill("Intellectual") if pawn else 0
	var xp: float = BASE_XP + skill * 2.0
	pawn.gain_xp("Intellectual", xp)
	if ColonyLog and ResearchManager:
		var proj: String = ResearchManager.current_project
		if not proj.is_empty():
			var pct: float = ResearchManager.get_progress_pct(proj) if ResearchManager.has_method("get_progress_pct") else 0.0
			ColonyLog.add_entry("Research", "%s contributed to %s (%.0f%%)." % [pawn.pawn_name, proj, pct * 100.0], "info")
