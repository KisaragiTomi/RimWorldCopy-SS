class_name JobDriverWarden
extends JobDriver

## Drives the Warden job: walk to prisoner cell, attempt recruitment.


func _make_toils() -> Array[Dictionary]:
	return [
		{
			"name": "chatting",
			"complete_mode": "delay",
			"delay_ticks": 200,
		},
		{
			"name": "done",
			"complete_mode": "instant",
		},
	]


func _on_toil_init(toil_name: String) -> void:
	match toil_name:
		"done":
			_finish_warden()


func _finish_warden() -> void:
	var prisoner_id: int = job.meta_data.get("prisoner_id", -1)
	if prisoner_id < 0:
		return
	var recruited: bool = false
	if PrisonerManager:
		for p: Pawn in PrisonerManager.prisoners:
			if p.id == prisoner_id:
				recruited = PrisonerManager.attempt_recruit(p, pawn)
				if not recruited and p.get_need("Food") < 0.3:
					_feed_prisoner(p)
				break
	var skill: int = pawn.get_skill("Social") if pawn else 0
	pawn.gain_xp("Social", 30.0 + skill * 1.5)


func _feed_prisoner(p: Pawn) -> void:
	if not ThingManager:
		return
	for t: Thing in ThingManager.things:
		if t is Item and t.def_name in ["MealSimple", "Meal", "MealFine", "RawFood"]:
			var item := t as Item
			if item.state == Thing.ThingState.SPAWNED and item.stack_count >= 1:
				item.stack_count -= 1
				if item.stack_count <= 0:
					ThingManager.remove_thing(t)
				p.set_need("Food", minf(1.0, p.get_need("Food") + 0.3))
				if ColonyLog:
					ColonyLog.add_entry("Prisoner", "%s fed prisoner %s." % [pawn.pawn_name, p.pawn_name], "info")
				return
