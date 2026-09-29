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
| Shield | Consumes itself to block one positive-damage attack, physical or magical, regardless of its size. | No |
| Frozen | Blocks movement until the hero commits a legal move with an effective movement allowance of at least 6; then breaks. | No |
| Bleed | Loses 1 HP per 2 actual steps in one move, rounded down, capped at 3 HP per move. | No |
| Nature Shield | Reduces an incoming attack by 1 and deals 1 HP loss to its attacker. | Yes |
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
over Nature Shield: a fully shielded attack does not retaliate. Reflection is
status HP loss and cannot cause reflection loops.

`TakeDamage(amount, direct, damage_type, attacker)` accepts an optional attacker
for Nature Shield. Like the existing damage API, it returns whether the defender
died; the caller must resolve deaths, including an attacker reduced to zero by
reflection. Board combat already handles this, including mutual knockouts.

Icons use the supplied `Arts/Textures_Game/Effects/Status` assets, follow the hero's
rendered head even on shared tiles, and stay upright under board rotation. The
small `t` number is remaining owner turns, not power stacks. The selected hero's
panel also shows icons with status type and duration tooltips.

No hero skills automatically inflict these effects yet: skill assignments and
durations will be supplied separately. Open `tests/hero_status_preview.tscn` for a
visual showcase, or run `tests/hero_status_test.tscn` for regression checks.
