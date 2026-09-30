extends Node

var game: Node
var board: BoardManager
var heroes: Array[Piece] = []
var caster: Piece

func _ready() -> void:
	call_deferred("_run")

func _place(hero: Piece, number: int) -> void:
	if hero.CurrentWayPoint != null:
		hero.CurrentWayPoint.RemoveMyRef(hero)
	var cell: WayPoint = board.way_points.main_path.get_node(str(number))
	hero.CurrentPosition = board.way_points.GetPath(hero.CurrentPlayerColor).find(cell)
	hero.CurrentWayPoint = cell
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.position = cell.position
	cell.myHoldings.append(hero)

func _reset(id: String) -> void:
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	for hero in heroes:
		hero.SendBackToLobby()
		hero.SkillCooldown = 0
		hero.SkillCooldownAwaitingFirstTurn = false
		hero.MaxHealth = 20
		hero.Health = 20
		hero.SkillDamage = 0
		hero.PhysicalDefense = 0
		hero.MagicalDefense = 0
		hero.Items = {0: 1, 1: 1}
		if hero.HeroId == id:
			caster = hero
	board.currentPlayerColor = caster.CurrentPlayerColor
	board.currentPlayerTurnIndex = int(caster.CurrentPlayerColor)
	_place(caster, 19)
	caster.BeginStatusTurn()

func _targets(numbers: Array, ally: bool = false) -> Array[Piece]:
	var result: Array[Piece] = []
	for hero in heroes:
		if hero == caster or (hero.CurrentPlayerColor == caster.CurrentPlayerColor) != ally:
			continue
		_place(hero, numbers[result.size()])
		result.append(hero)
		if result.size() == numbers.size():
			break
	return result

func _cast(die: int, selected: Array[Piece] = []) -> void:
	board._on_dice_root_on_dice_rolled([die, 6])
	assert(board.skills.can_use(caster, die))
	var previous_position := caster.CurrentPosition
	var skill: Dictionary = board.skills.definition(caster)
	var scenes: Array[String] = []
	var track_scene := func(node: Node):
		if node.name in ["SkillAnnouncement", "SkillBattle"]:
			scenes.append(String(node.name))
	board.attack_presentation.child_entered_tree.connect(track_scene)
	assert(await board.skills.cast(caster, 0, selected))
	board.attack_presentation.child_entered_tree.disconnect(track_scene)
	assert(scenes == (["SkillAnnouncement", "SkillBattle"] if skill.effect == "damage" else ["SkillAnnouncement"]))
	assert(board.remainingDice == [0, 6])
	assert(caster.SkillCooldown == skill.cooldown)
	assert(not board.skills.can_use(caster, die))
	if skill.effect not in ["move", "shortcut"]:
		assert(caster.CurrentPosition == previous_position)
	assert(board.attack_presentation.stage == null)

func _run() -> void:
	Engine.time_scale = 30.0
	game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	board = game.get_node("CoreGamplay/Board/board_GamePlay")
	for color in range(4):
		heroes.append_array(board.piecesManager.GetPieceGroupBasedOnType(color).Pieces)
	assert(preload("res://Scripts/SkillCatalog.gd").SKILLS.size() == 16)
	_reset("Brilia")
	var targets := _targets([18, 20, 22])
	await _cast(1)
	assert(targets[0].Health == 18 and targets[1].Health == 18 and targets[2].Health == 20)
	caster.EndStatusTurn()
	assert(caster.SkillCooldown == 2)
	caster.BeginStatusTurn()
	assert(caster.SkillCooldown == 2 and not board.skills.can_use(caster, 1))
	caster.EndStatusTurn()
	caster.BeginStatusTurn()
	assert(caster.SkillCooldown == 1 and not board.skills.can_use(caster, 1))
	caster.EndStatusTurn()
	caster.BeginStatusTurn()
	assert(caster.SkillCooldown == 0 and board.skills.can_use(caster, 1))
	_reset("Suki")
	targets = _targets([18, 20])
	targets[1].Health = 5
	await _cast(3)
	assert(targets[0].Health == 20 and targets[1].Health == 3)
	_reset("Mordian")
	await _cast(2)
	assert(caster.HasStatus("Shield"))
	caster.EndStatusTurn()
	assert(caster.HasStatus("Shield") and caster.SkillCooldown == 1)
	caster.TakeDamage(999)
	assert(caster.Health == 20 and not caster.HasStatus("Shield"))
	caster.BeginStatusTurn()
	assert(caster.SkillCooldown == 1 and not board.skills.can_use(caster, 2))
	caster.EndStatusTurn()
	assert(caster.SkillCooldown == 1)
	caster.BeginStatusTurn()
	assert(caster.SkillCooldown == 0 and board.skills.can_use(caster, 2))
	_reset("Anata")
	targets = _targets([18, 20], true)
	await _cast(6)
	assert(int(targets[0].HasStatus("Shield")) + int(targets[1].HasStatus("Shield")) == 1)
	var eligible: Array[Piece] = board.skills.candidates(caster)
	assert(eligible.size() == 1 and eligible[0] != caster and not eligible[0].HasStatus("Shield"))
	for target in targets:
		target.ApplyStatus("Shield")
	assert(board.skills.candidates(caster) == [caster])
	caster.BeginStatusTurn()
	caster.EndStatusTurn()
	caster.BeginStatusTurn()
	await _cast(6)
	assert(caster.HasStatus("Shield") and board.skills.candidates(caster).is_empty())
	print("PASS: Astherion skills, self range, lowest-HP/automatic ally targeting, die consumption and cooldown")

	_reset("Kaelgrave")
	targets = _targets([20, 22, 23, 18])
	await _cast(4)
	assert(targets[0].HasStatus("Stun") and targets[1].HasStatus("Stun"))
	assert(not targets[2].HasStatus("Stun") and not targets[3].HasStatus("Stun"))
	assert(targets[0].Status.effects["Stun"].turns == 1)
	_reset("Nyssara")
	await _cast(2)
	assert(caster.HasStatus("Hidden"))
	targets = _targets([20])
	assert(caster.CurrentWayPoint._find_capturable_opponent(targets[0]) == null)
	var power := caster.Attack
	caster.SetCurrentPositionAndCheckKill(board.way_points.GetPath(caster.CurrentPlayerColor).find(targets[0].CurrentWayPoint))
	assert(targets[0].Health == 20 - power * 2 and not caster.HasStatus("Hidden"))
	await board.attack_presentation.play_pending()
	_reset("Nyssara")
	await _cast(2)
	targets = _targets([20])
	targets[0].ApplyStatus("Nature Shield", 4)
	power = caster.Attack
	caster.SetCurrentPositionAndCheckKill(board.way_points.GetPath(caster.CurrentPlayerColor).find(targets[0].CurrentWayPoint))
	assert(targets[0].Health == 20 - maxi(0, power * 2 - 4))
	assert(not targets[0].HasStatus("Nature Shield"))
	assert(not caster.HasStatus("Stun"))
	await board.attack_presentation.play_pending()
	_reset("Vilmira")
	targets = _targets([20])
	await _cast(6)
	assert(caster.HeroClass == "Mage" and targets[0].HasStatus("Bleed") and not targets[0].HasStatus("Cursed"))
	for distance in range(1, 7):
		targets[0].Health = 20
		targets[0].ApplyMovementStatuses(distance)
		assert(targets[0].Health == (19 if distance <= 3 else 18))
	targets[0].EndStatusTurn()
	assert(targets[0].HasStatus("Bleed"))
	targets[0].BeginStatusTurn()
	assert(targets[0].HasStatus("Bleed"))
	targets[0].BeginStatusTurn()
	assert(not targets[0].HasStatus("Bleed"))
	_reset("Zyrella")
	var initial := caster.CurrentPosition
	await _cast(1)
	assert(caster.CurrentPosition == initial + 3)
	print("PASS: Nekravia stun, Hidden/reveal/double attack, Blood Curse Bleed formula and dash")

	_reset("Silvy")
	targets = _targets([20, 22, 23, 18])
	await _cast(3)
	for index in range(3):
		assert(targets[index].Health == 19)
	assert(targets[3].Health == 20)
	_reset("Garruk")
	await _cast(2)
	targets = _targets([20])
	caster.TakeDamage(3, true, Piece.DamageType.PHYSICAL, targets[0])
	assert(caster.Health == 19 and targets[0].Health == 20 and not targets[0].HasStatus("Stun"))
	assert(not caster.HasStatus("Nature Shield"))
	_reset("Pirunrun")
	targets = _targets([18, 20, 22])
	await _cast(2)
	var hit := 0
	for target in targets:
		hit += int(target.Health == 18)
	assert(hit == 2)
	_reset("Mycellia")
	targets = _targets([20, 23], true)
	await _cast(4)
	assert(targets[0].HasStatus("Nature Shield") and not targets[1].HasStatus("Nature Shield"))
	assert(targets[0].Status.effects["Nature Shield"].charges == 4)
	caster.EndStatusTurn()
	assert(targets[0].HasStatus("Nature Shield"))
	targets[0].EndStatusTurn()
	assert(targets[0].HasStatus("Nature Shield"))
	targets[0].BeginStatusTurn()
	assert(not targets[0].HasStatus("Nature Shield"))
	print("PASS: Thornvale target caps, Nature Shield absorption and one-turn expiry, random damage, nearest ally")

	_reset("Skalfin")
	targets = _targets([20])
	targets[0].ApplyStatus("Shield", 2)
	await _cast(2)
	assert(targets[0].Health in [16, 17, 18] and targets[0].HasStatus("Shield"))
	_reset("Octavus")
	targets = _targets([18, 20, 22, 23, 17])
	await _cast(6)
	hit = 0
	for target in targets:
		hit += int(target.Health == 18)
	assert(hit == 4)
	_reset("Velissa")
	targets = _targets([20])
	await _cast(2)
	assert(targets[0].HasStatus("Drown"))
	for turn in range(3):
		targets[0].BeginStatusTurn()
		targets[0].EndStatusTurn()
	assert(targets[0].Health == 18 and not targets[0].HasStatus("Drown"))
	print("PASS: Twin Tides separate hits/Shield, four-target barrage, three-turn Drown")
	_reset("Kragor")
	var kragor_path := board.way_points.GetPath(caster.CurrentPlayerColor)
	var found := false
	for index in range(kragor_path.size() - 1):
		if caster.CurrentWayPoint != null:
			caster.CurrentWayPoint.RemoveMyRef(caster)
		caster.CurrentPosition = index
		caster.CurrentWayPoint = kragor_path[index]
		caster.position = kragor_path[index].position
		caster.CurrentWayPoint.myHoldings.append(caster)
		var shortcut: Array[int] = board.skills.movement_path(caster)
		if shortcut.is_empty():
			continue
		var destination: int = shortcut.back()
		assert(destination > index + 4)
		assert(is_equal_approx(kragor_path[destination].position.distance_to(caster.position), 4 * 1804.0 / 15.0))
		await _cast(4)
		assert(caster.CurrentPosition == destination)
		found = true
		break
	assert(found, "Kragor must have a valid straight corner shortcut")
	print("PASS: Reef Shortcut crosses a corner in a straight line of four tile widths")
	_reset("Brilia")
	targets = _targets([18, 20])
	for target in targets:
		target.Health = 1
	var kills := caster.MatchKills
	await _cast(1)
	assert(caster.MatchKills == kills + 2)
	assert(targets[0].IsInLobby() and targets[1].IsInLobby())
	_reset("Brilia")
	targets = _targets([20])
	caster.Health = 1
	targets[0].Health = 1
	targets[0].ApplyStatus("Nature Shield", 2)
	board._on_dice_root_on_dice_rolled([1, 6])
	assert(await board.skills.cast(caster, 0))
	assert(not caster.IsInLobby() and targets[0].IsInLobby() and board.remainingDice == [0, 6])
	assert(not caster.HasStatus("Stun") and targets[0].Status.effects.is_empty())
	print("PASS: multi-target defeat, kill attribution, skill bypass and continued dice")
	await _selection_and_guards()
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _selection_and_guards() -> void:
	_reset("Suki")
	var targets := _targets([18, 20])
	targets[1].Health = 5
	await _cast(4, [targets[0]])
	assert(targets[0].Health == 18 and targets[1].Health == 5)
	_reset("Silvy")
	targets = _targets([20, 22])
	board._on_dice_root_on_dice_rolled([2, 6])
	var duplicate_targets: Array[Piece] = [targets[0], targets[0]]
	assert(not await board.skills.cast(caster, 0, duplicate_targets))
	assert(board.remainingDice == [2, 6] and caster.SkillCooldown == 0)
	assert(not board.skills.can_use(caster, 1))
	_place(caster, 21)
	assert(not board.skills.can_use(caster, 2))
	_place(caster, 19)
	_place(targets[0], 21)
	assert(not board.skills.candidates(caster).has(targets[0]))
	_reset("Mordian")
	var path := board.way_points.GetPath(caster.CurrentPlayerColor)
	if caster.CurrentWayPoint != null:
		caster.CurrentWayPoint.RemoveMyRef(caster)
	caster.CurrentPosition = path.size() - 2
	caster.CurrentWayPoint = path[caster.CurrentPosition]
	caster.CurrentWayPoint.myHoldings.append(caster)
	caster.ApplyStatus("Frozen", 2)
	board._on_dice_root_on_dice_rolled([2, 3])
	assert(GameManager.GameCurrentState == GameManager.GameStateEnum.PlayerSelectPiece)
	assert(not caster.CanMoveWithDice(2, path.size()) and board.skills.can_use(caster, 2))
	var hud = game.get_child(game.get_child_count() - 1)
	hud._refresh_recommendations()
	assert(hud.skill_buttons[2].visible)
	var bot = game.get_node("CoreGamplay/BotController")
	var decision: Dictionary = bot.ChooseMove()
	assert(decision.get("skill", false) and decision.piece == caster)
	bot._play_move()
	while GameManager.GameCurrentState == GameManager.GameStateEnum.Null:
		await get_tree().process_frame
	assert(caster.HasStatus("Shield") and board.currentPlayerColor != caster.CurrentPlayerColor)
	print("PASS: manual target overrides, duplicate/invalid die rejection, safe tiles, skill-only legal turn and book availability")
