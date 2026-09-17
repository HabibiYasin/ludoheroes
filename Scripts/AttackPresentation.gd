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
