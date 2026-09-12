# Entries: Class, Faction, Attack, Health, Physical Defense, Magical Defense.
extends RefCounted

# Source: Character design basic.xlsx, Name / Class / Faction / Attack / Health.
const HEROES := {
	"Brilia": ["Warrior", "Astherion", 2, 3, 0, 0],
	"Suki": ["Ranger", "Astherion", 3, 1, 0, 0],
	"Mordian": ["Tank", "Astherion", 1, 4, 0, 0],
	"Anata": ["Support", "Astherion", 0, 5, 0, 0],
	"Kaelgrave": ["Warrior", "Nekravia", 2, 3, 0, 0],
	"Nyssara": ["Assassin", "Nekravia", 3, 2, 0, 0],
	"Vilmira": ["Warrior - mage", "Nekravia", 2, 3, 0, 0],
	"Zyrella": ["Runner", "Nekravia", 2, 3, 0, 0],
	"Silvy": ["Ranger", "Thornvale", 3, 2, 0, 0],
	"Garruk": ["Tank", "Thornvale", 1, 4, 0, 0],
	"Pirunrun": ["Mage", "Thornvale", 2, 3, 0, 0],
	"Mycellia": ["Support", "Thornvale", 2, 3, 0, 0],
	"Skalfin": ["Warrior", "Nerathis", 2, 3, 0, 0],
	"Octavus": ["Mage", "Nerathis", 3, 2, 0, 0],
	"Velissa": ["Support", "Nerathis", 2, 3, 0, 0],
	"Kragor": ["Runner", "Nerathis", 1, 4, 0, 0],
}