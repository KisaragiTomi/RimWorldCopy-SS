class_name ColonistData

static func get_mood_color(mood: float) -> Color:
	if mood >= 0.75:
		return RWTheme.MOOD_HAPPY
	elif mood >= 0.55:
		return RWTheme.MOOD_CONTENT
	elif mood >= 0.35:
		return RWTheme.MOOD_NEUTRAL
	elif mood >= 0.15:
		return RWTheme.MOOD_SAD
	else:
		return RWTheme.MOOD_BROKEN


static func get_mood_label(mood: float) -> String:
	if mood >= 0.75:
		return "Happy"
	elif mood >= 0.55:
		return "Content"
	elif mood >= 0.35:
		return "Neutral"
	elif mood >= 0.15:
		return "Sad"
	else:
		return "Broken"


static func get_skill_level_label(level: int) -> String:
	if level >= 18:
		return "Legendary"
	elif level >= 14:
		return "Master"
	elif level >= 10:
		return "Skilled"
	elif level >= 6:
		return "Adequate"
	elif level >= 2:
		return "Poor"
	else:
		return "Incapable"
