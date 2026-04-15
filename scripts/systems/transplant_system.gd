extends Node

var _harvested_organs: Array[Dictionary] = []

const ORGANS: Dictionary = {
	"Heart": {"vital": true, "market_value": 500, "surgery_skill": 8, "failure_chance": 0.05},
	"Lung": {"vital": false, "market_value": 400, "surgery_skill": 6, "failure_chance": 0.04, "max_harvest": 1},
	"Kidney": {"vital": false, "market_value": 350, "surgery_skill": 6, "failure_chance": 0.04, "max_harvest": 1},
	"Liver": {"vital": false, "market_value": 450, "surgery_skill": 7, "failure_chance": 0.05},
	"Stomach": {"vital": false, "market_value": 300, "surgery_skill": 6, "failure_chance": 0.04},
	"Eye": {"vital": false, "market_value": 250, "surgery_skill": 5, "failure_chance": 0.03, "max_harvest": 2},
	"Ear": {"vital": false, "market_value": 200, "surgery_skill": 4, "failure_chance": 0.02, "max_harvest": 2},
	"Jaw": {"vital": false, "market_value": 350, "surgery_skill": 6, "failure_chance": 0.04},
	"Nose": {"vital": false, "market_value": 180, "surgery_skill": 4, "failure_chance": 0.02}
}

const BIONICS: Dictionary = {
	"BionicHeart": {"replaces": "Heart", "efficiency": 1.25, "cost": 1200},
	"BionicEye": {"replaces": "Eye", "efficiency": 1.5, "cost": 900},
	"BionicArm": {"replaces": "Arm", "efficiency": 1.25, "cost": 800},
	"BionicLeg": {"replaces": "Leg", "efficiency": 1.25, "cost": 800},
	"BionicEar": {"replaces": "Ear", "efficiency": 1.4, "cost": 700},
	"BionicJaw": {"replaces": "Jaw", "efficiency": 1.2, "cost": 600},
	"ArchotechEye": {"replaces": "Eye", "efficiency": 2.5, "cost": 3500},
	"ArchotechArm": {"replaces": "Arm", "efficiency": 2.0, "cost": 3000}
}

const COMPATIBILITY: Dictionary = {
	"blood_type_match": 0.3,
	"species_match": 0.5,
	"rejection_base_chance": 0.15
}

func harvest_organ(organ: String, donor_id: String, doctor_skill: int) -> Dictionary:
	if not ORGANS.has(organ):
		return {"error": "unknown_organ"}
	var info: Dictionary = ORGANS[organ]
	var success_chance: float = 1.0 - info["failure_chance"] * (maxf(1, info["surgery_skill"] - doctor_skill) * 0.1 + 1.0)
	var succeeded: bool = randf() < success_chance
	if succeeded:
		_harvested_organs.append({"organ": organ, "donor": donor_id, "quality": minf(1.0, doctor_skill / 10.0)})
	return {"organ": organ, "success": succeeded, "lethal": info.get("vital", false) and succeeded}

func install_organ(organ: String, recipient_id: String, doctor_skill: int) -> Dictionary:
	if not ORGANS.has(organ):
		return {"error": "unknown_organ"}
	var rejection_chance: float = COMPATIBILITY["rejection_base_chance"] * maxf(0.5, 1.0 - doctor_skill * 0.05)
	var rejected: bool = randf() < rejection_chance
	return {"organ": organ, "recipient": recipient_id, "rejected": rejected}

func get_most_valuable_organ() -> String:
	var best: String = ""
	var best_val: int = 0
	for o: String in ORGANS:
		if ORGANS[o]["market_value"] > best_val:
			best_val = ORGANS[o]["market_value"]
			best = o
	return best

func get_best_bionic(part: String) -> String:
	var best: String = ""
	var best_eff: float = 0.0
	for b: String in BIONICS:
		if BIONICS[b]["replaces"] == part and BIONICS[b]["efficiency"] > best_eff:
			best_eff = BIONICS[b]["efficiency"]
			best = b
	return best

func get_total_harvest_value() -> int:
	var total: int = 0
	for h: Dictionary in _harvested_organs:
		total += ORGANS.get(h["organ"], {}).get("market_value", 0)
	return total

func get_avg_organ_value() -> float:
	if ORGANS.is_empty():
		return 0.0
	var total: float = 0.0
	for o: String in ORGANS:
		total += float(ORGANS[o].get("value", 0))
	return total / ORGANS.size()


func get_most_valuable_bionic() -> String:
	var best: String = ""
	var best_val: float = 0.0
	for b: String in BIONICS:
		var v: float = float(BIONICS[b].get("value", 0))
		if v > best_val:
			best_val = v
			best = b
	return best


func get_vital_organ_count() -> int:
	var count: int = 0
	for o: String in ORGANS:
		if bool(ORGANS[o].get("vital", false)):
			count += 1
	return count


func get_medical_sophistication() -> String:
	var archotech: int = 0
	for b: String in BIONICS:
		if b.begins_with("Archotech"):
			archotech += 1
	var ratio: float = archotech * 1.0 / maxf(BIONICS.size(), 1.0)
	if ratio >= 0.3:
		return "cutting_edge"
	if ratio >= 0.1:
		return "advanced"
	return "standard"

func get_surgical_risk_pct() -> float:
	var high_risk: int = 0
	for o: String in ORGANS:
		if ORGANS[o]["failure_chance"] >= 0.05:
			high_risk += 1
	if ORGANS.is_empty():
		return 0.0
	return snapped(high_risk * 100.0 / ORGANS.size(), 0.1)

func get_enhancement_coverage() -> String:
	var covered_parts: Dictionary = {}
	for b: String in BIONICS:
		covered_parts[BIONICS[b]["replaces"]] = true
	var ratio: float = covered_parts.size() * 1.0 / maxf(ORGANS.size(), 1.0)
	if ratio >= 0.7:
		return "comprehensive"
	if ratio >= 0.4:
		return "partial"
	return "limited"

func get_summary() -> Dictionary:
	return {
		"organ_types": ORGANS.size(),
		"bionic_types": BIONICS.size(),
		"harvested": _harvested_organs.size(),
		"most_valuable_organ": get_most_valuable_organ(),
		"total_harvest_value": get_total_harvest_value(),
		"avg_organ_value": snapped(get_avg_organ_value(), 0.1),
		"best_bionic": get_most_valuable_bionic(),
		"vital_organs": get_vital_organ_count(),
		"medical_sophistication": get_medical_sophistication(),
		"surgical_risk_pct": get_surgical_risk_pct(),
		"enhancement_coverage": get_enhancement_coverage(),
	}
