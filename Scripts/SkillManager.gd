extends Node

const Catalog = preload("res://Scripts/SkillCatalog.gd")
var board: BoardManager

func _ready() -> void:
	board = get_parent()

func definition(hero: Piece) -> Dictionary:
	return Catalog.get_skill(hero.HeroId)

func _relative_cell(hero: Piece, offset: int) -> WayPoint:
	var path := board.way_points.GetPath(hero.CurrentPlayerColor)
	var index := path.find(hero.CurrentWayPoint)
	if index < 0:
		return null
	if index + offset >= 0:
		return board.way_points.GetWayPoint(index + offset, hero.CurrentPlayerColor)
	# Crossing behind a start square follows the shared ring, never the base.
	if hero.CurrentWayPoint.get_parent() == board.way_points.main_path:
		return board.way_points.main_path.get_node_or_null(str(posmod(int(hero.CurrentWayPoint.name) + offset, 52))) as WayPoint
	return null

func candidates(hero: Piece) -> Array[Piece]:
	var result: Array[Piece] = []
	var data := definition(hero)
	if data.is_empty() or hero.IsInLobby() or hero.IsInHome or hero.Health <= 0 or hero.CurrentWayPoint == null:
		return result
	if data.team == "self":
		if data.effect == "shield" and hero.HasStatus("Shield"):
			return result
		if data.effect == "ambush" and hero.HasStatus("Hidden"):
			return result
		result.append(hero)
		return result
	if data.team == "enemy" and (hero.CurrentWayPoint.isThisSafePlace or hero.CurrentWayPoint.IsThisHomePlace):
		return result
	var distances := {}
	for offset in range(-int(data.behind), int(data.front) + 1):
		var cell := _relative_cell(hero, offset)
		if cell == null or (data.team == "enemy" and (cell.isThisSafePlace or cell.IsThisHomePlace)):
			continue
		for target: Piece in cell.myHoldings:
			if target == hero or target.Health <= 0 or target.IsInLobby() or target.IsInHome or result.has(target):
				continue
			if (target.CurrentPlayerColor == hero.CurrentPlayerColor) != (data.team == "ally"):
				continue
			if data.team == "enemy" and target.HasStatus("Hidden"):
				continue
			var status: String = {"shield": "Shield", "stun": "Stun", "bleed": "Bleed"}.get(data.effect, "")
			if not status.is_empty() and target.HasStatus(status):
				continue
			result.append(target)
			distances[target] = absi(offset)
	result.sort_custom(func(a: Piece, b: Piece): return distances[a] < distances[b])
	if result.is_empty() and data.team == "ally" and data.effect == "shield" and not hero.HasStatus("Shield"):
		result.append(hero)
	return result

func can_use(hero: Piece, dice_value: int) -> bool:
	var data := definition(hero)
	if data.is_empty() or hero.CurrentPlayerColor != board.currentPlayerColor or hero.SkillCooldown > 0 or hero.HasStatus("Stun"):
		return false
	if not data.dice.has(dice_value) or candidates(hero).is_empty():
		return false
	if data.effect in ["move", "shortcut"]:
		return not movement_path(hero).is_empty()
	return true

func die_for(hero: Piece) -> int:
	var order: Array[int] = [board.selectedDiceIndex]
	for index in range(board.remainingDice.size()):
		if not order.has(index):
			order.append(index)
	for index in order:
		if index >= 0 and index < board.remainingDice.size() and can_use(hero, board.remainingDice[index]):
			return index
	return -1

func has_action(dice_value: int) -> bool:
	for hero: Piece in board.piecesManager.GetPieceGroupBasedOnType(board.currentPlayerColor).Pieces:
		if can_use(hero, dice_value):
			return true
	return false

func movement_path(hero: Piece) -> Array[int]:
	var route: Array[int] = []
	var data := definition(hero)
	if hero.HasStatus("Stun") or hero.HasStatus("Frozen") or hero.IsInLobby():
		return route
	var count := int(data.get("distance", 0))
	if data.effect == "shortcut":
		var path := board.way_points.GetPath(hero.CurrentPlayerColor)
		var direction := Vector2.ZERO
		# Continue the last straight heading, including the diagonal corner step.
		for index in range(hero.CurrentPosition - 1, maxi(-1, hero.CurrentPosition - 4), -1):
			var delta := path[index + 1].position - path[index].position
			if absf(delta.x) < 1.0 or absf(delta.y) < 1.0:
				direction = delta.normalized()
				break
		if direction == Vector2.ZERO and hero.CurrentPosition == 0:
			direction = (path[1].position - path[0].position).normalized()
		var landing := hero.CurrentWayPoint.position + direction * (1804.0 / 15.0) * count
		for index in range(hero.CurrentPosition + count + 1, path.size()):
			if path[index].position.distance_to(landing) < 1.0:
				route.append(index)
				break
		return route
	if count <= 0 or hero.CurrentPosition + count >= board.GetPathCount(hero.CurrentPlayerColor):
		return route
	for step in range(1, count + 1):
		route.append(hero.CurrentPosition + step)
	return route

func choose_targets(hero: Piece) -> Array[Piece]:
	var result := candidates(hero)
	var data := definition(hero)
	match data.get("selection", "nearest"):
		"lowest": result.sort_custom(func(a: Piece, b: Piece): return a.Health < b.Health)
		"random": result.shuffle()
	if result.size() > int(data.targets):
		result.resize(int(data.targets))
	return result

func cast(hero: Piece, die_index: int, chosen: Array[Piece] = [], manual: bool = false) -> bool:
	if get_tree().paused or GameManager.GameCurrentState != GameManager.GameStateEnum.PlayerSelectPiece:
		return false
	if die_index < 0 or die_index >= board.remainingDice.size() or not can_use(hero, board.remainingDice[die_index]):
		return false
	var data := definition(hero)
	var targets := choose_targets(hero) if chosen.is_empty() else chosen.duplicate()
	var available := candidates(hero)
	if targets.is_empty() or targets.size() > int(data.targets):
		return false
	var unique := {}
	for target: Piece in targets:
		if not available.has(target) or unique.has(target):
			return false
		unique[target] = true
	# Lock input before emitting UI updates. Invalid requests consume nothing.
	GameManager.UpdateGameCurrentState(GameManager.GameStateEnum.Null)
	board.StopPieceAnimation()
	board.selectedDiceIndex = die_index
	board.currentDiceValue = board.remainingDice[die_index]
	if manual:
		board.ManualAction.emit()
	board.HeroMoveStarted.emit(hero)
	hero.SkillCooldown = int(data.cooldown)
	hero.SkillCooldownAwaitingFirstTurn = hero.SkillCooldown > 0
	hero.StatsChanged.emit()
	await board.attack_presentation.show_skill_name(hero, data.name)
	if data.effect in ["move", "shortcut"]:
		await board.MovePieces(board.currentDiceValue, hero, false, movement_path(hero), data.effect == "shortcut", int(data.distance))
		return true
	var records: Array[Dictionary] = []
	var defeated: Array[Piece] = []
	for target: Piece in targets:
		if hero.Health <= 0:
			break
		var damage := 0
		var health_before := target.Health
		match data.effect:
			"damage":
				for hit in range(int(data.get("hits", 1))):
					if target.Health <= 0 or hero.Health <= 0:
						break
					var amount := int(data.damage) + hero.SkillDamage
					if randf() < float(data.get("bonus_chance", 0.0)):
						amount += 1
					var kind := Piece.DamageType.MAGICAL if data.get("magical", false) else Piece.DamageType.PHYSICAL
					target.TakeDamage(amount, true, kind, hero, true)
				damage = health_before - target.Health
			"shield": target.ApplyStatus("Shield")
			"stun": target.ApplyStatus("Stun", int(data.duration))
			"ambush": target.ApplyStatus("Hidden", 1)
			"bleed":
				if target.ApplyStatus("Bleed", int(data.duration)):
					target.Status.effects["Bleed"]["blood_curse"] = true
			"drown": target.ApplyStatus("Drown", int(data.duration))
			"nature": target.ApplyStatus("Nature Shield", int(data.duration))
			"thornhide":
				target.ApplyStatus("Nature Shield", int(data.duration))
		var territory := board.way_points.GetTerritoryFaction(target.CurrentWayPoint) if target.CurrentWayPoint != null else ""
		records.append({"texture": target.PieceSprite.texture, "damage": damage, "territory": territory, "name": target.HeroId, "effect": {"stun": "Stun", "bleed": "Bleed", "drown": "Drown"}.get(data.effect, "0")})
		if target.Health <= 0:
			hero.RecordKill()
			defeated.append(target)
		if hero.Health <= 0 and not defeated.has(hero):
			target.RecordKill()
			defeated.append(hero)
	if data.effect == "damage":
		await board.attack_presentation.play_skill(hero, data.name, records)
	for fallen: Piece in defeated:
		fallen.SendBackToLobby()
	board._complete_die()
	return true
