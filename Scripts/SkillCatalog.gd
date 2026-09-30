extends RefCounted

# Each skill consumes one matching die. Ranges are measured from the caster.
const SKILLS := {
	"Brilia": {"name": "Royal Cleave", "dice": [1, 2], "front": 1, "behind": 1, "cooldown": 2, "effect": "damage", "damage": 2, "targets": 16, "selection": "all", "team": "enemy", "magical": false},
	"Suki": {"name": "Weakspot Arrow", "dice": [3, 4], "front": 2, "behind": 2, "cooldown": 2, "effect": "damage", "damage": 2, "targets": 1, "selection": "lowest", "team": "enemy", "magical": false},
	"Mordian": {"name": "Iron Bulwark", "dice": [1, 2], "front": 0, "behind": 0, "cooldown": 1, "effect": "shield", "targets": 1, "team": "self"},
	"Anata": {"name": "Guardian's Blessing", "dice": [6], "front": 6, "behind": 6, "cooldown": 1, "effect": "shield", "targets": 1, "selection": "random", "team": "ally"},
	"Kaelgrave": {"name": "Gravebreaker", "dice": [2, 4], "front": 4, "behind": 0, "cooldown": 2, "effect": "stun", "duration": 1, "targets": 2, "selection": "nearest", "team": "enemy"},
	"Nyssara": {"name": "Phantom Ambush", "dice": [2, 4], "front": 0, "behind": 0, "cooldown": 2, "effect": "ambush", "targets": 1, "team": "self"},
	"Vilmira": {"name": "Blood Curse", "dice": [6], "front": 3, "behind": 3, "cooldown": 3, "effect": "bleed", "duration": 2, "targets": 1, "selection": "nearest", "team": "enemy"},
	"Zyrella": {"name": "Witch's Dash", "dice": [1, 2], "front": 0, "behind": 0, "cooldown": 1, "effect": "move", "distance": 3, "targets": 1, "team": "self"},
	"Silvy": {"name": "Briar Volley", "dice": [2, 3], "front": 4, "behind": 0, "cooldown": 2, "effect": "damage", "damage": 1, "targets": 3, "selection": "nearest", "team": "enemy", "magical": false},
	"Garruk": {"name": "Thornhide", "dice": [2, 3], "front": 0, "behind": 0, "cooldown": 1, "effect": "thornhide", "duration": 2, "targets": 1, "team": "self"},
	"Pirunrun": {"name": "Fairy Sparks", "dice": [2, 3], "front": 4, "behind": 4, "cooldown": 2, "effect": "damage", "damage": 2, "targets": 2, "selection": "random", "team": "enemy", "magical": true},
	"Mycellia": {"name": "Sporeguard", "dice": [4, 5], "front": 5, "behind": 5, "cooldown": 3, "effect": "nature", "duration": 4, "targets": 1, "selection": "nearest", "team": "ally"},
	"Skalfin": {"name": "Twin Tides", "dice": [2, 3], "front": 2, "behind": 2, "cooldown": 1, "effect": "damage", "damage": 1, "hits": 2, "bonus_chance": 0.5, "targets": 1, "selection": "nearest", "team": "enemy", "magical": false},
	"Octavus": {"name": "Tidal Barrage", "dice": [6], "front": 4, "behind": 4, "cooldown": 3, "effect": "damage", "damage": 2, "targets": 4, "selection": "random", "team": "enemy", "magical": true},
	"Velissa": {"name": "Drowning Hex", "dice": [2, 3], "front": 3, "behind": 3, "cooldown": 2, "effect": "drown", "duration": 3, "targets": 1, "selection": "random", "team": "enemy"},
	"Kragor": {"name": "Reef Shortcut", "dice": [4, 5], "front": 0, "behind": 0, "cooldown": 3, "effect": "shortcut", "distance": 4, "targets": 1, "team": "self"},
}

static func get_skill(hero_id: String) -> Dictionary:
	return SKILLS.get(hero_id, {})
