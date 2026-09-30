# Hero skills

All sixteen skills are configured in `Scripts/SkillCatalog.gd`. The matching die
is consumed instead of normal movement. Only deployed, living, unfinished heroes
can cast. Stun prevents casting. Frozen prevents movement skills but allows skills
that do not move the caster. A book is shown only when a matching unused die,
cooldown, and eligible targets permit a cast.

- Click the book on a controller portrait to cast using automatic targeting.
- Hold it for 0.45 seconds to open circular portraits of eligible targets.
- Select up to the skill's target limit and confirm. Cancel spends nothing.
- Click the underlying hero portrait to move normally instead of casting.
- When multiple dice qualify, the selected die is preferred, then another unused
  matching die. The book tooltip identifies the die it will consume.

Target selection pauses the game and idle countdown. It validates targets again
before casting. Cooldown decreases at the start of the owner's next turn: cooldown
1 is available next owner turn, cooldown 2 on the second next owner turn. Cooldown
survives defeat and cannot be bypassed by respawning. A visible CD badge and hero
skill tooltip show remaining cooldown.

Ranges are measured from the caster's current cell, along its path. A skill with
both ranges zero is self-only. Positive ranges include the current tile and the
specified front/behind cells. Offensive skills follow safe-tile combat protection:
they cannot attack from a safe tile or target enemies on safe/home tiles. Allies
can receive buffs on safe tiles. Hidden enemies cannot be selected by ordinary
attacks or enemy skills. Range targeting skips safe targets but may reach an enemy
beyond a safe tile, like normal ranged combat.

| Hero | Skill | Dice | Front/back | Cooldown | Effect |
| --- | --- | --- | --- | --- | --- |
| Brilia | Royal Cleave | 1, 2 | 1/1 | 2 | Damage 2 to all eligible enemies. |
| Suki | Weakspot Arrow | 3, 4 | 2/2 | 2 | Damage 2 to one enemy; automatic targeting chooses lowest HP. |
| Mordian | Iron Bulwark | 1, 2 | 0/0 | 1 | Shield against one basic attack, without turn expiry. |
| Anata | Guardian's Blessing | 6 | 6/6 | 1 | Shield a random unshielded ally in range; otherwise self if unshielded. |
| Kaelgrave | Gravebreaker | 2, 4 | 4/0 | 2 | Stun up to two enemies for one turn; nearest first. |
| Nyssara | Phantom Ambush | 2, 4 | 0/0 | 2 | Hidden for one turn; next basic attack hits twice and reveals her. |
| Vilmira | Blood Curse | 6 | 3/3 | 3 | Bleed one enemy for two turns; nearest first. Class is Mage. |
| Zyrella | Witch's Dash | 1, 2 | 0/0 | 1 | Move exactly three path cells. |
| Silvy | Briar Volley | 2, 3 | 4/0 | 2 | Damage 1 to up to three enemies, nearest first. |
| Garruk | Thornhide | 2, 3 | 0/0 | 1 | Two Nature Shield charges: -1 damage per basic hit and Stun 1 turn, once per attacker turn. |
| Pirunrun | Fairy Sparks | 2, 3 | 4/4 | 2 | Damage 2 to two distinct random enemies. |
| Mycellia | Sporeguard | 4, 5 | 5/5 | 3 | Four Nature Shield charges on the nearest ally. |
| Skalfin | Twin Tides | 2, 3 | 2/2 | 1 | Two hits on one enemy; each deals 1 with an independent 50% chance of +1. |
| Octavus | Tidal Barrage | 6 | 4/4 | 3 | Damage 2 to up to four distinct random enemies. |
| Velissa | Drowning Hex | 2, 3 | 3/3 | 2 | Drown one random enemy for three turns. |
| Kragor | Reef Shortcut | 4, 5 | 0/0 | 3 | Continue straight four tile widths across a corner to a valid later path cell. |

Manual selection overrides automatic lowest-HP/random/nearest selection. A skill
can affect fewer than its maximum targets if fewer eligible enemies exist.
Nature Shield 2/4 denotes attack charges, with no turn expiry. Each hit consumes
one charge and reduces damage by one; reapplication adds charges. Shield is also
permanent until one basic hit or death, and cannot stack. Anata's manual picker
uses the same unshielded-ally preference and self fallback as automatic targeting.
Other non-stackable statuses reject reapplication; other stackable statuses add duration.
Buffs applied during their owner's turn do not lose a duration tick immediately
at that turn's end. Other duration rules use the status system's owner-turn ticks.

Vilmira uses a skill-specific Bleed variant: a move of 1–3 actual steps loses 1 HP,
4–6 loses 2 HP, and longer moves lose at most 3 HP. It never applies Cursed.
Hidden uses a translucent sprite and a text marker, without inventing a new asset.

Damaging skills add SkillDamage per hit. Fairy Sparks and Tidal Barrage use magical
defense; the weapon skills use physical defense. Damaging skills, including both
hits of Twin Tides, bypass Shield and Nature Shield without consuming charges or
triggering Stun. Nyssara's two basic hits consume protection separately; Nature
Shield reduces each hit but stuns her only once that turn. Shield has priority
when both shields are present. Defeated heroes lose statuses and revive at base.

Witch's Dash uses exactly three steps without die/item/Runner movement bonuses.
Reef Shortcut follows the most recent straight heading (also at a diagonal corner
transition). It is available only when the landing is exactly four tile widths
away on a later path cell beyond the normal four-step destination. The animation
travels directly across the corner, without following the skipped path. Movement
status damage counts four steps, not the number of skipped path cells. Both
movement skills retain landing combat, item rewards, finish scoring, and death
cleanup. Frozen and Stun prevent these movement skills.

Each cast announces the skill name in the screen center. Offensive skills then
show the existing faction battlefield, caster, and all affected targets together,
using the existing attack effects. Bot and idle play can also select legal skills.

Validation scenes: `tests/skills_test.tscn` and `tests/skills_ui_test.tscn`.
Interactive demonstration: `tests/skills_preview.tscn` (Octavus with four targets).
Optional preview arguments: `--targets`, `--battle`, `--announcement`, `--capture`.
