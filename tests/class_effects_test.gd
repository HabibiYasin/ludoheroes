extends Node

var manager: WayPointsManager
var heroes: Array[Piece] = []

func _ready() -> void:
	call_deferred("_run")

func _hero(kind: String, hp: int, cell_index: int, ally: bool = false) -> Piece:
	var hero := Piece.new()
	hero.HeroClass = kind
	hero.Health = hp
	hero.MaxHealth = 10
	hero.Attack = 2
	hero.CurrentPlayerColor = GameManager.PlayerColor.Green if ally else GameManager.PlayerColor.Red
	hero.CurrentState = GameManager.PieceStateEnum.InWayPoint
	hero.CurrentPosition = cell_index
	hero.wayPointManager = manager
	if cell_index >= 0:
		hero.CurrentWayPoint = manager.green_path[cell_index]
		hero.CurrentWayPoint.myHoldings.append(hero)
	heroes.append(hero)
	return hero

func _clear() -> void:
	for cell in manager.green_path:
		cell.ClearMe()
	for hero in heroes:
		hero.free()
	heroes.clear()

func _run() -> void:
	manager = WayPointsManager.new()
	manager.main_path = Node2D.new()
	manager.add_child(manager.main_path)
	add_child(manager)
	for index in range(8):
		var cell := WayPoint.new()
		if index < 6:
			manager.main_path.add_child(cell)
		else:
			manager.add_child(cell)
		manager.green_path.append(cell)
	manager.green_path[7].IsThisHomePlace = true
	var cell := manager.green_path[2]
	var warrior := _hero("Warrior - mage", 3, -1, true)
	assert(warrior.HasClass("Warrior") and warrior.HasClass("Mage"))
	var same := _hero("Mage", 4, 2)
	var front := _hero("Mage", 5, 3)
	var back := _hero("Mage", 6, 1)
	var far := _hero("Mage", 9, 4)
	cell.SetPiece(warrior)
	assert(back.Health == 4 and same.Health == 4 and front.Health == 5 and far.Health == 9)
	cell.SetPiece(warrior)
	assert(back.Health == 4)
	cell.RemoveMyRef(warrior)
	cell.SetPiece(warrior)
	assert(front.Health == 3 and back.Health == 4)
	_clear()
	var ranger := _hero("Ranger", 3, -1, true)
	back = _hero("Mage", 10, 1)
	same = _hero("Mage", 4, 2)
	front = _hero("Mage", 5, 3)
	far = _hero("Tank", 7, 4)
	cell.SetPiece(ranger)
	assert(far.Health == 6 and back.Health == 10 and same.Health == 4 and front.Health == 5)
	cell.RemoveMyRef(ranger)
	ranger.Attack = 1
	cell.SetPiece(ranger)
	assert(far.Health == 6) # Tank can reduce indirect damage to zero.
	cell.RemoveMyRef(ranger)
	manager.green_path[4].isThisSafePlace = true
	ranger.Attack = 2
	cell.SetPiece(ranger)
	assert(front.Health == 3 and far.Health == 6)
	manager.green_path[4].isThisSafePlace = false
	_clear()
	var assassin := _hero("Assassin", 3, -1, true)
	var weak := _hero("Tank", 2, 2)
	var strong := _hero("Mage", 8, 2)
	var friend := _hero("Mage", 1, 2, true)
	var dead := _hero("Mage", 0, 2)
	cell.SetPiece(assassin)
	assert(weak.Health == weak.MaxHealth and weak.IsInLobby() and not cell.myHoldings.has(weak))
	assert(strong.Health == 8 and friend.Health == 1 and dead.Health == 0)
	_clear()
	var support := _hero("Support", 3, -1, true)
	friend = _hero("Mage", 8, 2, true)
	var friend2 := _hero("Tank", 9, 2, true)
	dead = _hero("Mage", 0, 2, true)
	strong = _hero("Tank", 9, 2)
	support.Attack = 0
	cell.SetPiece(support)
	assert(friend.Health == 9 and friend2.Health == 10 and dead.Health == 0 and strong.Health == 9 and support.Health == 3)
	cell.SetPiece(support)
	assert(friend.Health == 9)
	cell.HealFriends(support)
	assert(friend.Health == 10 and friend2.Health == 10)
	_clear()
	var runner := _hero("Runner", 3, 0, true)
	for die in range(1, 7):
		assert(runner.GetMoveDistance(die) == die + (1 if die <= 3 else 0))
	runner.CurrentPosition = 4
	assert(runner.GetMoveDistance(1) == 1) # Bonus would enter the colored lane.
	assert(runner.GetMoveDistance(2) == 2) # Raw die enters the lane.
	runner.CurrentPosition = 6
	assert(runner.GetMoveDistance(1) == 1 and runner.CanMoveWithDice(1, 8))
	assert(not runner.CanMoveWithDice(2, 8))
	runner.CurrentState = GameManager.PieceStateEnum.InLobby
	assert(runner.GetMoveDistance(1) == 1 and not runner.CanMoveWithDice(1, 8))
	assert(runner.CanMoveWithDice(6, 8))
	_clear()
	print("PASS: class ranges, single attack, hybrid class, highest/lowest HP, Tank mitigation, safe target, Support healing and Runner lane boundary")
	await _test_real_moves()
	get_tree().quit()

func _test_real_moves() -> void:
	Engine.time_scale = 30.0
	var game = load("res://Levels/Level_MainGamePlay.tscn").instantiate()
	game.get_node("CoreGamplay/Board/board_GamePlay").BotsEnabled = false
	game.get_node("CoreGamplay/PlayerIdleController").Enabled = false
	add_child(game)
	var board: BoardManager = game.get_node("CoreGamplay/Board/board_GamePlay")
	var support: Piece = board.piecesManager.GreenPieces.Pieces[3]
	var friend: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var friend2: Piece = board.piecesManager.GreenPieces.Pieces[1]
	var friend3: Piece = board.piecesManager.GreenPieces.Pieces[2]
	friend.SetCurrentPositionAndCheckKill(1)
	friend2.SetCurrentPositionAndCheckKill(2)
	friend3.SetCurrentPositionAndCheckKill(2)
	for hero in [friend, friend2, friend3]:
		hero.TakeDamage(mini(2, hero.Health - 1))
	var hp := [friend.Health, friend2.Health, friend3.Health]
	support.SetCurrentPositionAndCheckKill(0)
	board._on_dice_root_on_dice_rolled([2, 4])
	await board._on_player_select_piece(support)
	assert(friend.Health == hp[0] + 1 and friend2.Health == hp[1] + 1 and friend3.Health == hp[2] + 1)
	assert(support.CurrentPosition == 2 and board.remainingDice == [0, 4])
	for hero in [support, friend, friend2, friend3]:
		hero.SendBackToLobby()
	var runner: Piece = board.piecesManager.BluePieces.Pieces[3]
	while board.currentPlayerColor != runner.CurrentPlayerColor:
		board.UpdatePlayerTurn()
	runner.SetCurrentPositionAndCheckKill(0)
	board._on_dice_root_on_dice_rolled([2, 4])
	await board._on_player_select_piece(runner)
	assert(runner.CurrentPosition == 3 and board.remainingDice == [0, 4])
	print("PASS: real Support pass-through + destination heals exactly once; Runner moves +1 and consumes original die")
	runner.SendBackToLobby()
	for color in range(4):
		var path := board.way_points.GetPath(color)
		var lane_start := 0
		while path[lane_start].get_parent() == board.way_points.main_path:
			lane_start += 1
		var probe := Piece.new()
		probe.HeroClass = "Runner"
		probe.CurrentPlayerColor = color
		probe.CurrentState = GameManager.PieceStateEnum.InWayPoint
		probe.wayPointManager = board.way_points
		probe.CurrentPosition = lane_start - 3
		assert(probe.GetMoveDistance(1) == 2)
		probe.CurrentPosition = lane_start - 2
		assert(probe.GetMoveDistance(1) == 1)
		probe.CurrentPosition = lane_start - 1
		assert(probe.GetMoveDistance(1) == 1)
		probe.CurrentPosition = lane_start
		assert(probe.GetMoveDistance(1) == 1)
		probe.free()
	# A ranged lethal hit must remove the defender from its own cell and
	# finish both the capture wait and the animation before the next die.
	var ranger: Piece = board.piecesManager.GreenPieces.Pieces[0]
	var tank: Piece = board.piecesManager.RedPieces.Pieces[2]
	var victim_cell := board.way_points.green_path[3]
	tank.CurrentWayPoint = victim_cell
	tank.CurrentState = GameManager.PieceStateEnum.InWayPoint
	tank.CurrentPosition = board.way_points.red_path.find(victim_cell)
	victim_cell.SetPiece(tank)
	tank.Health = 2
	ranger.SetCurrentPositionAndCheckKill(0)
	while board.currentPlayerColor != ranger.CurrentPlayerColor:
		board.UpdatePlayerTurn()
	board._on_dice_root_on_dice_rolled([1, 4])
	await board._on_player_select_piece(ranger)
	assert(tank.Health == tank.MaxHealth and tank.IsInLobby() and tank.CurrentWayPoint == null)
	assert(not victim_cell.myHoldings.has(tank))
	assert(ranger.CurrentPosition == 1 and board.remainingDice == [0, 4])
	assert(board.attack_presentation.pending.is_empty() and board.attack_presentation.stage == null)
	# Check the displayed amount before resolving a nonlethal ranged hit.
	tank.SetCurrentPositionAndCheckKill(board.way_points.red_path.find(victim_cell))
	ranger.CurrentWayPoint.RemoveMyRef(ranger)
	ranger.SetCurrentPositionAndCheckKill(1)
	assert(tank.Health == 2)
	assert(board.attack_presentation.pending.size() == 1)
	assert(board.attack_presentation.pending[0].damage == 2)
	await board._wait_for_kill_if_needed()
	print("PASS: all four colored-lane boundaries, ranged Tank kill cleanup, next die and actual damage presentation")
	game.queue_free()
	await get_tree().process_frame
