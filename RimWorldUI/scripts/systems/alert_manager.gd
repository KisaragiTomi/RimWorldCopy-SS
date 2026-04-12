extends Node

## Monitors colony conditions and raises prioritized alerts.
## Registered as autoload "AlertManager".

signal alert_changed()

var active_alerts: Array[Dictionary] = []

const SEVERITY_ORDER: Dictionary = {"critical": 0, "danger": 1, "warning": 2, "info": 3}


func _ready() -> void:
	if TickManager:
		TickManager.rare_tick.connect(_on_rare_tick)


func _on_rare_tick(_tick: int) -> void:
	active_alerts.clear()
	_check_food()
	_check_medicine()
	_check_idle()
	_check_injured()
	_check_mental_break()
	_check_fire()
	_check_enemies()
	_check_temperature()
	_check_prisoners()
	_check_beds()
	_sort_alerts()
	alert_changed.emit()


func _add_alert(atype: String, severity: String, message: String) -> void:
	for a: Dictionary in active_alerts:
		if a.get("type", "") == atype:
			return
	active_alerts.append({"type": atype, "severity": severity, "message": message})


func _check_food() -> void:
	var total_food: int = 0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				var item := t as Item
				if item.state == Thing.ThingState.SPAWNED:
					if item.def_name in ["RawFood", "MealSimple", "MealFine", "Rice", "Corn", "Meat"]:
						total_food += item.stack_count

	var pawn_count: int = PawnManager.pawns.size() if PawnManager else 1
	if total_food < pawn_count * 3:
		_add_alert("StarvingFood", "critical", "Starvation imminent! (%d food)" % total_food)
	elif total_food < pawn_count * 10:
		_add_alert("LowFood", "warning", "Food supplies low (%d units)." % total_food)


func _check_medicine() -> void:
	var total_med: int = 0
	if ThingManager:
		for t: Thing in ThingManager.things:
			if t is Item:
				var item := t as Item
				if item.state == Thing.ThingState.SPAWNED:
					if item.def_name in ["Medicine", "HerbalMedicine"]:
						total_med += item.stack_count
	if total_med == 0:
		_add_alert("NoMedicine", "warning", "No medicine available!")


func _check_idle() -> void:
	if not PawnManager:
		return
	var idle_count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed or p.drafted:
			continue
		if p.current_job_name.is_empty() or p.current_job_name == "Wander":
			idle_count += 1
	if idle_count > 0:
		_add_alert("IdleColonists", "info", "%d colonist(s) idle." % idle_count)


func _check_injured() -> void:
	if not PawnManager:
		return
	var downed_names: PackedStringArray = []
	var bleeding_names: PackedStringArray = []
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if p.downed:
			downed_names.append(p.pawn_name)
		elif p.health and p.health.is_bleeding():
			bleeding_names.append(p.pawn_name)
	if downed_names.size() > 0:
		_add_alert("DownedColonist", "critical", "%s downed!" % ", ".join(downed_names))
	if bleeding_names.size() > 0:
		_add_alert("Bleeding", "danger", "%s bleeding!" % ", ".join(bleeding_names))


func _check_mental_break() -> void:
	if not PawnManager:
		return
	for p: Pawn in PawnManager.pawns:
		if p.dead or p.downed:
			continue
		if p.get_need("Mood") < 0.15:
			_add_alert("MentalBreakRisk", "warning", "%s near mental break!" % p.pawn_name)
			return


func _check_fire() -> void:
	if not FireManager:
		return
	var fire_count: int = FireManager.fires.size()
	if fire_count > 0:
		_add_alert("ActiveFire", "critical", "%d active fire(s)!" % fire_count)


func _check_enemies() -> void:
	var enemy_count: int = 0
	if PawnManager:
		for p: Pawn in PawnManager.pawns:
			if p.has_meta("faction") and p.get_meta("faction") == "enemy" and not p.dead:
				enemy_count += 1
	if enemy_count > 0:
		_add_alert("EnemiesPresent", "critical", "%d enemies on map!" % enemy_count)


func _check_temperature() -> void:
	if not GameState:
		return
	var temp: float = GameState.temperature
	if WeatherManager:
		temp += WeatherManager.get_temp_offset()
	if temp < -15.0:
		_add_alert("ExtremeCold", "danger", "Extreme cold: %.1f°C!" % temp)
	elif temp > 50.0:
		_add_alert("ExtremeHeat", "danger", "Extreme heat: %.1f°C!" % temp)


func _check_prisoners() -> void:
	if not PrisonerManager:
		return
	if PrisonerManager.prisoners.size() > 0:
		_add_alert("HasPrisoners", "info", "%d prisoner(s)." % PrisonerManager.prisoners.size())


func _check_beds() -> void:
	if not PawnManager or not ThingManager:
		return
	var bed_count: int = 0
	for t: Thing in ThingManager.things:
		if t is Building and t.def_name == "Bed":
			var b := t as Building
			if b.build_state == Building.BuildState.COMPLETE:
				bed_count += 1
	var colonist_count: int = 0
	for p: Pawn in PawnManager.pawns:
		if p.dead:
			continue
		if not p.has_meta("faction") or p.get_meta("faction") == "colony":
			colonist_count += 1
	if bed_count < colonist_count:
		_add_alert("NeedBeds", "warning", "Need %d more bed(s)." % (colonist_count - bed_count))


func _sort_alerts() -> void:
	active_alerts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = SEVERITY_ORDER.get(a.get("severity", "info"), 3)
		var sb: int = SEVERITY_ORDER.get(b.get("severity", "info"), 3)
		return sa < sb
	)


func get_danger_count() -> int:
	var count: int = 0
	for a: Dictionary in active_alerts:
		if a.get("severity", "") in ["critical", "danger"]:
			count += 1
	return count


func get_alerts_by_severity(severity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a: Dictionary in active_alerts:
		if a.get("severity", "") == severity:
			result.append(a)
	return result


func get_most_critical() -> Dictionary:
	for a: Dictionary in active_alerts:
		if a.get("severity", "") == "critical":
			return a
	for a: Dictionary in active_alerts:
		if a.get("severity", "") == "danger":
			return a
	if not active_alerts.is_empty():
		return active_alerts[0]
	return {}


func has_critical_alerts() -> bool:
	for a: Dictionary in active_alerts:
		if a.get("severity", "") == "critical":
			return true
	return false


func get_warning_count() -> int:
	var cnt: int = 0
	for a: Dictionary in active_alerts:
		if a.get("severity", "") == "warning":
			cnt += 1
	return cnt


func get_unique_alert_type_count() -> int:
	var types: Dictionary = {}
	for a: Dictionary in active_alerts:
		types[a.get("type", "")] = true
	return types.size()


func get_severity_breakdown() -> Dictionary:
	var counts: Dictionary = {"critical": 0, "danger": 0, "warning": 0, "info": 0}
	for a: Dictionary in active_alerts:
		var sev: String = a.get("severity", "info")
		counts[sev] = counts.get(sev, 0) + 1
	return counts


func get_critical_ratio() -> float:
	if active_alerts.is_empty():
		return 0.0
	var bd: Dictionary = get_severity_breakdown()
	return snappedf(float(bd.get("critical", 0)) / float(active_alerts.size()) * 100.0, 0.1)


func get_info_count() -> int:
	return get_severity_breakdown().get("info", 0)


func get_oldest_alert_type() -> String:
	if active_alerts.is_empty():
		return ""
	return active_alerts[0].get("type", "")


func get_alert_escalation_trend() -> String:
	if active_alerts.size() < 2:
		return "Stable"
	var recent_critical := 0
	var older_critical := 0
	var mid := active_alerts.size() / 2
	for i in range(mid, active_alerts.size()):
		if active_alerts[i].get("severity", "info") in ["critical", "danger"]:
			recent_critical += 1
	for i in range(0, mid):
		if active_alerts[i].get("severity", "info") in ["critical", "danger"]:
			older_critical += 1
	if recent_critical > older_critical + 1:
		return "Escalating"
	elif recent_critical < older_critical:
		return "De-escalating"
	return "Stable"

func get_response_priority() -> String:
	if has_critical_alerts():
		return "Immediate"
	if get_danger_count() > 0:
		return "High"
	if get_warning_count() > 0:
		return "Medium"
	return "Low"

func get_system_stress_pct() -> float:
	var bd: Dictionary = get_severity_breakdown()
	var critical := float(bd.get("critical", 0)) * 3.0
	var danger := float(bd.get("danger", 0)) * 2.0
	var warning := float(bd.get("warning", 0)) * 1.0
	var total_weight := critical + danger + warning
	var max_weight := float(active_alerts.size()) * 3.0
	if max_weight <= 0.0:
		return 0.0
	return snapped(total_weight / max_weight * 100.0, 0.1)

func get_summary() -> Dictionary:
	return {
		"count": active_alerts.size(),
		"danger_count": get_danger_count(),
		"alerts": active_alerts,
		"has_critical": has_critical_alerts(),
		"most_critical": get_most_critical().get("message", ""),
		"warning_count": get_warning_count(),
		"unique_types": get_unique_alert_type_count(),
		"severity_breakdown": get_severity_breakdown(),
		"critical_ratio_pct": get_critical_ratio(),
		"info_count": get_info_count(),
		"oldest_type": get_oldest_alert_type(),
		"escalation_trend": get_alert_escalation_trend(),
		"response_priority": get_response_priority(),
		"system_stress_pct": get_system_stress_pct(),
		"alert_fatigue_risk": get_alert_fatigue_risk(),
		"situational_awareness_score": get_situational_awareness_score(),
		"crisis_management_readiness": get_crisis_management_readiness(),
		"alert_ecosystem_health": get_alert_ecosystem_health(),
		"threat_governance": get_threat_governance(),
		"vigilance_maturity_index": get_vigilance_maturity_index(),
	}

func get_alert_fatigue_risk() -> String:
	var info := get_info_count()
	var total := active_alerts.size()
	if total <= 2:
		return "None"
	var noise_ratio := float(info) / float(total)
	if noise_ratio >= 0.7:
		return "High"
	elif noise_ratio >= 0.4:
		return "Moderate"
	return "Low"

func get_situational_awareness_score() -> float:
	var danger := get_danger_count()
	var total := active_alerts.size()
	if total <= 0:
		return 100.0
	return snapped((1.0 - float(danger) / float(total)) * 100.0, 0.1)

func get_crisis_management_readiness() -> String:
	var critical := has_critical_alerts()
	var stress := get_system_stress_pct()
	if not critical and stress < 30.0:
		return "Prepared"
	elif stress < 60.0:
		return "Alert"
	return "Overwhelmed"

func get_alert_ecosystem_health() -> float:
	var awareness := get_situational_awareness_score()
	var readiness := get_crisis_management_readiness()
	var r_val: float = 90.0 if readiness == "Prepared" else (60.0 if readiness == "Alert" else 30.0)
	var stress := get_system_stress_pct()
	return snapped((awareness + r_val + maxf(100.0 - stress, 0.0)) / 3.0, 0.1)

func get_threat_governance() -> String:
	var health := get_alert_ecosystem_health()
	var fatigue := get_alert_fatigue_risk()
	if health >= 65.0 and fatigue in ["None", "Low"]:
		return "Vigilant"
	elif health >= 35.0:
		return "Responsive"
	return "Overwhelmed"

func get_vigilance_maturity_index() -> float:
	var priority := get_response_priority()
	var p_val: float = 90.0 if priority in ["None", "Low"] else (50.0 if priority == "Medium" else 20.0)
	var trend := get_alert_escalation_trend()
	var t_val: float = 90.0 if trend in ["Decreasing", "Stable"] else (50.0 if trend == "Rising" else 20.0)
	return snapped((p_val + t_val) / 2.0, 0.1)
