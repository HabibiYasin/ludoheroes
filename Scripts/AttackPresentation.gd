extends CanvasLayer

const SLASHES = preload("res://Arts/Textures_Game/Effects/AttackSlashes.tres")
const BATTLE_BACKGROUNDS := {
	"Nerathis": preload("res://Arts/Textures_Game/Board/NerathisBattle.png"),
	"Astherion": preload("res://Arts/Textures_Game/Board/AstherionBattle.png"),
	"Thornvale": preload("res://Arts/Textures_Game/Board/ThornvaleBattle.png"),
	"Nekravia": preload("res://Arts/Textures_Game/Board/NekraviaBattle.png"),
}
var pending: Array[Dictionary] = []
var stage: Control

func show_skill_name(skill_name: String) -> void:
	var cover := ColorRect.new()
	cover.name = "SkillAnnouncement"
	cover.color = Color(0.03, 0.02, 0.09, 0.65)
	cover.size = get_viewport().get_visible_rect().size
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	var title := Label.new()
	title.text = skill_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", int(76 * minf(cover.size.x / 1920.0, cover.size.y / 1080.0)))
	title.add_theme_color_override("font_color", Color("ffe49b"))
	title.add_theme_color_override("font_outline_color", Color("261237"))
	title.add_theme_constant_override("outline_size", 8)
	cover.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.modulate.a = 0.0
	var animation := create_tween()
	animation.tween_property(cover, "modulate:a", 1.0, 0.15)
	animation.tween_interval(0.65)
	animation.tween_property(cover, "modulate:a", 0.0, 0.15)
	await animation.finished
	cover.queue_free()

func play_skill(caster: Piece, skill_name: String, targets: Array[Dictionary]) -> void:
	if targets.is_empty():
		return
	stage = Control.new()
	stage.name = "SkillBattle"
	stage.size = Vector2(1000, 1000)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(stage)
	_process(0.0)
	var background := TextureRect.new()
	background.name = "BattleBackground"
	background.texture = BATTLE_BACKGROUNDS.get(targets[0].territory, BATTLE_BACKGROUNDS.get(caster.Faction))
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = stage.size
	stage.add_child(background)
	var title := Label.new()
	title.text = skill_name
	title.position = Vector2(30, 35)
	title.size = Vector2(940, 140)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color("ffe49b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 7)
	stage.add_child(title)
	var attacker := _hero(caster.PieceSprite.texture, Vector2(220, 540))
	attacker.name = "SkillCaster"
	var columns := 1 if targets.size() == 1 else 2
	var rows := ceili(float(targets.size()) / columns)
	var spacing_y := minf(300, 690.0 / rows)
	var size_limit := minf(260, spacing_y * 0.85)
	var effects: Array[AnimatedSprite2D] = []
	for index in range(targets.size()):
		var record := targets[index]
		var center := Vector2(720 if columns == 1 else 580 + (index % columns) * 260, 540 + (index / columns - (rows - 1) * 0.5) * spacing_y)
		var target := _hero(record.texture, center)
		target.name = "SkillTarget%d" % index
		target.scale = Vector2.ONE * size_limit / maxf(record.texture.get_width(), record.texture.get_height())
		var slash := AnimatedSprite2D.new()
		slash.sprite_frames = SLASHES
		slash.position = center
		var frame_size := SLASHES.get_frame_texture(caster.Faction, 0).get_size()
		slash.scale = Vector2.ONE * (size_limit * 1.25 / maxf(frame_size.x, frame_size.y))
		stage.add_child(slash)
		effects.append(slash)
		var label := Label.new()
		label.text = "-%d" % record.damage if record.damage > 0 else String(record.get("effect", "0"))
		label.position = center + Vector2(-100, -size_limit * 0.6)
		label.size.x = 200
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 46)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		stage.add_child(label)
	var lunge := create_tween()
	lunge.tween_property(attacker, "position:x", 360.0, 0.2)
	await lunge.finished
	for effect in effects:
		effect.play(caster.Faction)
	GameAudio.play_attack()
	await effects.back().animation_finished
	var finish := create_tween()
	finish.tween_interval(0.2)
	finish.tween_property(stage, "modulate:a", 0.0, 0.25)
	await finish.finished
	stage.queue_free()
	stage = null

func queue_attack(attacker: Piece, defender: Piece, damage: int = -1, battle_cell: WayPoint = null) -> void:
	if damage < 0:
		damage = defender.GetIncomingDamage(attacker.Attack)
	if battle_cell == null:
		battle_cell = defender.CurrentWayPoint
	var territory := ""
	if battle_cell != null and attacker.wayPointManager != null:
		territory = attacker.wayPointManager.GetTerritoryFaction(battle_cell)
	pending.append({
		"attacker": attacker.PieceSprite.texture,
		"defender": defender.PieceSprite.texture,
		"faction": attacker.Faction,
		"territory": territory,
		"damage": mini(damage, defender.Health),
	})

func play_pending() -> void:
	while not pending.is_empty():
		await _play(pending.pop_front())

func _process(_delta: float) -> void:
	if is_instance_valid(stage):
		var viewport_size := get_viewport().get_visible_rect().size
		var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
		stage.scale = Vector2.ONE * fit
		stage.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5 + Vector2(470, 90) * fit
		stage.scale *= 0.98

func _hero(texture: Texture2D, center: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = center
	sprite.scale = Vector2.ONE * (340.0 / maxf(texture.get_width(), texture.get_height()))
	stage.add_child(sprite)
	return sprite

func _play(attack: Dictionary) -> void:
	stage = Control.new()
	stage.size = Vector2(1000, 1000)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.modulate.a = 0.0
	add_child(stage)
	_process(0.0)
	var background_texture: Texture2D = BATTLE_BACKGROUNDS.get(attack.get("territory", ""))
	if background_texture != null:
		var background := TextureRect.new()
		background.name = "BattleBackground"
		background.texture = background_texture
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.size = stage.size
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(background)
	else:
		var white := ColorRect.new()
		white.color = Color(1, 1, 1, 0.5)
		white.size = stage.size
		white.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(white)
	var attacker := _hero(attack.attacker, Vector2(250, 520))
	var defender := _hero(attack.defender, Vector2(750, 520))
	var slash := AnimatedSprite2D.new()
	slash.sprite_frames = SLASHES
	slash.position = defender.position
	slash.visible = false
	stage.add_child(slash)
	var damage := Label.new()
	damage.text = "-%d" % attack.damage
	damage.add_theme_font_size_override("font_size", 110)
	damage.add_theme_color_override("font_color", Color("a92e24"))
	damage.add_theme_color_override("font_outline_color", Color.WHITE)
	damage.add_theme_constant_override("outline_size", 8)
	damage.position = Vector2(675, 260)
	damage.modulate.a = 0.0
	stage.add_child(damage)
	var entrance := create_tween()
	entrance.tween_property(stage, "modulate:a", 1.0, 0.18)
	entrance.tween_interval(0.12)
	entrance.tween_property(attacker, "position:x", 570.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await entrance.finished
	slash.visible = true
	var animation := StringName(attack.faction)
	var frame_size := SLASHES.get_frame_texture(animation, 0).get_size()
	slash.scale = Vector2.ONE * (440.0 / maxf(frame_size.x, frame_size.y))
	slash.play(animation)
	GameAudio.play_attack()
	damage.modulate.a = 1.0
	var shake := create_tween()
	for offset in [18.0, -16.0, 12.0, -9.0, 5.0, 0.0]:
		shake.tween_property(defender, "position:x", 750.0 + offset, 0.045)
	var number := create_tween()
	number.tween_property(damage, "position:y", 190.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await slash.animation_finished
	slash.hide()
	var ending := create_tween()
	ending.tween_property(attacker, "position:x", 250.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ending.tween_interval(0.16)
	ending.tween_property(stage, "modulate:a", 0.0, 0.25)
	await ending.finished
	stage.queue_free()
	stage = null
