# Hero statuses

Skills and other gameplay sources can apply a status to a `Piece`:

```gdscript
target.ApplyStatus("Stun", 2)       # Two turns of the target's owner.
target.ApplyStatus("Thorned", 3)
target.ApplyStatus("Thorned", 2)    # Five remaining turns, same damage strength.
target.RemoveStatus("Stun")        # Explicit cleanse.
target.HasStatus("Shield")
```

`ApplyStatus` returns false for unknown names, invalid durations, dead/finished
heroes, or an already active non-stackable status. Stackable statuses add their
remaining durations; they never increase damage, reduction, or movement penalties.
Shield and Nature Shield are exceptions: they store attack charges with no turn
expiry. Shield always has one charge and rejects reapplication. Nature Shield
adds the supplied number of charges (default one), with only -1 damage per hit.
Durations are supplied by each skill. Omitted duration means condition-based
expiry (`-1`), except Stun defaults to one turn. Adding a condition-based duration
to a stackable status leaves it condition-based.

Durations tick once at the end of the affected owner's turn, after both dice have
been resolved. If applied during that owner's turn, its end counts as the first
tick. They do not tick during other players' turns. Returning to base clears all
statuses, and a defeated hero revives using the existing game rules.

| Status | Effect | Stackable |
| --- | --- | --- |
| Stun | Blocks movement and pair summons. | No |
| Shield | Blocks one basic attack regardless of damage, then disappears. Skills bypass it without consuming it. No turn expiry. | No |
| Frozen | Blocks movement until the hero commits a legal move with an effective movement allowance of at least 6; then breaks. | No |
| Bleed | Loses 1 HP per 2 actual steps in one move, rounded down, capped at 3 HP per move. | No |
| Nature Shield | Each basic hit consumes one charge, reduces damage by 1, and stuns its attacker for one turn, at most once per attacker turn. Skill damage bypasses it. No turn expiry. | Yes, charges |
| Confused | Each step independently chooses forward or backward, currently 50% each. | No |
| Thorned | Loses `max(0, actual steps - 3)` HP for a move. | Yes |
| Drown | A deployed hero loses 1 HP at the end of its owner's turn if it did not move. | Yes |
| Slowed | Reduces each die's effective movement allowance by 1, minimum zero. | Yes |
| Cursed | Any rolled die showing 4 removes the curse; otherwise the hero dies after four owner turns. | No |

Confused generates a stable step sequence for each die value while choosing a move,
so querying legal moves, switching dice, previews, and bot evaluation never reroll
it. Completing a move generates a fresh sequence for the hero's next move, even
if both dice show the same value. Steps backwards stop at the first path square (they do not enter base).
Movement cannot pass beyond the final waypoint. A move returning to its starting
square still counts its actual steps for Bleed, Thorned, and Drown.
Frozen can also break on a legal base summon using a six (including a pair totaling
six), provided Slowed has not reduced its effective allowance below six.

Movement damage resolves after walking but before landing attacks, items, or goal
scoring. Status HP loss bypasses attack defenses and Shield. Shield takes priority
over Nature Shield: a fully shielded hit does not consume Nature Shield or stun.
Nature Shield no longer reflects damage. Multi-hit basic attacks consume a charge
per hit even when reduction prevents all damage; Stun does not interrupt hits
already committed in the same attack. Death clears all remaining charges.

`TakeDamage(amount, direct, damage_type, attacker, is_skill)` accepts an optional
attacker for Nature Shield and a skill flag (default false). Skills must pass true
regardless of physical/magical damage type. The return value indicates whether
the defender died; the caller resolves death.

Icons use the supplied `Arts/Textures_Game/Effects/Status` assets, follow the hero's
rendered sprite even on shared tiles, and stay upright under board rotation.
Only Stun and Confused appear above the head; other effects cover the body.
The small `t` number is remaining owner turns; `x` is remaining attack charges.
The selected hero's panel also shows status type and duration/charge tooltips.

Hero skills now apply these effects; see [hero-skills.md](hero-skills.md) for
activation dice, durations, cooldowns, and skill-specific variants. Fresh buffs
applied by a skill during the owner's own turn skip that turn's duration tick.
Hidden is an additional skill effect; Thornhide grants Nature Shield. Open
`tests/hero_status_preview.tscn` for a visual showcase, or run
`tests/hero_status_test.tscn` for regression checks.
