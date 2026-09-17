extends CanvasLayer

const GOLD := Color("f4c563")
const INK := Color("17243c")
var root: Control
var hero_icon: TextureRect
var hero_name: Label
var hero_health: Label
var hero_attack: Label
var hero_physical_defense: Label
var hero_magical_defense: Label
var inspected_hero: Piece
var modal: ColorRect
var menu_panel: Panel
var settings_panel: Panel
var emote: Label
var idle_controller: Node
var idle_countdown: Label
var idle_warning: Label
var round_label: Label
var item_icons: Array[TextureRect] = []
var item_counts: Array[Label] = []
var hero_move: Label
var hero_skill_damage: Label
var match_results: CanvasLayer

var board: BoardManager
var automatic_hero: Piece
var inspection_until := -1
var cards: Dictionary = {}
var scores: Dictionary = {}
var ranking: Array[int] = []
var rank_tween: Tween
var recommendations: Array[Piece] = []
var recommendation_icons: Array[TextureRect] = []
var recommendation_buttons: Array[Button] = []
var skill_panel: Panel
var skill_title: Label

const Portrait = preload("res://Scripts/HUDPortrait.gd")
const FACTION_COLORS := [Color("20c770"), Color("b767e4"), Color("478bf5"), Color("ff414b")]
var round_numbers: Array[Label] = []
var round_crosses: Array[Label] = []
var hero_portraits: Array[Button] = []
var faction_button: Button
var displayed_player: int = -1
var storage_panel: Panel
var storage_content: Control
var storage_signature := ""
var chat_bubbles: Dictionary = {}
var emote_bubbles: Dictionary = {}
var bubble_versions: Dictionary = {}
var skill_description: Label
var dice: Dice

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	board = get_parent().get_node("CoreGamplay/Board/board_GamePlay")
	dice = get_parent().get_node("CoreGamplay/Dice/DiceRoot")
	_build_rounds()
	board.RoundChanged.connect(_refresh_round)
	board.ItemHeroInspected.connect(_follow_hero)
	board.HeroMoveStarted.connect(_follow_hero)
	_refresh_round(board.currentRound)
	var hero := _panel(root, Rect2(38, 154, 374, 602), Color("2d384d"))
	var frame := _style(Color("2d384d"))
	frame.set_corner_radius_all(0)
	frame.set_border_width_all(7)
	frame.border_color = Color("080d17")
	hero.add_theme_stylebox_override("panel", frame)
	hero_name = _label(hero, "Pilih hero", Rect2(12, 15, 350, 50), 29)
	hero_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_icon = _picture(hero, Rect2(38, 72, 298, 270), null)
	hero_health = _label(hero, "", Rect2(14, 342, 170, 40), 27)
	hero_attack = _label(hero, "", Rect2(190, 342, 170, 40), 27)
	hero_physical_defense = _label(hero, "", Rect2(14, 383, 170, 40), 27)
	hero_magical_defense = _label(hero, "", Rect2(190, 383, 170, 40), 27)
	hero_move = _label(hero, "", Rect2(14, 424, 170, 40), 27)
	hero_skill_damage = _label(hero, "", Rect2(190, 424, 170, 40), 27)
	for i in range(3):
		var slot := _panel(hero, Rect2(16 + i * 117, 478, 108, 108), Color("eff2f8"))
		var style := _style(Color("eff2f8"))
		style.set_corner_radius_all(0)
		slot.add_theme_stylebox_override("panel", style)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.tooltip_text = "Skill - coming soon" if i == 0 else "Slot item kosong"
		if i > 0:
			var icon := _picture(slot, Rect2(0, 0, 108, 108), null)
			icon.mouse_filter = Control.MOUSE_FILTER_STOP
			item_icons.append(icon)
			item_counts.append(_label(slot, "", Rect2(65, 77, 40, 28), 19, GOLD))
	faction_button = _circle(root, Rect2(83, 780, 286, 286), null, "Domain Authority", _open_skill.bind("Domain Authority"))
	faction_button.ring_width = 0
	_build_cards()
	_build_actions()
	idle_controller = get_parent().get_node("CoreGamplay/PlayerIdleController")
	idle_countdown = _label(root, "", Rect2(38, 126, 374, 25), 17)
	idle_countdown.add_theme_color_override("font_shadow_color", Color.BLACK)
	idle_countdown.add_theme_constant_override("shadow_offset_y", 2)
	idle_warning = _label(root, "", Rect2(480, 95, 960, 80), 24, GOLD)
	idle_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	idle_warning.add_theme_stylebox_override("normal", _style(INK))
	idle_warning.hide()
	_build_menu()
	_build_skill_popup()
	_build_storage()
	GameManager.HeroInspected.connect(_inspect_hero)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_follow_hero(board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor).Pieces[0])
	for color in range(4):
		for piece: Piece in board.piecesManager.GetPieceGroupBasedOnType(color).Pieces:
			piece.StatsChanged.connect(_refresh_ranking)
	_refresh_ranking()
	_refresh_recommendations()
	match_results = preload("res://Scripts/MatchResults.gd").new()
	match_results.board = board
	add_child(match_results)

func _build_rounds() -> void:
	round_label = _label(root, "A", Rect2(466, 5, 68, 74), 60)
	_label(root, "|", Rect2(532, 5, 22, 74), 56)
	for i in range(10):
		var x := 558 + i * 89
		var color := Color("ff414b") if i == 9 else (GOLD if i == 4 else Color.WHITE)
		round_numbers.append(_label(root, str(i + 1), Rect2(x, 8, 80, 70), 55, color))
		var cross := _label(root, "X", Rect2(x, 4, 80, 74), 64, Color("ff414b"))
		cross.hide()
		round_crosses.append(cross)
		if i < 9:
			_label(root, "-", Rect2(x + 77, 14, 15, 60), 32)

func _round_block(value: int) -> String:
	var block := maxi(0, (value - 1) / 10)
	var result := ""
	while true:
		result = String.chr(65 + block % 26) + result
		block = block / 26 - 1
		if block < 0:
			return result
	return result

func _refresh_round(value: int) -> void:
	round_label.text = _round_block(value)
	var current := (maxi(1, value) - 1) % 10
	for i in range(10):
		round_crosses[i].visible = i < current
		round_numbers[i].modulate.a = 0.4 if i < current else 1.0
	if inspection_until >= 0 and value >= inspection_until:
		inspection_until = -1
		if is_instance_valid(automatic_hero):
			_display_hero(automatic_hero)


func _process(_delta: float) -> void:
	_refresh_recommendations()
	if storage_panel != null and storage_panel.visible:
		_refresh_storage()
	if idle_controller == null:
		return
	idle_countdown.visible = idle_controller.WaitingForPlayer or idle_controller.AutoPlaying
	idle_countdown.text = "Auto-play aktif - ketuk hero untuk stop" if idle_controller.AutoPlaying else "Aksi otomatis dalam %d detik" % ceili(idle_controller.SecondsRemaining)
	idle_warning.text = idle_controller.WarningText()
	idle_warning.visible = not idle_warning.text.is_empty()

func _resize() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	root.scale = Vector2.ONE * fit
	root.position = (viewport_size - Vector2(1920, 1080) * fit) * 0.5
	if modal != null:
		modal.position = -root.position / fit
		modal.size = viewport_size / fit

func _inspect_hero(piece: Piece) -> void:
	inspection_until = board.currentRound + 2
	_display_hero(piece)

func _follow_hero(piece: Piece) -> void:
	automatic_hero = piece
	if inspection_until < 0:
		_display_hero(piece)

func _display_hero(piece: Piece) -> void:
	if not is_instance_valid(piece):
		return
	if is_instance_valid(inspected_hero) and inspected_hero.StatsChanged.is_connected(_refresh_hero_stats):
		inspected_hero.StatsChanged.disconnect(_refresh_hero_stats)
	inspected_hero = piece
	piece.StatsChanged.connect(_refresh_hero_stats)
	hero_icon.texture = piece.PieceSprite.texture if piece.PieceSprite != null else piece.PieceTexture
	hero_name.text = "%s - (%s)" % [piece.HeroId, piece.HeroClass]
	_refresh_hero_stats()

func _refresh_hero_stats() -> void:
	if not is_instance_valid(inspected_hero):
		return
	var catalog = preload("res://Scripts/ItemCatalog.gd")
	var ids := inspected_hero.Items.keys()
	for i in range(2):
		item_icons[i].texture = catalog.texture(ids[i]) if i < ids.size() else null
		item_counts[i].text = "x%d" % inspected_hero.Items[ids[i]] if i < ids.size() else ""
		item_icons[i].tooltip_text = catalog.NAMES[ids[i]] + "\n" + catalog.EFFECTS[ids[i]] if i < ids.size() else ""
	hero_move.text = "Move  +%d" % inspected_hero.MoveBonus
	hero_skill_damage.text = "S.Dmg  +%d" % inspected_hero.SkillDamage
	hero_health.text = "HP  %d / %d" % [inspected_hero.Health, inspected_hero.MaxHealth]
	hero_attack.text = "ATK  %d" % inspected_hero.Attack
	hero_physical_defense.text = "P. Def  %d" % inspected_hero.PhysicalDefense
	hero_magical_defense.text = "M.Def  %d" % inspected_hero.MagicalDefense


# Presentation hooks for future chat/emote transport. No messages are sent.
func show_player_chat(color: int, value: String) -> void:
	_show_bubble(color, value, false)

func show_player_emote(color: int, value: String) -> void:
	_show_bubble(color, value, true)

func _show_bubble(color: int, value: String, is_emote: bool) -> void:
	if not cards.has(color):
		return
	var bubbles: Dictionary = emote_bubbles if is_emote else chat_bubbles
	var bubble: Label = bubbles[color]
	var key := "%d:%s" % [color, is_emote]
	var version := int(bubble_versions.get(key, 0)) + 1
	bubble_versions[key] = version
	bubble.text = value
	bubble.show()
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(bubble) and bubble_versions.get(key) == version:
		bubble.hide()

func _react(value: String) -> void:
	show_player_emote(int(GameManager.LocalPlayerColor), value)

func _build_menu() -> void:
	modal = ColorRect.new()
	modal.color = Color(0, 0, 0, 0.72)
	root.add_child(modal)
	menu_panel = _panel(root, Rect2(650, 280, 620, 520))
	menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(menu_panel, "MENU", Rect2(20, 30, 580, 60), 40, GOLD)
	_button(menu_panel, "Lanjutkan", Rect2(60, 125, 500, 80), _close_menu)
	_button(menu_panel, "Settings", Rect2(60, 235, 500, 80), func(): menu_panel.hide(); settings_panel.show())
	_button(menu_panel, "Exit", Rect2(60, 345, 500, 80), func(): get_tree().quit())
	settings_panel = _panel(root, Rect2(650, 280, 620, 520))
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(settings_panel, "SETTINGS", Rect2(20, 30, 580, 60), 40, GOLD)
	var audio_settings := preload("res://Scripts/AudioSettings.gd").new()
	audio_settings.position = Vector2(60, 108)
	audio_settings.size = Vector2(500, 240)
	settings_panel.add_child(audio_settings)
	_button(settings_panel, "Kembali", Rect2(60, 398, 500, 80), _close_menu)
	modal.hide()
	menu_panel.hide()
	settings_panel.hide()

func _open_menu() -> void:
	_close_menu()
	modal.show()
	menu_panel.show()
	get_tree().paused = true

func _close_menu() -> void:
	if storage_panel != null:
		storage_panel.hide()
	skill_panel.hide()
	modal.hide()
	menu_panel.hide()
	settings_panel.hide()
	get_tree().paused = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if modal.visible:
			_close_menu()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(18)
	return style

func _panel(parent: Node, bounds: Rect2, color: Color = Color("17243ce8")) -> Panel:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	return panel

func _label(parent: Node, value: String, bounds: Rect2, font_size: int, color: Color = Color.WHITE) -> Label:
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

func _picture(parent: Node, bounds: Rect2, texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.position = bounds.position
	picture.size = bounds.size
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _button(parent: Node, value: String, bounds: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.position = bounds.position
	button.size = bounds.size
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", _style(GOLD))
	button.add_theme_stylebox_override("hover", _style(Color("ffdc8a")))
	button.add_theme_stylebox_override("pressed", _style(Color("ce9c42")))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, INK)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _circle(parent: Node, bounds: Rect2, texture: Texture2D, tip: String, action: Callable) -> Button:
	var button := Portrait.new()
	button.position = bounds.position
	button.size = bounds.size
	parent.add_child(button)
	button.portrait.texture = texture
	button.tooltip_text = tip
	button.pressed.connect(action)
	return button

func _build_cards() -> void:
	var names := ["Hijau", "Ungu", "Biru", "Merah"]
	ranking.append(int(GameManager.LocalPlayerColor))
	for color in range(4):
		if color != int(GameManager.LocalPlayerColor):
			ranking.append(color)
	for i in range(4):
		var color := ranking[i]
		var card := _panel(root, Rect2(1510, 138 + i * 94, 390, 90), Color.TRANSPARENT)
		card.name = "PlayerCard%d" % color
		cards[color] = card
		var avatar := _circle(card, Rect2(35, 0, 88, 88), load("res://Arts/Player/player %d.jpg" % (4 if i == 0 else i)), "", func(): pass)
		avatar.ring_color = FACTION_COLORS[color]
		avatar.portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var player_name: String = "Player (You)" if color == int(GameManager.LocalPlayerColor) else ("Bot. " + names[color] if board.BotsEnabled else "Player " + names[color])
		var title := _label(card, player_name, Rect2(135, 3, 253, 42), 27)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		scores[color] = _label(card, "Score: 0", Rect2(135, 44, 253, 36), 26)
		scores[color].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var chat := _label(card, "", Rect2(129, 40, 258, 49), 19)
		chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chat.add_theme_stylebox_override("normal", _style(INK))
		chat.hide()
		chat_bubbles[color] = chat
		var reaction := _label(card, "", Rect2(-40, 18, 74, 60), 28)
		reaction.add_theme_stylebox_override("normal", _style(INK))
		reaction.hide()
		emote_bubbles[color] = reaction
	emote = emote_bubbles[int(GameManager.LocalPlayerColor)]
	for i in range(4):
		var portrait := _circle(root, Rect2(1490 + (i % 2) * 220, 675 + (i / 2) * 200, 186, 186), null, "", _inspect_recommendation.bind(i))
		portrait.ring_width = 7
		hero_portraits.append(portrait)
		recommendation_buttons.append(portrait)
		recommendation_icons.append(portrait.portrait)

func _build_actions() -> void:
	var icons := "res://Arts/Textures_Game/Icons/"
	_circle(root, Rect2(1510, 12, 116, 116), load(icons + "Battle Status.png"), "Battle Status", _open_skill.bind("Battle Status"))
	_circle(root, Rect2(1641, 12, 116, 116), load(icons + "Knowledge.png"), "Knowledge", _open_skill.bind("Knowledge"))
	_circle(root, Rect2(1772, 12, 116, 116), load(icons + "Settings.png"), "Pengaturan", _open_settings)
	_circle(root, Rect2(1513, 523, 135, 135), load(icons + "Items.png"), "Storage", _open_storage)
	_circle(root, Rect2(1748, 523, 135, 135), load(icons + "Emote and Chat.png"), "Chat & Emoji", _open_skill.bind("Chat & Emoji"))

func _open_settings() -> void:
	_close_menu()
	modal.show()
	settings_panel.show()
	get_tree().paused = true

func _refresh_ranking() -> void:
	var values: Dictionary = {}
	for result in board.piecesManager.GetMatchResults():
		values[int(result.color)] = int(result.score)
		scores[int(result.color)].text = "Score: %d" % result.score
	var next_order: Array[int] = ranking.duplicate()
	# Ties retain their previous order; the local player starts at the top.
	next_order.sort_custom(func(a: int, b: int) -> bool:
		return values[a] > values[b] if values[a] != values[b] else ranking.find(a) < ranking.find(b))
	if next_order == ranking:
		return
	ranking = next_order
	if rank_tween != null:
		rank_tween.kill()
	rank_tween = create_tween().set_parallel(true)
	rank_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		rank_tween.tween_property(cards[ranking[i]], "position:y", 138.0 + i * 94.0, 0.45)

func _refresh_recommendations() -> void:
	var color := int(board.currentPlayerColor) if board.IsHumanTurn() else int(board.HumanPlayerColor)
	if color != displayed_player:
		displayed_player = color
		recommendations.assign(board.piecesManager.GetPieceGroupBasedOnType(color).Pieces)
		var faction := recommendations[0].Faction
		faction_button.portrait.texture = load("res://Arts/Textures_Game/Board/%s Finish.png" % faction)
		faction_button.tooltip_text = "%s - Domain Authority (coming soon)" % faction
		for i in range(4):
			hero_portraits[i].portrait.texture = recommendations[i].PieceTexture
			hero_portraits[i].background.texture = load("res://Arts/Textures_Game/Board/%sBattle.png" % faction)
	for i in range(recommendations.size()):
		var hero := recommendations[i]
		var action := _hero_action(hero)
		var portrait = hero_portraits[i]
		portrait.ring_color = Color("ff414b") if action == "attack" else (Color("27da79") if action == "skill" else GOLD)
		var blocked := action == "blocked" or hero.IsInHome
		portrait.shade.color = Color(0, 0, 0, 0.68) if blocked else (Color(1, 0.06, 0.09, 0.40) if hero.Health * 3 <= hero.MaxHealth else Color.TRANSPARENT)
		var caption := "Kocok dadu" if action == "roll" else ("Serang" if action == "attack" else ("Jalankan" if action == "move" else "Tidak ada langkah"))
		portrait.tooltip_text = "%s - %s" % [hero.HeroId, "Selesai" if hero.IsInHome else caption]

# The preview and click resolve the same die, including pair summons.
func _hero_die(hero: Piece) -> int:
	if not board.IsHumanTurn() or hero.CurrentPlayerColor != board.currentPlayerColor or hero.IsInHome:
		return -1
	if GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerSelectPiece:
		return -1
	var group := board.piecesManager.GetPieceGroupBasedOnType(hero.CurrentPlayerColor)
	var path_count := board.GetPathCount(hero.CurrentPlayerColor)
	var order: Array[int] = [board.selectedDiceIndex]
	for index in range(board.remainingDice.size()):
		if not order.has(index):
			order.append(index)
	for index in order:
		if index >= 0 and index < board.remainingDice.size() and board.remainingDice[index] > 0 and group.GetMovablePieces(board.remainingDice[index], path_count).has(hero):
			return index
	return -1

func _hero_action(hero: Piece) -> String:
	if hero.IsInHome or not board.IsHumanTurn() or hero.CurrentPlayerColor != board.currentPlayerColor:
		return "blocked"
	if GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice:
		return "roll"
	var die_index := _hero_die(hero)
	if die_index < 0:
		return "blocked"
	var target := 0 if hero.IsInLobby() else hero.CurrentPosition + hero.GetMoveDistance(board.remainingDice[die_index])
	var cell := board.way_points.GetWayPoint(target, hero.CurrentPlayerColor)
	if cell != null and hero.Attack > 0 and cell._find_capturable_opponent(hero) != null:
		return "attack"
	# Active skills are not implemented yet. Reserve the green ring for their action.
	return "move"

func _inspect_recommendation(index: int) -> void:
	if get_tree().paused or board.item_choice.stage != null:
		return
	_refresh_recommendations()
	if index < 0 or index >= recommendations.size():
		return
	var hero := recommendations[index]
	GameManager.HeroInspected.emit(hero)
	if not board.IsHumanTurn():
		return
	if GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerCanRollDice:
		board.ManualAction.emit()
		dice.RollDice()
		return
	var die_index := _hero_die(hero)
	if die_index < 0:
		return
	board.SelectDie(die_index)
	hero.ManualInput()
	_refresh_recommendations()

func _build_skill_popup() -> void:
	skill_panel = _panel(root, Rect2(650, 330, 620, 420))
	skill_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	skill_title = _label(skill_panel, "", Rect2(20, 30, 580, 60), 36, GOLD)
	skill_description = _label(skill_panel, "Coming soon", Rect2(40, 110, 540, 150), 26)
	skill_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(skill_panel, "Tutup", Rect2(160, 300, 300, 70), _close_menu)
	skill_panel.hide()

func _open_skill(title: String) -> void:
	_close_menu()
	modal.show()
	skill_title.text = title
	match title:
		"Domain Authority":
			skill_description.text = "Coming soon\nSkill faksi dengan kondisi khusus. Efek hanya berlaku di wilayah faksinya."
		"Knowledge":
			skill_description.text = "Coming soon\nPengetahuan hero, item, dan skill."
		"Battle Status":
			skill_description.text = "Coming soon\nStatistik dan ringkasan pertempuran."
		_:
			skill_description.text = "Coming soon\nChat dan emoji pemain."
	skill_panel.show()
	get_tree().paused = true

func _build_storage() -> void:
	storage_panel = _panel(root, Rect2(570, 175, 780, 750))
	storage_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(storage_panel, "STORAGE", Rect2(30, 20, 720, 55), 38, GOLD)
	storage_content = Control.new()
	storage_content.position = Vector2(30, 90)
	storage_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	storage_panel.add_child(storage_content)
	_button(storage_panel, "Tutup", Rect2(240, 660, 300, 64), _close_menu)
	storage_panel.hide()

func _open_storage() -> void:
	_close_menu()
	modal.show()
	storage_signature = ""
	storage_panel.show()
	_refresh_storage()
	get_tree().paused = true

func _refresh_storage() -> void:
	var signature := str(displayed_player)
	if signature == storage_signature:
		return
	storage_signature = signature
	for child in storage_content.get_children():
		child.free()
	_label(storage_content, "Item sekali pakai milik pemain", Rect2(0, 5, 720, 45), 28)
	_label(storage_content, "Belum ada item disposable.", Rect2(0, 55, 720, 45), 23, Color("b6c4d8"))
	for i in range(6):
		var slot := _panel(storage_content, Rect2(52 + (i % 3) * 214, 125 + (i / 3) * 190, 188, 166), Color("304059"))
		_label(slot, "Kosong", Rect2(0, 0, 188, 166), 23, Color("9ba6ba"))
	_label(storage_content, "Item disposable akan tersedia di sini.", Rect2(0, 510, 720, 40), 22)
