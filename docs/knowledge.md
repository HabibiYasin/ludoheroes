# Knowledge

The main menu Knowledge button and in-game book button open the same
`Scripts/Knowledge.gd` screen. Each opening starts on Hero. In-game play pauses
while reading; closing restores the previous pause state. Escape closes a hero
popup first, then the guide. The layout scales from a 1920×1080 design canvas.

- Hero: four faction rows with four clickable heroes each; the popup shows the
  portrait, class/faction, base attributes, activation dice, range, cooldown, and
  skill explanation. Skill text scrolls when necessary.
- Equipment: six options, with the first automatically selected; selecting any
  option immediately updates the artwork and description on the right.
- Encyclopedia: topic tabs with scrollable articles about current game rules,
  turns, classes, skills, equipment, and statuses.

Base hero numbers come from HeroCatalog, skill numbers from SkillCatalog, and
equipment from ItemCatalog. Editorial explanations and topic text are centralized
in `Scripts/KnowledgeData.gd`; update them alongside rule changes. The Brilia
portrait intentionally maps to the existing `Brillia.png` filename.

Run `tests/knowledge_test.tscn` to verify both entry points, browsing, default
selection, and pause restoration. Add `-- --capture` with a graphical renderer
to save previews in `.godot/knowledge_*.png`.
