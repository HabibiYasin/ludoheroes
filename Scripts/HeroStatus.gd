extends RefCounted

const DEFINITIONS := {
	"Stun": {"file": "stunned.png", "type": "Debuff", "stackable": false},
	"Shield": {"file": "shield.png", "type": "Buff", "stackable": false},
	"Frozen": {"file": "frozen.png", "type": "Debuff", "stackable": false},
	"Bleed": {"file": "bleeding.png", "type": "Debuff", "stackable": false},
	"Nature Shield": {"file": "nature shield.png", "type": "Buff", "stackable": true},
	"Confused": {"file": "confused.png", "type": "Debuff", "stackable": false},
	"Thorned": {"file": "thorned.png", "type": "Debuff", "stackable": true},
	"Drown": {"file": "Drowned.png", "type": "Debuff", "stackable": true},
	"Slowed": {"file": "Slowed.png", "type": "Debuff", "stackable": true},
	"Cursed": {"file": "Cursed.png", "type": "Debuff", "stackable": false},
	"Hidden": {"file": "", "type": "Buff", "stackable": false},
}
const ASSET_PATH := "res://Arts/Textures_Game/Effects/Status/"

var effects: Dictionary = {}
var moved_this_turn := false
var confusion_seed: int = 0

func apply(id: String, turns: int = -1) -> bool:
	if not DEFINITIONS.has(id) or turns == 0 or turns < -1:
		return false
	if id == "Stun" and turns == -1:
		turns = 1
	if id in ["Shield", "Nature Shield"]:
		if id == "Shield" and effects.has(id):
			return false
		var charges := 1 if id == "Shield" else maxi(1, turns)
		if effects.has(id):
			charges += int(effects[id].charges)
		effects[id] = {"turns": -1, "elapsed": 0, "charges": charges}
		return true
	if effects.has(id):
		var entry: Dictionary = effects[id]
		if not DEFINITIONS[id].stackable:
			return false
		entry.turns = -1 if entry.turns == -1 or turns == -1 else entry.turns + turns
	else:
		effects[id] = {"turns": turns, "elapsed": 0}
		if id == "Confused":
			confusion_seed = randi()
	return true

func count(id: String) -> int:
	return 1 if effects.has(id) else 0

func summary() -> String:
	var lines := PackedStringArray()
	for id: String in effects:
		var entry: Dictionary = effects[id]
		var text := id
		if id == "Cursed":
			text += " (%d giliran untuk dadu 4)" % (4 - entry.elapsed)
		elif entry.has("charges"):
			text += " (%d serangan)" % entry.charges
		elif entry.turns > 0:
			text += " (%d giliran)" % entry.turns
		lines.append(text)
	return "\n".join(lines)
