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
var hero_class: Label
var inspected_hero: Piece
var modal: ColorRect
var menu_panel: Panel
var settings_panel: Panel
var reactions: Panel
var emote: Label
var emote_timer: Timer
var config := ConfigFile.new()
var settings_dirty := false
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
var choice_labels: Array[Label] = []
var sidebar_items: Array[int] = []
var chat_panel: Panel
var skill_panel: Panel
var skill_title: Label
const CHATS := ["Semangat semuanya!", "Langkah bagus!", "Tunggu sebentar!", "GG, seru banget!"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_button(root, "MENU", Rect2(40, 40, 180, 78), _open_menu)
	var round_panel := _panel(root, Rect2(240, 40, 180, 78), GOLD)
	round_label = _label(round_panel, "", Rect2(0, 0, 180, 78), 26, INK)
	board = get_parent().get_node("CoreGamplay/Board/board_GamePlay")
	board.RoundChanged.connect(_refresh_round)
	board.ItemHeroInspected.connect(_follow_hero)
	board.HeroMoveStarted.connect(_follow_hero)
	_refresh_round(board.currentRound)
	var hero := _panel(root, Rect2(40, 170, 380, 604))
	hero_icon = _picture(hero, Rect2(65, 8, 250, 245), null)
	hero_name = _label(hero, "Ketuk hero di papan", Rect2(10, 265, 360, 42), 30)
	hero_health = _label(hero, "HP  - / -", Rect2(10, 315, 180, 38), 27)
	hero_attack = _label(hero, "ATK  -", Rect2(190, 315, 180, 38), 27)
	hero_physical_defense = _label(hero, "P. Def  -", Rect2(10, 355, 180, 38), 27)
	hero_magical_defense = _label(hero, "M.Def  -", Rect2(190, 355, 180, 38), 27)
	hero_move = _label(hero, "Move  +0", Rect2(10, 395, 180, 38), 27)
	hero_skill_damage = _label(hero, "S.Dmg  +0", Rect2(190, 395, 180, 38), 27)
	hero_class = _label(hero, "Class: -", Rect2(10, 445, 360, 30), 21, GOLD)
	_label(hero, "SKILLS                 ITEMS", Rect2(20, 480, 340, 32), 22, GOLD)
	for i in range(4):
		var slot := _panel(hero, Rect2(28 + i * 84, 522, 72, 54), Color("304059"))
		_label(slot, "—", Rect2(0, 8, 72, 44), 30)
	for i in range(2):
		var icon := _picture(hero, Rect2(196 + i * 84, 522, 72, 54), null)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		item_icons.append(icon)
		item_counts.append(_label(hero, "", Rect2(236 + i * 84, 552, 32, 24), 18, GOLD))
	_build_cards()
	emote = _label(cards[int(GameManager.LocalPlayerColor)], "", Rect2(-256, 36, 250, 80), 23, GOLD)
	emote.add_theme_stylebox_override("normal", _style(INK))
	emote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	emote.hide()
	emote_timer = Timer.new()
	emote_timer.one_shot = true
	emote_timer.wait_time = 3.0
	emote_timer.timeout.connect(emote.hide)
	add_child(emote_timer)
	reactions = _panel(root, Rect2(40, 802, 380, 164))
	for i in range(4):
		var reaction: String = [":)  Senang", "GG!", ":O  Wow", ":(  Sedih"][i]
		_button(reactions, reaction, Rect2(12 + (i % 2) * 184, 12 + (i / 2) * 72, 172, 62), _react.bind(reaction))
	reactions.hide()
	idle_controller = get_parent().get_node("CoreGamplay/PlayerIdleController")
	idle_countdown = _label(root, "", Rect2(40, 122, 380, 38), 22, GOLD)
	idle_warning = _label(root, "", Rect2(460, 40, 1000, 110), 26, GOLD)
	idle_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	idle_warning.add_theme_stylebox_override("normal", _style(INK))
	idle_warning.hide()
	_button(root, "Chatbox", Rect2(40, 984, 184, 64), _toggle_chat)
	_button(root, "Emote", Rect2(236, 984, 184, 64), _toggle_emotes)
	chat_panel = _panel(root, Rect2(40, 688, 380, 284))
	chat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(4):
		var button := _button(chat_panel, CHATS[i], Rect2(12, 12 + i * 66, 356, 58), _react.bind(CHATS[i]))
		button.add_theme_font_size_override("font_size", 22)
	chat_panel.hide()
	reactions.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_menu()
	_build_skill_popup()
	GameManager.HeroInspected.connect(_inspect_hero)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_follow_hero(board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor).Pieces[0])
	for color in range(4):
		for piece: Piece in board.piecesManager.GetPieceGroupBasedOnType(color).Pieces:
			piece.StatsChanged.connect(_refresh_ranking)
	_refresh_ranking()

	match_results = preload("res://Scripts/MatchResults.gd").new()
	match_results.board = board
	add_child(match_results)

func _refresh_round(value: int) -> void:
	round_label.text = "RONDE %d" % value
	if inspection_until >= 0 and value >= inspection_until:
		inspection_until = -1
		if is_instance_valid(automatic_hero):
			_display_hero(automatic_hero)


func _process(_delta: float) -> void:
	_refresh_recommendations()
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
	hero_name.text = piece.HeroId
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
	hero_class.text = "Class: %s%s" % [inspected_hero.HeroClass, " | Gugur" if inspected_hero.Health == 0 else ""]

func _react(value: String) -> void:
	chat_panel.hide()
	reactions.hide()
	emote.text = value
	emote.show()
	emote_timer.start()

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
	_label(settings_panel, "Volume suara", Rect2(40, 130, 540, 50), 30)
	config.load("user://settings.cfg")
	var volume := HSlider.new()
	volume.position = Vector2(60, 215)
	volume.size = Vector2(500, 70)
	volume.max_value = 100
	volume.value = float(config.get_value("audio", "volume", 80))
	settings_panel.add_child(volume)
	volume.value_changed.connect(_volume_changed)
	_button(settings_panel, "Kembali", Rect2(60, 345, 500, 80), func(): settings_panel.hide(); menu_panel.show())
	modal.hide()
	menu_panel.hide()
	settings_panel.hide()

func _volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
	AudioServer.set_bus_mute(0, value == 0)
	config.set_value("audio", "volume", value)
	settings_dirty = true

func _open_menu() -> void:
	chat_panel.hide()
	reactions.hide()
	modal.show()
	menu_panel.show()
	get_tree().paused = true

func _close_menu() -> void:
	skill_panel.hide()
	if settings_dirty:
		var error := config.save("user://settings.cfg")
		if error != OK:
			push_warning("Pengaturan tidak dapat disimpan: %s" % error_string(error))
		else:
			settings_dirty = false
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

func _build_cards() -> void:
	var colors := [Color("29975a"), Color("8341b4"), Color("168ccd"), Color("d93c40")]
	var names := ["Hijau", "Kuning", "Biru", "Merah"]
	ranking.append(int(GameManager.LocalPlayerColor))
	for color in range(4):
		if color != int(GameManager.LocalPlayerColor):
			ranking.append(color)
	for i in range(4):
		var color := ranking[i]
		var card := _panel(root, Rect2(1490, 24 + i * 160, 406, 152), colors[color])
		card.name = "PlayerCard%d" % color
		cards[color] = card
		_picture(card, Rect2(12, 16, 118, 118), load("res://Arts/Player/player %d.jpg" % (4 if i == 0 else i)))
		_label(card, "Player" if i == 0 else "Bot." + names[color], Rect2(142, 8, 252, 38), 28)
		scores[color] = _label(card, "Skor 0", Rect2(142, 44, 252, 26), 18)
		for slot_index in range(3):
			var slot := _panel(card, Rect2(156 + slot_index * 76, 82, 60, 56), Color("f5eedc"))
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			slot.tooltip_text = "Slot item spesial • setiap 10 ronde"
	for i in range(2):
		var slot := _panel(root, Rect2(1490, 684 + i * 180, 194, 170))
		recommendation_icons.append(_picture(slot, Rect2(8, 8, 178, 154), null))
		var button := Button.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.flat = true
		button.pressed.connect(_inspect_recommendation.bind(i))
		slot.add_child(button)
		recommendation_buttons.append(button)
		var caption := _label(slot, "", Rect2(6, 112, 182, 52), 17, GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_labels.append(caption)
	_button(root, "Dice\nSkills", Rect2(1700, 684, 196, 170), _open_skill.bind("Dice Skills"))
	_button(root, "Domain\nAuthority", Rect2(1700, 864, 196, 170), _open_skill.bind("Domain Authority"))

func _refresh_ranking() -> void:
	var values: Dictionary = {}
	for result in board.piecesManager.GetMatchResults():
		values[int(result.color)] = int(result.score)
		scores[int(result.color)].text = "Skor %d" % result.score
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
		rank_tween.tween_property(cards[ranking[i]], "position:y", 24.0 + i * 160.0, 0.45)

func _refresh_recommendations() -> void:
	if board.item_choice.stage != null:
		_refresh_item_shortcuts()
		return
	sidebar_items.clear()
	for i in range(2):
		recommendation_icons[i].position = Vector2(8, 8)
		recommendation_icons[i].size = Vector2(178, 154)
		recommendation_icons[i].modulate = Color.WHITE
		recommendation_buttons[i].disabled = false
		choice_labels[i].text = ""
	# Rank distinct legal heroes: exact finish, summon, then path progress.
	recommendations.clear()
	var candidates: Array[Dictionary] = []
	if GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece:
		var group := board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor)
		var path_count := board.GetPathCount(board.currentPlayerColor)
		for piece: Piece in group.Pieces:
			var best := -1.0
			for die in board.remainingDice:
				if die <= 0 or not group.GetMovablePieces(die, path_count).has(piece):
					continue
				var target := piece.CurrentPosition + piece.GetMoveDistance(die)
				var score := 100.0 if not piece.IsInLobby() and target == path_count - 1 else (10.0 if piece.IsInLobby() else float(target) / maxf(1, path_count))
				best = maxf(best, score)
			if best >= 0:
				candidates.append({"piece": piece, "score": best, "order": candidates.size()})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.score > b.score if a.score != b.score else a.order < b.order)
	for i in range(2):
		var icon := recommendation_icons[i]
		icon.texture = null
		icon.get_parent().get_child(1).tooltip_text = "Belum ada langkah legal"
		if i < candidates.size():
			var piece: Piece = candidates[i].piece
			recommendations.append(piece)
			icon.texture = piece.PieceTexture
			icon.get_parent().get_child(1).tooltip_text = "Rekomendasi: " + piece.HeroId

func _inspect_recommendation(index: int) -> void:
	if board.item_choice.stage != null:
		if not get_tree().paused and not board.item_choice.entering and index < sidebar_items.size():
			board.item_choice._select(sidebar_items[index], true)
			_refresh_item_shortcuts()
		return
	if index < recommendations.size():
		_inspect_hero(recommendations[index])

func _refresh_item_shortcuts() -> void:
	var choice = board.item_choice
	var catalog = preload("res://Scripts/ItemCatalog.gd")
	recommendations.clear()
	# Retain the displayed choices during the shared selection/exit animation.
	if not choice.offered.is_empty():
		sidebar_items.assign(choice.offered)
	for i in range(2):
		var icon := recommendation_icons[i]
		var button := recommendation_buttons[i]
		icon.position = Vector2(8, 6)
		icon.size = Vector2(178, 104)
		button.disabled = get_tree().paused or choice.entering or choice.offered.is_empty() or i >= sidebar_items.size()
		icon.modulate = Color(0.65, 0.65, 0.65) if button.disabled else Color.WHITE
		icon.texture = null
		choice_labels[i].text = ""
		button.tooltip_text = ""
		if i < sidebar_items.size():
			var id := sidebar_items[i]
			icon.texture = catalog.texture(id)
			choice_labels[i].text = "%s\n%s" % [catalog.NAMES[id], catalog.EFFECTS[id]]
			button.tooltip_text = "Pilih %s\n%s" % [catalog.NAMES[id], catalog.EFFECTS[id]]

func _toggle_chat() -> void:
	reactions.hide()
	chat_panel.visible = not chat_panel.visible

func _toggle_emotes() -> void:
	chat_panel.hide()
	reactions.visible = not reactions.visible


func _build_skill_popup() -> void:
	skill_panel = _panel(root, Rect2(650, 330, 620, 420))
	skill_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	skill_title = _label(skill_panel, "", Rect2(20, 30, 580, 60), 36, GOLD)
	_label(skill_panel, "Pilihan skill belum tersedia.", Rect2(30, 140, 560, 70), 26)
	_button(skill_panel, "Tutup", Rect2(160, 290, 300, 70), _close_menu)
	skill_panel.hide()

func _open_skill(title: String) -> void:
	reactions.hide()
	chat_panel.hide()
	modal.show()
	skill_title.text = title
	skill_panel.show()
	get_tree().paused = true
