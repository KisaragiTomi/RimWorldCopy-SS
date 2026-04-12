extends Node

const BIOME_DISEASES: Dictionary = {
	"TemperateForest": [
		{"disease": "Flu", "chance": 0.04},
		{"disease": "Plague", "chance": 0.01},
		{"disease": "GutWorms", "chance": 0.02}
	],
	"TropicalRainforest": [
		{"disease": "Malaria", "chance": 0.06},
		{"disease": "SleepingSickness", "chance": 0.04},
		{"disease": "GutWorms", "chance": 0.03},
		{"disease": "Plague", "chance": 0.02}
	],
	"AridShrubland": [
		{"disease": "Flu", "chance": 0.02},
		{"disease": "HeatStroke", "chance": 0.03}
	],
	"Desert": [
		{"disease": "HeatStroke", "chance": 0.05},
		{"disease": "Flu", "chance": 0.01}
	],
	"BorealForest": [
		{"disease": "Flu", "chance": 0.05},
		{"disease": "Hypothermia", "chance": 0.03},
		{"disease": "Frostbite", "chance": 0.02}
	],
	"Tundra": [
		{"disease": "Hypothermia", "chance": 0.06},
		{"disease": "Frostbite", "chance": 0.04},
		{"disease": "Flu", "chance": 0.03}
	],
	"IceSheet": [
		{"disease": "Hypothermia", "chance": 0.08},
		{"disease": "Frostbite", "chance": 0.06}
	],
	"Swamp": [
		{"disease": "Malaria", "chance": 0.05},
		{"disease": "GutWorms", "chance": 0.04},
		{"disease": "Plague", "chance": 0.02},
		{"disease": "WoundInfection", "chance": 0.03}
	],
	"Savanna": [
		{"disease": "SleepingSickness", "chance": 0.03},
		{"disease": "Flu", "chance": 0.02},
		{"disease": "GutWorms", "chance": 0.02}
	]
}

func get_disease_risks(biome: String) -> Array:
	return BIOME_DISEASES.get(biome, [])

func roll_disease(biome: String) -> String:
	var risks: Array = get_disease_risks(biome)
	for risk: Dictionary in risks:
		if randf() < risk["chance"]:
			return risk["disease"]
	return ""

func get_most_dangerous_biome() -> String:
	var best: String = ""
	var best_total: float = 0.0
	for biome: String in BIOME_DISEASES:
		var total: float = 0.0
		for entry: Dictionary in BIOME_DISEASES[biome]:
			total += float(entry.get("chance", 0.0))
		if total > best_total:
			best_total = total
			best = biome
	return best


func get_safest_biome() -> String:
	var best: String = ""
	var lowest: float = 999.0
	for biome: String in BIOME_DISEASES:
		var total: float = 0.0
		for entry: Dictionary in BIOME_DISEASES[biome]:
			total += float(entry.get("chance", 0.0))
		if total < lowest:
			lowest = total
			best = biome
	return best


func get_unique_diseases() -> Array[String]:
	var seen: Dictionary = {}
	for biome: String in BIOME_DISEASES:
		for entry: Dictionary in BIOME_DISEASES[biome]:
			seen[String(entry.get("disease", ""))] = true
	var result: Array[String] = []
	for d: String in seen:
		result.append(d)
	return result


func get_least_disease_biome() -> String:
	var best: String = ""
	var best_total: float = 999.0
	for biome: String in BIOME_DISEASES:
		var total: float = 0.0
		for d: Dictionary in BIOME_DISEASES[biome]:
			total += float(d.get("chance", 0.0))
		if total < best_total:
			best_total = total
			best = biome
	return best


func get_avg_diseases_per_biome() -> float:
	if BIOME_DISEASES.is_empty():
		return 0.0
	var total: int = 0
	for biome: String in BIOME_DISEASES:
		total += BIOME_DISEASES[biome].size()
	return float(total) / BIOME_DISEASES.size()


func get_most_widespread_disease() -> String:
	var counts: Dictionary = {}
	for biome: String in BIOME_DISEASES:
		for d: Dictionary in BIOME_DISEASES[biome]:
			var name: String = String(d.get("disease", ""))
			counts[name] = counts.get(name, 0) + 1
	var best: String = ""
	var best_count: int = 0
	for disease: String in counts:
		if int(counts[disease]) > best_count:
			best_count = int(counts[disease])
			best = disease
	return best


func get_exclusive_disease_count() -> int:
	var disease_biome_count: Dictionary = {}
	for biome: String in BIOME_DISEASES:
		for d: Dictionary in BIOME_DISEASES[biome]:
			var name: String = String(d.get("disease", ""))
			disease_biome_count[name] = int(disease_biome_count.get(name, 0)) + 1
	var count: int = 0
	for disease: String in disease_biome_count:
		if int(disease_biome_count[disease]) == 1:
			count += 1
	return count


func get_highest_single_chance() -> float:
	var best: float = 0.0
	for biome: String in BIOME_DISEASES:
		for d: Dictionary in BIOME_DISEASES[biome]:
			var c: float = float(d.get("chance", 0.0))
			if c > best:
				best = c
	return best


func get_biome_with_most_diseases() -> String:
	var best: String = ""
	var best_count: int = 0
	for biome: String in BIOME_DISEASES:
		var c: int = BIOME_DISEASES[biome].size()
		if c > best_count:
			best_count = c
			best = biome
	return best


func get_health_threat_level() -> String:
	var avg: float = get_avg_diseases_per_biome()
	if avg >= 4.0:
		return "Severe"
	if avg >= 2.5:
		return "Elevated"
	if avg >= 1.0:
		return "Moderate"
	return "Low"


func get_endemic_ratio_pct() -> float:
	var exclusive: int = get_exclusive_disease_count()
	var unique: int = get_unique_diseases().size()
	if unique == 0:
		return 0.0
	return snappedf(float(exclusive) / float(unique) * 100.0, 0.1)


func get_biome_safety_spread() -> String:
	var most: String = get_most_dangerous_biome()
	var least: String = get_least_disease_biome()
	if most == least:
		return "Uniform"
	var most_count: int = 0
	var least_count: int = 999
	for biome: String in BIOME_DISEASES:
		var c: int = BIOME_DISEASES[biome].size()
		if c > most_count:
			most_count = c
		if c < least_count:
			least_count = c
	var diff: int = most_count - least_count
	if diff >= 4:
		return "Extreme"
	if diff >= 2:
		return "Varied"
	return "Similar"


func get_summary() -> Dictionary:
	var total_diseases: int = 0
	for biome: String in BIOME_DISEASES:
		total_diseases += BIOME_DISEASES[biome].size()
	return {
		"biomes_covered": BIOME_DISEASES.size(),
		"total_disease_entries": total_diseases,
		"unique_diseases": get_unique_diseases().size(),
		"most_dangerous": get_most_dangerous_biome(),
		"safest": get_least_disease_biome(),
		"avg_per_biome": snapped(get_avg_diseases_per_biome(), 0.1),
		"most_widespread": get_most_widespread_disease(),
		"exclusive_diseases": get_exclusive_disease_count(),
		"highest_single_chance": get_highest_single_chance(),
		"most_diseases_biome": get_biome_with_most_diseases(),
		"health_threat_level": get_health_threat_level(),
		"endemic_ratio_pct": get_endemic_ratio_pct(),
		"biome_safety_spread": get_biome_safety_spread(),
		"disease_preparedness": get_disease_preparedness(),
		"epidemic_risk_index": get_epidemic_risk_index(),
		"medical_burden_forecast": get_medical_burden_forecast(),
		"disease_ecosystem_health": get_disease_ecosystem_health(),
		"epidemiological_governance": get_epidemiological_governance(),
		"public_health_maturity_index": get_public_health_maturity_index(),
	}

func get_disease_preparedness() -> String:
	var threat := get_health_threat_level()
	var exclusive := get_exclusive_disease_count()
	if threat in ["Low", "Minimal"] and exclusive <= 2:
		return "Well Prepared"
	elif threat in ["Moderate"]:
		return "Watchful"
	return "Vulnerable"

func get_epidemic_risk_index() -> float:
	var highest := get_highest_single_chance()
	var widespread := 0
	for disease: String in get_unique_diseases():
		var count := 0
		for biome: String in BIOME_DISEASES:
			for d: Dictionary in BIOME_DISEASES[biome]:
				if d.get("name", "") == disease:
					count += 1
		if count >= 3:
			widespread += 1
	return snapped(highest * (float(widespread) + 1.0), 0.01)

func get_medical_burden_forecast() -> String:
	var avg := get_avg_diseases_per_biome()
	if avg >= 4.0:
		return "Heavy"
	elif avg >= 2.0:
		return "Moderate"
	return "Light"

func get_disease_ecosystem_health() -> float:
	var preparedness := get_disease_preparedness()
	var p_val: float = 90.0 if preparedness == "Prepared" else (60.0 if preparedness == "Moderate" else 25.0)
	var risk := get_epidemic_risk_index()
	var burden := get_medical_burden_forecast()
	var b_val: float = 90.0 if burden == "Light" else (60.0 if burden == "Moderate" else 25.0)
	return snapped((p_val + (100.0 - minf(risk * 20.0, 100.0)) + b_val) / 3.0, 0.1)

func get_epidemiological_governance() -> String:
	var ecosystem := get_disease_ecosystem_health()
	var threat := get_health_threat_level()
	var t_val: float = 90.0 if threat in ["Low", "Minimal"] else (60.0 if threat == "Moderate" else 25.0)
	var combined := (ecosystem + t_val) / 2.0
	if combined >= 70.0:
		return "Controlled"
	elif combined >= 40.0:
		return "Monitored"
	elif BIOME_DISEASES.size() > 0:
		return "Vulnerable"
	return "Unknown"

func get_public_health_maturity_index() -> float:
	var safety_spread := get_biome_safety_spread()
	var sp_val: float = 90.0 if safety_spread == "Wide" else (60.0 if safety_spread == "Moderate" else 30.0)
	var endemic := get_endemic_ratio_pct()
	return snapped(((100.0 - endemic) + sp_val) / 2.0, 0.1)
