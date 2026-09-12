extends RefCounted

const NAMES := ["Bloodfang Blade", "Heart of Gaia", "Windrunner Boots", "Voidcaller Staff", "Ironwall Aegis", "Mystic Veil"]
const EFFECTS := ["Damage +1", "Max Health +1", "Move +1", "Skill Damage +1", "Physical Shield +1", "Magical Shield +1"]

static func texture(id: int) -> Texture2D:
	return load("res://Arts/Textures_Game/Items/%s.png" % NAMES[id])

static func choices() -> Array[int]:
	var pool: Array[int] = [0, 1, 2, 3, 4, 5]
	pool.shuffle()
	return [pool[0], pool[1]]
