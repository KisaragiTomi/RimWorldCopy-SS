extends Node

## Handles gradual skill decay for unused skills.
## Registered as autoload "SkillDecayManager".

const DECAY_RATE := 0.5
const MIN_DECAY_LEVEL := 5
const ACTIVE_SKILL_PROTECTION_TICKS := 5000

var _skill_last_used: Dictionary = {}  # pawn_id -> {skill_name: last_tick}


func _ready() -> void:
	if TickManager:
		TickManager.long_tick.connect(_on_long_tick)


func record_skill_use(pawn_id: int, skill_name: String) -> void:
	if not _skill_last_used.has(pawn_id):
		_skill_last_used[pawn_id] = {}
	_skill_last_used[pawn_id][skill_name] = TickManager.current_tick if TickManager else 0


func _on_long_tick(_tick: int) -> void:
	if not PawnManager:
		return
	var current_tick: int = TickManager.current_tick if TickManager else 0

	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		_decay_pawn_skills(p, current_tick)


func _decay_pawn_skills(pawn: Pawn, current_tick: int) -> void:
	var used: Dictionary = _skill_last_used.get(pawn.id, {})

	for skill_name: String in pawn.skills:
		var s: Dictionary = pawn.skills[skill_name]
		var level: int = s.get("level", 0)
		if level < MIN_DECAY_LEVEL:
			continue

		var last_used: int = used.get(skill_name, 0)
		if current_tick - last_used < ACTIVE_SKILL_PROTECTION_TICKS:
			continue

		var passion: int = s.get("passion", 0)
		if passion >= 2:
			continue

		var decay_amount: float = DECAY_RATE
		if passion == 1:
			decay_amount *= 0.5

		s["xp"] = s.get("xp", 0.0) - decay_amount
		if s["xp"] < 0.0:
			s["xp"] = Pawn.xp_for_level(level - 1) - 1.0
			s["level"] = level - 1


func get_summary() -> Dictionary:
	return {
		"tracked_pawns": _skill_last_used.size(),
		"min_decay_level": MIN_DECAY_LEVEL,
		"decay_rate": DECAY_RATE,
	}
