extends CanvasLayer

const ASSET_PATH := "res://Arts/Textures_Game/Notifications/"
const TEAM_COLORS := [Color("29975a"), Color("e7ba19"), Color("168ccd"), Color("d93c40")]
const PLACES := ["1st", "2nd", "3rd", "4th"]
const INK := Color("17243c")

var board: BoardManager
var root: Control
var backdrop: ColorRect
var banner: TextureRect
var hint: Label
var table: Control
var sound: AudioStreamPlayer
var results: Array[Dictionary] = []
var showing_scores := false
var presented := false
var is_victory := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	backdrop = ColorRect.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	banner = _picture(root, null, Rect2(240, 260, 1440, 560))
	hint = _label(root, "Klik untuk melihat penilaian", Rect2(460, 900, 1000, 56), 30, Color.WHITE)
	sound = AudioStreamPlayer.new()
	sound.bus = "Music"
	add_child(sound)
	visible = false
	GameManager.OnGameCurrentStateChange.connect(_on_state_changed)
	get_viewport().size_changed.connect(_resize)
	_resize()
	if GameManager.GameCurrentState == GameManager.GameStateEnum.GameOver:
		_on_state_changed(GameManager.GameCurrentState)

func _resize() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	root.scale = Vector2.ONE * fit
	root.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5
	backdrop.size = viewport_size

func _on_state_changed(state: GameManager.GameStateEnum) -> void:
	if state != GameManager.GameStateEnum.GameOver or presented:
		return
	# A battle kill is not a match win: a player must finish their roster first.
	if board.piecesManager.GetWinner() == null:
		return
	presented = true
	results = board.piecesManager.GetMatchResults()
	is_victory = results[0].color == int(GameManager.LocalPlayerColor)
	backdrop.color = Color(0.04, 0.42, 0.16, 0.68) if is_victory else Color(0.65, 0.06, 0.04, 0.68)
	banner.texture = load(ASSET_PATH + ("Victory.png" if is_victory else "Defeated.png"))
	GameAudio.stop_for_results()
	sound.stream = load("res://Sounds/Music/" + ("Victory.mp3" if is_victory else "Defeated.mp3"))
	visible = true
	sound.play()

func _on_backdrop_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		ShowScores()
		backdrop.accept_event()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		ShowScores()
		get_viewport().set_input_as_handled()

func ShowScores() -> void:
	if not presented or showing_scores:
		return
	showing_scores = true
	backdrop.color = Color(0.68, 0.66, 0.63, 0.76)
	banner.position = Vector2(480, 15)
	banner.size = Vector2(960, 300)
	hint.hide()
	table = Control.new()
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(table)
	for index in range(results.size()):
		_build_row(results[index], index)
	_label(table, "Goal +100  |  Kill +10  |  MMR sementara", Rect2(65, 1005, 1100, 50), 24, INK)
	var menu := Button.new()
	menu.text = "Kembali ke Menu"
	menu.position = Vector2(1440, 1005)
	menu.size = Vector2(420, 54)
	menu.add_theme_font_size_override("font_size", 26)
	menu.pressed.connect(func():
		get_tree().paused = false
		GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.PlayerCanRollDice)
		get_tree().change_scene_to_file("res://Levels/MainMenu.tscn")
	)
	table.add_child(menu)

func _build_row(result: Dictionary, index: int) -> void:
	var color: int = result.color
	var row := Panel.new()
	row.name = "ResultRow%d" % color
	row.position = Vector2(65, 325 + index * 168)
	row.size = Vector2(1790, 156)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffdf7")
	style.border_color = TEAM_COLORS[color]
	style.set_border_width_all(10)
	row.add_theme_stylebox_override("panel", style)
	table.add_child(row)
	_label(row, PLACES[index], Rect2(15, 15, 120, 126), 46, INK)
	# Match the HUD's portraits, which put the local player last.
	var player_order: Array[int] = []
	for player_color in [2, 3, 1, 0]:
		if player_color != int(GameManager.LocalPlayerColor):
			player_order.append(player_color)
	player_order.append(int(GameManager.LocalPlayerColor))
	_picture(row, load("res://Arts/Player/player %d.jpg" % (player_order.find(color) + 1)), Rect2(140, 10, 145, 136))
	_label(row, "Goals: %d" % result.goals, Rect2(305, 20, 260, 116), 44, INK)
	_label(row, "|  Score: %d" % result.score, Rect2(575, 20, 350, 116), 44, INK)
	_label(row, "|  MVP:", Rect2(925, 20, 200, 116), 42, INK)
	var hero: Piece = result.mvp
	if hero != null:
		var texture := hero.PieceSprite.texture if hero.PieceSprite != null else hero.PieceTexture
		_picture(row, texture, Rect2(1120, 10, 165, 105))
		_label(row, hero.HeroId, Rect2(1090, 115, 225, 30), 21, INK)
	var divider := ColorRect.new()
	divider.color = TEAM_COLORS[color]
	divider.position = Vector2(1320, 10)
	divider.size = Vector2(5, 136)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(divider)
	_label(row, "MMR:", Rect2(1340, 15, 200, 64), 42, INK)
	_label(row, "%+d" % result.mmr, Rect2(1540, 15, 220, 64), 46, Color("238d4b") if result.mmr > 0 else Color("c92e35"))
	_label(row, "Player (You)" if color == int(GameManager.LocalPlayerColor) else "Bot", Rect2(1340, 80, 420, 60), 36, INK)

func _picture(parent: Node, texture: Texture2D, bounds: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	picture.position = bounds.position
	picture.size = bounds.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _label(parent: Node, value: String, bounds: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = bounds.position
	label.size = bounds.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label
