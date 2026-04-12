class_name NameGenerator
extends RefCounted

## Generates random pawn names in a RimWorld style.

const FIRST_NAMES_MALE: Array = [
	"Adam", "Blake", "Cole", "Dane", "Eli", "Finn", "Gray",
	"Hawk", "Ivan", "Jake", "Kai", "Leon", "Max", "Nash",
	"Owen", "Pike", "Quinn", "Reed", "Sam", "Troy",
	"Vance", "Wade", "Zane", "Ash", "Brock", "Cruz",
	"Dex", "Flint", "Grant", "Heath", "Jett", "Knox",
]

const FIRST_NAMES_FEMALE: Array = [
	"Aria", "Belle", "Cora", "Dawn", "Eve", "Faye", "Grace",
	"Hope", "Iris", "Jade", "Kira", "Luna", "Maya", "Nova",
	"Opal", "Pip", "Quinn", "Rose", "Sky", "Tara",
	"Uma", "Vera", "Wren", "Xena", "Yara", "Zara",
	"Ember", "Ivy", "Lyra", "Sage", "Raven", "Willow",
]

const LAST_NAMES: Array = [
	"Stone", "Ward", "Hunt", "Cross", "Black", "Grey",
	"Steel", "Frost", "Vale", "Drake", "Cole", "Vex",
	"Marsh", "Wolfe", "Fox", "Hart", "Raven", "Storm",
	"Reed", "Shaw", "Price", "Gold", "Silver", "Flint",
	"Ash", "Thorn", "Crane", "Ridge", "Brook", "Wynn",
]

const NICKNAMES: Array = [
	"Doc", "Hawk", "Engie", "Ace", "Shadow", "Scout",
	"Tank", "Patch", "Chef", "Spark", "Slim", "Flash",
	"Bear", "Rook", "Sage", "Lucky", "Razor", "Ghost",
	"Blaze", "Frost", "Copper", "Maverick", "Viper", "Phoenix",
]


static func generate_name(rng: RandomNumberGenerator, gender: String = "Male") -> Dictionary:
	var first: String
	if gender == "Female":
		first = FIRST_NAMES_FEMALE[rng.randi_range(0, FIRST_NAMES_FEMALE.size() - 1)]
	else:
		first = FIRST_NAMES_MALE[rng.randi_range(0, FIRST_NAMES_MALE.size() - 1)]

	var last: String = LAST_NAMES[rng.randi_range(0, LAST_NAMES.size() - 1)]
	var nick: String = ""

	if rng.randf() < 0.6:
		nick = NICKNAMES[rng.randi_range(0, NICKNAMES.size() - 1)]

	return {
		"first": first,
		"last": last,
		"nickname": nick,
		"full": first + " '" + nick + "' " + last if not nick.is_empty() else first + " " + last,
		"short": nick if not nick.is_empty() else first,
	}
