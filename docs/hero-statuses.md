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
Shield stores one attack charge without turn expiry and rejects reapplication.
Nature Shield stores absorption points: applying it adds the supplied amount
(default one), capped at four, and refreshes its fixed one-owner-turn duration.
Nature Shield expires at the start of its owner's next turn: applied in
Thornvale's player slot in A4, it expires when Thornvale begins that slot in A5.
Ending the current turn or another player's turn does not expire it.
Durations are supplied by each skill. Omitted duration means condition-based
expiry (`-1`), except Stun defaults to one turn. Adding a condition-based duration
to a stackable status leaves it condition-based.

All finite status durations tick at the start of the affected owner's next turn,
before rolling or acting. One turn expires at the next owner-turn start; two
turns expire at the second next start. This includes enemy-applied Stun: a one-turn
Stun is removed before the target can act on its next turn. End-of-turn damage
and Cursed dice checks still resolve at turn end while those effects are active.
Other players' turns do not tick durations. Returning to base clears all
statuses, and a defeated hero revives using the existing game rules.

| Status | Effect | Stackable |
| --- | --- | --- |
| Stun | Blocks movement and pair summons. | No |
| Shield | Blocks one basic attack regardless of damage, then disappears. Skills bypass it without consuming it. No turn expiry. | No |
| Frozen | Blocks movement until the hero commits a legal move with an effective movement allowance of at least 6; then breaks. | No |
| Bleed | Loses 1 HP per 2 actual steps in one move, rounded down, capped at 3 HP per move. | No |
| Nature Shield | Absorbs basic-attack damage after defenses, spending one point per damage absorbed; overflow hits HP. Maximum 4 points, expires after one owner turn. No Stun or reflection. Skill damage bypasses it. | Yes, capped at 4 points |
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
over Nature Shield: a fully shielded hit does not consume Nature Shield.
Nature Shield neither reflects damage nor stuns. Each hit spends the amount
absorbed, not a fixed one charge: 4 points hit for 3 leaves 1 point and no HP loss.
Defenses apply first; fully defended attacks spend no points. Death clears it.

`TakeDamage(amount, direct, damage_type, attacker, is_skill)` accepts an optional
attacker argument and a skill flag (default false). Skills must pass true
regardless of physical/magical damage type. The return value indicates whether
the defender died; the caller resolves death.

Icons use the supplied `Arts/Textures_Game/Effects/Status` assets, follow the hero's
rendered sprite even on shared tiles, and stay upright under board rotation.
Only Stun and Confused appear above the head; other effects cover the body.
The small `t` number is remaining owner turns; `x` is Shield attack charges.
Nature Shield displays its remaining absorption points without the `x` suffix.
The selected hero's panel also shows status type and duration/charge tooltips.

Hero skills now apply these effects; see [hero-skills.md](hero-skills.md) for
activation dice, durations, cooldowns, and skill-specific variants. Buffs and
debuffs share the same owner-turn-start duration clock, without skill exceptions.
Hidden is an additional skill effect; Thornhide grants Nature Shield. Open
`tests/hero_status_preview.tscn` for a visual showcase, or run
`tests/hero_status_test.tscn` for regression checks.
