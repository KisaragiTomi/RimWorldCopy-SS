extends Node

## Quality levels for items and buildings. Affects market value, effectiveness.
## Registered as autoload "QualitySystem".

enum Quality { AWFUL, POOR, NORMAL, GOOD, EXCELLENT, MASTERWORK, LEGENDARY }

const QUALITY_LABELS: Dictionary = {
	Quality.AWFUL: "Awful",
	Quality.POOR: "Poor",
	Quality.NORMAL: "Normal",
	Quality.GOOD: "Good",
	Quality.EXCELLENT: "Excellent",
	Quality.MASTERWORK: "Masterwork",
	Quality.LEGENDARY: "Legendary",
}

const QUALITY_VALUE_MULTIPLIER: Dictionary = {
	Quality.AWFUL: 0.5,
	Quality.POOR: 0.75,
	Quality.NORMAL: 1.0,
	Quality.GOOD: 1.25,
	Quality.EXCELLENT: 1.5,
	Quality.MASTERWORK: 2.5,
	Quality.LEGENDARY: 5.0,
}

const QUALITY_EFFECTIVENESS: Dictionary = {
	Quality.AWFUL: 0.7,
	Quality.POOR: 0.85,
	Quality.NORMAL: 1.0,
	Quality.GOOD: 1.1,
	Quality.EXCELLENT: 1.25,
	Quality.MASTERWORK: 1.5,
	Quality.LEGENDARY: 2.0,
}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = randi()


func roll_quality(crafter_skill: int) -> int:
	var roll: float = _rng.randf()
	var skill_bonus: float = crafter_skill * 0.02

	if roll < 0.02 + skill_bonus * 0.5:
		return Quality.LEGENDARY if roll < 0.002 + skill_bonus * 0.05 else Quality.MASTERWORK
	elif roll < 0.10 + skill_bonus:
		return Quality.EXCELLENT
	elif roll < 0.30 + skill_bonus:
		return Quality.GOOD
	elif roll < 0.70:
		return Quality.NORMAL
	elif roll < 0.90 - skill_bonus * 0.5:
		return Quality.POOR
	else:
		return Quality.AWFUL


func get_label(quality: int) -> String:
	return QUALITY_LABELS.get(quality, "Normal")


func get_value_multiplier(quality: int) -> float:
	return QUALITY_VALUE_MULTIPLIER.get(quality, 1.0)


func get_effectiveness(quality: int) -> float:
	return QUALITY_EFFECTIVENESS.get(quality, 1.0)


func get_min_skill_for(quality: int) -> int:
	match quality:
		Quality.LEGENDARY:
			return 18
		Quality.MASTERWORK:
			return 14
		Quality.EXCELLENT:
			return 10
		Quality.GOOD:
			return 6
		_:
			return 0


func quality_from_label(label: String) -> int:
	for q: int in QUALITY_LABELS:
		if QUALITY_LABELS[q] == label:
			return q
	return Quality.NORMAL


func compare_quality(a: int, b: int) -> int:
	if a > b:
		return 1
	elif a < b:
		return -1
	return 0


func get_avg_value_multiplier() -> float:
	if QUALITY_VALUE_MULTIPLIER.is_empty():
		return 1.0
	var total: float = 0.0
	for q: int in QUALITY_VALUE_MULTIPLIER:
		total += QUALITY_VALUE_MULTIPLIER[q]
	return total / float(QUALITY_VALUE_MULTIPLIER.size())


func get_quality_above(threshold: int) -> int:
	var cnt: int = 0
	for q: int in QUALITY_LABELS:
		if q >= threshold:
			cnt += 1
	return cnt


func get_multiplier_range() -> float:
	var lo: float = 999.0
	var hi: float = 0.0
	for q: int in QUALITY_VALUE_MULTIPLIER:
		var v: float = QUALITY_VALUE_MULTIPLIER[q]
		if v < lo:
			lo = v
		if v > hi:
			hi = v
	return snappedf(hi - lo, 0.01)


func get_below_normal_count() -> int:
	var cnt: int = 0
	for q: int in QUALITY_LABELS:
		if q < Quality.NORMAL:
			cnt += 1
	return cnt


func get_quality_tier_count() -> int:
	return QUALITY_LABELS.size()


func get_craftsmanship_index() -> float:
	var avg := get_avg_value_multiplier()
	var above_good := float(get_quality_above(Quality.GOOD))
	var total := float(get_quality_tier_count())
	if total <= 0.0:
		return 0.0
	return snapped((avg * 30.0 + above_good / total * 70.0), 0.1)

func get_quality_distribution() -> String:
	var above := get_quality_above(Quality.GOOD)
	var below := get_below_normal_count()
	var total := get_quality_tier_count()
	if total <= 0:
		return "Empty"
	if above > total / 2:
		return "Premium"
	elif below > total / 2:
		return "Low-End"
	return "Mixed"

func get_excellence_rate_pct() -> float:
	var total := get_quality_tier_count()
	if total <= 0:
		return 0.0
	var excellent := get_quality_above(Quality.EXCELLENT)
	return snapped(float(excellent) / float(total) * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"quality_levels": QUALITY_LABELS.size(),
		"max_multiplier": QUALITY_VALUE_MULTIPLIER.get(Quality.LEGENDARY, 5.0),
		"avg_multiplier": snappedf(get_avg_value_multiplier(), 0.01),
		"above_good": get_quality_above(Quality.GOOD),
		"multiplier_range": get_multiplier_range(),
		"below_normal": get_below_normal_count(),
		"total_tiers": get_quality_tier_count(),
		"craftsmanship_index": get_craftsmanship_index(),
		"quality_distribution": get_quality_distribution(),
		"excellence_rate_pct": get_excellence_rate_pct(),
		"artisanal_legacy_score": get_artisanal_legacy_score(),
		"quality_consistency": get_quality_consistency(),
		"crafting_excellence_index": get_crafting_excellence_index(),
	}

func get_artisanal_legacy_score() -> float:
	var avg_mult: float = get_avg_value_multiplier()
	var above_good: int = get_quality_above(Quality.GOOD)
	var score: float = avg_mult * 20.0 + float(above_good) * 5.0
	return snappedf(clampf(score, 0.0, 100.0), 0.1)

func get_quality_consistency() -> String:
	var spread: float = get_multiplier_range()
	if spread <= 1.0:
		return "Very Consistent"
	if spread <= 2.0:
		return "Consistent"
	if spread <= 3.5:
		return "Variable"
	return "Erratic"

func get_crafting_excellence_index() -> float:
	var excellence: float = get_excellence_rate_pct()
	var below: int = get_below_normal_count()
	var tiers: int = get_quality_tier_count()
	var penalty: float = float(below) * 5.0
	var score: float = excellence * 0.6 + float(tiers) * 5.0 - penalty
	return snappedf(clampf(score, 0.0, 100.0), 0.1)
