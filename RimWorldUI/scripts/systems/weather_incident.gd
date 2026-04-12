extends Node

var _active_incidents: Array = []

const WEATHER_INCIDENTS: Dictionary = {
	"LightningStrike": {"weather_trigger": "Thunderstorm", "chance": 0.15, "damage": 30, "fire_chance": 0.6, "desc": "Lightning hits a random outdoor tile"},
	"HeavyFrost": {"weather_trigger": "ColdSnap", "chance": 0.3, "crop_kill_pct": 0.4, "desc": "Frost kills exposed crops"},
	"Drought": {"weather_trigger": "HeatWave", "chance": 0.2, "growth_penalty": 0.5, "duration_days": 5, "desc": "Crops grow slower"},
	"Hailstorm": {"weather_trigger": "Thunderstorm", "chance": 0.08, "damage": 15, "radius": 5, "desc": "Hail damages outdoor items"},
	"FlashFlood": {"weather_trigger": "Rain", "chance": 0.05, "move_penalty": 0.4, "duration_hours": 8, "desc": "Low areas flood temporarily"},
	"ToxicBuildup": {"weather_trigger": "ToxicFallout", "chance": 0.4, "severity_rate": 0.02, "desc": "Outdoor pawns gain toxic buildup"},
	"Tornado": {"weather_trigger": "Thunderstorm", "chance": 0.02, "damage": 80, "path_length": 15, "desc": "Destroys buildings in path"},
	"FogOfWar": {"weather_trigger": "Fog", "chance": 0.5, "sight_reduction": 0.5, "desc": "Reduces weapon accuracy"},
	"Avalanche": {"weather_trigger": "ColdSnap", "chance": 0.05, "damage": 50, "blocked_tiles": 10, "desc": "Mountain tiles collapse"},
	"Sunstroke": {"weather_trigger": "HeatWave", "chance": 0.25, "severity_rate": 0.03, "desc": "Outdoor pawns risk heatstroke"}
}

func check_weather_incident(current_weather: String) -> Dictionary:
	for inc_name: String in WEATHER_INCIDENTS:
		var inc: Dictionary = WEATHER_INCIDENTS[inc_name]
		if inc["weather_trigger"] == current_weather:
			if randf() < inc["chance"]:
				_active_incidents.append({"type": inc_name, "tick": 0})
				return {"triggered": true, "incident": inc_name, "details": inc}
	return {"triggered": false}

func get_incidents_for_weather(weather: String) -> Array[String]:
	var result: Array[String] = []
	for inc_name: String in WEATHER_INCIDENTS:
		if String(WEATHER_INCIDENTS[inc_name].get("weather_trigger", "")) == weather:
			result.append(inc_name)
	return result


func get_most_damaging_incident() -> String:
	var best: String = ""
	var best_dmg: int = 0
	for inc_name: String in WEATHER_INCIDENTS:
		var d: int = int(WEATHER_INCIDENTS[inc_name].get("damage", 0))
		if d > best_dmg:
			best_dmg = d
			best = inc_name
	return best


func get_incident_history_count() -> int:
	return _active_incidents.size()


func get_avg_damage() -> float:
	var total: float = 0.0
	var n: int = 0
	for inc: String in WEATHER_INCIDENTS:
		if WEATHER_INCIDENTS[inc].has("damage"):
			total += float(WEATHER_INCIDENTS[inc]["damage"])
			n += 1
	return total / maxf(n, 1)


func get_unique_triggers() -> int:
	var triggers: Dictionary = {}
	for inc: String in WEATHER_INCIDENTS:
		triggers[String(WEATHER_INCIDENTS[inc].get("weather_trigger", ""))] = true
	return triggers.size()


func get_high_chance_incident_count(threshold: float = 0.2) -> int:
	var count: int = 0
	for inc: String in WEATHER_INCIDENTS:
		if float(WEATHER_INCIDENTS[inc].get("chance", 0.0)) >= threshold:
			count += 1
	return count


func get_fire_risk_incidents() -> int:
	var count: int = 0
	for inc: String in WEATHER_INCIDENTS:
		if float(WEATHER_INCIDENTS[inc].get("fire_chance", 0.0)) > 0.0:
			count += 1
	return count


func get_avg_chance() -> float:
	if WEATHER_INCIDENTS.is_empty():
		return 0.0
	var total: float = 0.0
	for inc: String in WEATHER_INCIDENTS:
		total += float(WEATHER_INCIDENTS[inc].get("chance", 0.0))
	return snappedf(total / float(WEATHER_INCIDENTS.size()), 0.01)


func get_crop_affecting_incidents() -> int:
	var count: int = 0
	for inc: String in WEATHER_INCIDENTS:
		if WEATHER_INCIDENTS[inc].has("crop_kill_pct") or WEATHER_INCIDENTS[inc].has("growth_penalty"):
			count += 1
	return count


func get_disaster_readiness() -> String:
	var active: int = _active_incidents.size()
	if active >= 3:
		return "Overwhelmed"
	elif active >= 2:
		return "Strained"
	elif active >= 1:
		return "Alert"
	return "Clear"

func get_hazard_density_pct() -> float:
	if WEATHER_INCIDENTS.is_empty():
		return 0.0
	return snappedf(float(get_high_chance_incident_count()) / float(WEATHER_INCIDENTS.size()) * 100.0, 0.1)

func get_agricultural_threat() -> String:
	var crop: int = get_crop_affecting_incidents()
	var fire: int = get_fire_risk_incidents()
	if crop + fire >= 4:
		return "Severe"
	elif crop + fire >= 2:
		return "Moderate"
	elif crop + fire >= 1:
		return "Minor"
	return "None"

func get_summary() -> Dictionary:
	return {
		"incident_types": WEATHER_INCIDENTS.size(),
		"active_incidents": _active_incidents.size(),
		"most_damaging": get_most_damaging_incident(),
		"avg_damage": snapped(get_avg_damage(), 0.1),
		"unique_triggers": get_unique_triggers(),
		"high_chance_count": get_high_chance_incident_count(),
		"fire_risk": get_fire_risk_incidents(),
		"avg_chance": get_avg_chance(),
		"crop_affecting": get_crop_affecting_incidents(),
		"disaster_readiness": get_disaster_readiness(),
		"hazard_density_pct": get_hazard_density_pct(),
		"agricultural_threat": get_agricultural_threat(),
		"weather_resilience": get_weather_resilience(),
		"seasonal_risk_profile": get_seasonal_risk_profile(),
		"infrastructure_vulnerability": get_infrastructure_vulnerability(),
		"climate_ecosystem_health": get_climate_ecosystem_health(),
		"weather_governance": get_weather_governance(),
		"environmental_resilience_index": get_environmental_resilience_index(),
	}

func get_weather_resilience() -> String:
	var readiness := get_disaster_readiness()
	var fire := get_fire_risk_incidents()
	if readiness in ["Prepared", "Fortified"] and fire <= 1:
		return "Hardened"
	elif readiness in ["Aware", "Prepared"]:
		return "Moderate"
	return "Exposed"

func get_seasonal_risk_profile() -> float:
	var high := get_high_chance_incident_count()
	var total := WEATHER_INCIDENTS.size()
	if total <= 0:
		return 0.0
	return snapped(float(high) / float(total) * 100.0, 0.1)

func get_infrastructure_vulnerability() -> String:
	var avg_dmg := get_avg_damage()
	if avg_dmg >= 50.0:
		return "Critical"
	elif avg_dmg >= 20.0:
		return "Moderate"
	return "Low"

func get_climate_ecosystem_health() -> float:
	var resilience := get_weather_resilience()
	var r_val: float = 90.0 if resilience == "Hardened" else (60.0 if resilience == "Moderate" else 25.0)
	var readiness := get_disaster_readiness()
	var rd_val: float = 90.0 if readiness == "Prepared" else (60.0 if readiness == "Aware" else 25.0)
	var risk := get_seasonal_risk_profile()
	return snapped((r_val + rd_val + (100.0 - risk)) / 3.0, 0.1)

func get_weather_governance() -> String:
	var ecosystem := get_climate_ecosystem_health()
	var vulnerability := get_infrastructure_vulnerability()
	var v_val: float = 90.0 if vulnerability == "Low" else (50.0 if vulnerability == "Moderate" else 10.0)
	var combined := (ecosystem + v_val) / 2.0
	if combined >= 70.0:
		return "Climate Adapted"
	elif combined >= 40.0:
		return "Weather Aware"
	elif _active_incidents.size() > 0:
		return "Vulnerable"
	return "Calm"

func get_environmental_resilience_index() -> float:
	var threat := get_agricultural_threat()
	var t_val: float = 90.0 if threat == "Minimal" else (60.0 if threat == "Moderate" else 20.0)
	var hazard := get_hazard_density_pct()
	return snapped((t_val + (100.0 - hazard)) / 2.0, 0.1)
