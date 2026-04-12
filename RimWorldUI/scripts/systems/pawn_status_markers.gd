extends Node

## Tracks visual status markers for pawns: drafted, hurt, hungry, sleepy,
## mental break, inspired, etc. Used by rendering to show icons/colors.
## Registered as autoload "PawnStatusMarkers".

enum Marker { DRAFTED, DOWNED, HURT, HUNGRY, EXHAUSTED, MENTAL_BREAK, INSPIRED, IDLE, SICK, BLEEDING, HYPOTHERMIC, OVERHEATED }

const MARKER_COLORS: Dictionary = {
	0: Color(0.2, 0.5, 1.0),   # DRAFTED - blue
	1: Color(1.0, 0.3, 0.3),   # DOWNED - red
	2: Color(1.0, 0.6, 0.2),   # HURT - orange
	3: Color(0.8, 0.7, 0.1),   # HUNGRY - yellow
	4: Color(0.5, 0.4, 0.8),   # EXHAUSTED - purple
	5: Color(1.0, 0.1, 0.1),   # MENTAL_BREAK - bright red
	6: Color(1.0, 0.9, 0.3),   # INSPIRED - gold
	7: Color(0.5, 0.5, 0.5),   # IDLE - gray
	8: Color(0.3, 0.8, 0.3),   # SICK - green
	9: Color(0.9, 0.1, 0.2),   # BLEEDING - deep red
	10: Color(0.4, 0.7, 1.0),  # HYPOTHERMIC - icy blue
	11: Color(1.0, 0.4, 0.0),  # OVERHEATED - hot orange
}

const MARKER_PRIORITY: Dictionary = {
	5: 0, 1: 1, 9: 2, 2: 3, 8: 4, 3: 5, 4: 6,
	10: 7, 11: 8, 0: 9, 6: 10, 7: 11,
}

const MARKER_LABELS: PackedStringArray = [
	"Drafted", "Downed", "Hurt", "Hungry", "Exhausted",
	"Mental Break", "Inspired", "Idle", "Sick",
	"Bleeding", "Hypothermic", "Overheated",
]


func get_markers(pawn: Pawn) -> Array[int]:
	var markers: Array[int] = []

	if pawn.drafted:
		markers.append(Marker.DRAFTED)
	if pawn.downed:
		markers.append(Marker.DOWNED)
	if pawn.health and pawn.health.hediffs.size() > 0:
		var has_injury := false
		var has_disease := false
		for h: Dictionary in pawn.health.hediffs:
			if h.get("type", "") == "Injury":
				has_injury = true
			elif h.get("type", "") == "Disease":
				has_disease = true
		if has_injury:
			markers.append(Marker.HURT)
		if has_disease:
			markers.append(Marker.SICK)
	if pawn.get_need("Food") < 0.2:
		markers.append(Marker.HUNGRY)
	if pawn.get_need("Rest") < 0.2:
		markers.append(Marker.EXHAUSTED)
	if pawn.is_in_mental_break():
		markers.append(Marker.MENTAL_BREAK)
	if InspirationManager and InspirationManager.is_inspired(pawn.id):
		markers.append(Marker.INSPIRED)
	if IdleDetector and IdleDetector.is_idle(pawn.id):
		markers.append(Marker.IDLE)
	if pawn.health and pawn.health.has_method("get_bleed_rate") and pawn.health.get_bleed_rate() > 0.0:
		markers.append(Marker.BLEEDING)
	if pawn.has_meta("hypothermic") and pawn.get_meta("hypothermic"):
		markers.append(Marker.HYPOTHERMIC)
	if pawn.has_meta("overheated") and pawn.get_meta("overheated"):
		markers.append(Marker.OVERHEATED)

	return markers


func get_primary_marker(pawn: Pawn) -> int:
	var markers := get_markers(pawn)
	if markers.is_empty():
		return -1
	var best_m: int = markers[0]
	var best_p: int = MARKER_PRIORITY.get(best_m, 99)
	for m: int in markers:
		var p: int = MARKER_PRIORITY.get(m, 99)
		if p < best_p:
			best_p = p
			best_m = m
	return best_m


func get_marker_color(marker: int) -> Color:
	return MARKER_COLORS.get(marker, Color.WHITE)


func get_marker_label(marker: int) -> String:
	if marker >= 0 and marker < MARKER_LABELS.size():
		return MARKER_LABELS[marker]
	return ""


func get_all_pawn_statuses() -> Array[Dictionary]:
	if not PawnManager:
		return []
	var result: Array[Dictionary] = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var markers := get_markers(p)
		var labels: PackedStringArray = []
		for m: int in markers:
			labels.append(get_marker_label(m))
		result.append({
			"pawn_id": p.id,
			"pawn_name": p.pawn_name,
			"markers": labels,
		})
	return result


func get_marker_counts() -> Dictionary:
	var counts: Dictionary = {}
	var statuses := get_all_pawn_statuses()
	for s: Dictionary in statuses:
		for label: String in s.markers:
			counts[label] = counts.get(label, 0) + 1
	return counts


func get_pawns_with_marker(marker: int) -> Array[int]:
	var result: Array[int] = []
	if not PawnManager:
		return result
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var markers := get_markers(p)
		if marker in markers:
			result.append(p.id)
	return result


func get_critical_count() -> int:
	var count: int = 0
	if not PawnManager:
		return 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		var markers := get_markers(p)
		for m: int in markers:
			if m in [Marker.DOWNED, Marker.MENTAL_BREAK, Marker.BLEEDING]:
				count += 1
				break
	return count


func get_most_common_marker() -> String:
	var counts := get_marker_counts()
	var best: String = ""
	var best_n: int = 0
	for label: String in counts:
		if counts[label] > best_n:
			best_n = counts[label]
			best = label
	return best


func get_healthy_pawn_count() -> int:
	if not PawnManager:
		return 0
	var count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if get_markers(p).is_empty():
			count += 1
	return count


func get_total_marker_count() -> int:
	var total: int = 0
	var counts := get_marker_counts()
	for label: String in counts:
		total += counts[label]
	return total


func get_health_rating() -> String:
	var crit: int = get_critical_count()
	if crit == 0:
		return "Healthy"
	elif crit <= 1:
		return "Stable"
	elif crit <= 3:
		return "Concerning"
	return "Critical"

func get_affliction_rate() -> float:
	var all: Array[Dictionary] = get_all_pawn_statuses()
	if all.is_empty():
		return 0.0
	var affected: int = 0
	for entry: Dictionary in all:
		if not entry.get("markers", []).is_empty():
			affected += 1
	return snappedf(float(affected) / float(all.size()) * 100.0, 0.1)

func get_marker_diversity() -> int:
	return get_marker_counts().size()

func get_colony_wellness() -> String:
	var healthy := get_healthy_pawn_count()
	var total := get_all_pawn_statuses().size()
	if total <= 0:
		return "N/A"
	var ratio := float(healthy) / float(total)
	if ratio >= 0.8:
		return "Healthy"
	elif ratio >= 0.5:
		return "Mixed"
	return "Ailing"

func get_medical_attention_load() -> float:
	var critical := get_critical_count()
	var total := get_all_pawn_statuses().size()
	if total <= 0:
		return 0.0
	return snapped(float(critical) / float(total) * 100.0, 0.1)

func get_condition_trend() -> String:
	var affliction := get_affliction_rate()
	if affliction < 20.0:
		return "Improving"
	elif affliction < 50.0:
		return "Stable"
	return "Worsening"

func get_summary() -> Dictionary:
	return {
		"pawn_statuses": get_all_pawn_statuses(),
		"marker_counts": get_marker_counts(),
		"critical_count": get_critical_count(),
		"most_common": get_most_common_marker(),
		"healthy_pawns": get_healthy_pawn_count(),
		"total_markers": get_total_marker_count(),
		"unique_marker_types": get_marker_counts().size(),
		"markers_per_pawn": snappedf(float(get_total_marker_count()) / maxf(float(get_all_pawn_statuses().size()), 1.0), 0.1),
		"health_rating": get_health_rating(),
		"affliction_rate_pct": get_affliction_rate(),
		"marker_diversity": get_marker_diversity(),
		"colony_wellness": get_colony_wellness(),
		"medical_attention_load_pct": get_medical_attention_load(),
		"condition_trend": get_condition_trend(),
		"health_governance_index": get_health_governance_index(),
		"morbidity_trajectory": get_morbidity_trajectory(),
		"population_vitality": get_population_vitality(),
	}

func get_health_governance_index() -> float:
	var wellness := get_colony_wellness()
	var load := get_medical_attention_load()
	var base: float = 100.0 - load
	if wellness == "Healthy":
		base *= 1.2
	elif wellness == "Ailing":
		base *= 0.6
	return snapped(clampf(base, 0.0, 100.0), 0.1)

func get_morbidity_trajectory() -> String:
	var trend := get_condition_trend()
	var affliction := get_affliction_rate()
	if trend == "Improving" and affliction < 30.0:
		return "Declining Risk"
	elif trend == "Worsening" or affliction >= 60.0:
		return "Rising Concern"
	return "Stable Outlook"

func get_population_vitality() -> float:
	var healthy := float(get_healthy_pawn_count())
	var total := float(get_all_pawn_statuses().size())
	if total <= 0.0:
		return 0.0
	var critical := float(get_critical_count())
	return snapped((healthy - critical * 2.0) / total * 100.0, 0.1)
