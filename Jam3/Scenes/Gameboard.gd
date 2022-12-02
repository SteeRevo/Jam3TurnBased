class_name GameBoard
extends YSort

enum {PLAYER, ENEMY}

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

export var grid: Resource = preload("res://Grid.tres")
onready var _fight_scene: Resource = preload("res://Scenes/CombatSceneLayer.tscn")

var attack_occured = false


onready var _unit_overlay: Overlay = $Overlay

var rng = RandomNumberGenerator.new()

var _units := {}

var _active_unit: Unit

var _walkable_cells := []

# is it the player's turn?
var _current_turn = PLAYER

var _selecting_opponent = false

enum TurnPhases {MOVEMENT_SELECTION, ATTACK_SELECTION}

# The current phase of the turn.
var _turn_phase = TurnPhases.MOVEMENT_SELECTION

var unit_teams = [{}, {}]

const MAX_VALUE = 9999999

var _movement_costs

var enemy_ui_on = false

var instance

onready var _unit_path: UnitPath = $UnitPath
onready var _map: TileMap = $TileMap
onready var _cursor: Cursor = $Cursor
onready var _enemy_camera: Camera2D = $EnemyCam
onready var _UI: Control = $CanvasLayer/UnitUi
onready var _UI_health_bar: TextureProgress = $CanvasLayer/UnitUi/Healthbar
onready var _UI_health_label: Label = $CanvasLayer/UnitUi/Label

onready var _enemy_UI: Control = $CanvasLayer/EnemyUnitUi
onready var _enemy_UI_health_bar: TextureProgress = $CanvasLayer/EnemyUnitUi/Healthbar
onready var _enemy_UI_health_label: Label = $CanvasLayer/EnemyUnitUi/Label

onready var _ai_brain = $AIBrain

signal choose_opponent
signal action_completed # Mainly used to indicate when the AIBrain can calculate its next action
signal enemy_turn_finished
signal combat_ended

func _ready():
	_movement_costs = _map.get_movement_costs(grid)
	_reinitialize()
	rng.randomize()

func is_occupied(cell: Vector2):
	return true if _units.has(cell) else false
	
func _reinitialize():
	$Cursor/Camera2D.current = true
	_units.clear()
	
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		if unit.team == PLAYER:
			unit_teams[PLAYER][unit.cell] = unit
		if unit.team == ENEMY:
			unit_teams[ENEMY][unit.cell] = unit
			unit.finished = true
			
		_units[unit.cell] = unit
		
func get_walkable_cells(unit: Unit):
	return dijkstra(unit.cell, unit.move_range)
	
func _check_turn_end():
	for unit in _units.values():
		if not unit.finished:
			print("Unit not finished: ", unit)
			return
	# flips the turn between 1 and 0
	_set_turn(1 - _current_turn)
		
	
func _set_turn(turn):
	_current_turn = turn
	print("turn: %s" % _current_turn)
	# reset all units of the next player to ready
	_enemy_camera.current = false
	$Cursor/Camera2D.current = true
	for unit in unit_teams[_current_turn].values():
		unit.finished = false
	
	# maybe send some signal to enemy AI or player?
	# temp turn-passing code:
	print("NUMBER OF ENEMIES: ", len(unit_teams[ENEMY]))
	if _current_turn == ENEMY and len(unit_teams[ENEMY]) != 0:
		execute_enemy_turn()
		yield(self, "enemy_turn_finished")
		_set_turn(PLAYER)
	elif len(unit_teams[ENEMY]) == 0:
		get_tree().change_scene("res://Scenes/VictoryScene.tscn")
	
func flood_fill(cell: Vector2, max_distance: int) -> Array:
	var array := []
	var stack := [cell]
	while not stack.empty():
		var current = stack.pop_back()

		if not grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			if is_occupied(coordinates):
				continue
			if coordinates in array:
				continue

			stack.append(coordinates)
	return array

func dijkstra(cell: Vector2, max_distance: int) -> Array:
	var movable_cells = [cell]
	var visited = []
	var distances = []
	var previous = []
	
	for y in range(grid.size.y):
		visited.append([])
		distances.append([])
		previous.append([])
		for x in range(grid.size.x):
			visited[y].append(false)
			distances[y].append(MAX_VALUE)
			previous[y].append(null)
	
	var queue = PriorityQueue.new()
	queue.push(cell, 0)
	distances[cell.y][cell.x] = 0
	
	var tile_cost
	var distance_to_node
	
	while not queue.is_empty():
		var current = queue.pop()
		visited[current.value.y][current.value.x] = true
		
		for direction in DIRECTIONS:
			var coordinates = current.value + direction
			if grid.is_within_bounds(coordinates) and !is_occupied(coordinates):
				if visited[coordinates.y][coordinates.x]:
					continue
				
				else:
					tile_cost = _movement_costs[coordinates.y][coordinates.x]
					distance_to_node = current.priority + tile_cost
					
					
				if distance_to_node <= max_distance:
					previous[coordinates.y][coordinates.x] = current.value
					movable_cells.append(coordinates)
					queue.push(coordinates, distance_to_node)
		
	
	return movable_cells

func _select_unit(cell: Vector2) -> void:
	if _units.has(cell) and _units[cell].team == ENEMY and _current_turn != ENEMY:
		enemy_ui_on = true
		_init_enemy_UI(cell)
		return
		
	if not _units.has(cell) or _units[cell].finished or _units[cell].team != _current_turn:
		return
	
	_enemy_camera.current = false
	_active_unit = _units[cell]
	_active_unit.is_selected = true
	_walkable_cells = get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_init_UI()
	_unit_path.initialize(_walkable_cells)
	_turn_phase = TurnPhases.MOVEMENT_SELECTION
	print("Active Unit: ", _active_unit)


func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()
	_UI.visible = false

func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


func _move_active_unit(new_cell: Vector2) -> void:
	if (_active_unit.team == PLAYER and ((is_occupied(new_cell) and new_cell != _active_unit.cell) or not new_cell in _walkable_cells)):
		return

	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	
	# Update unit_teams
	unit_teams[_active_unit.team].erase(_active_unit.cell)
	unit_teams[_active_unit.team][new_cell] = _active_unit
	
	_deselect_active_unit()
	if (new_cell != _active_unit.cell):
		_active_unit.walk_along(_unit_path.current_path)
		print("WAITING FOR WALK???")
		print("CURRENT ACTIVE UNIT: ", _active_unit)
		yield(_active_unit, "walk_finished")
		print("WALK SIGNAL RECEIVED")
	# process combat choices
	# yield again and wait for opponent choice (if any)
	var avail_opponents = get_adjacent_units(_active_unit.cell, 1 - _current_turn)
	if avail_opponents.size() > 0:
		_turn_phase = TurnPhases.ATTACK_SELECTION
		_unit_overlay.draw(avail_opponents.keys())
		_selecting_opponent = true

		# Wait for player choice of unit to attack
		print("CURRENT TURN: ", _current_turn)
		if (_current_turn == PLAYER):
			var opp = yield(self, "choose_opponent")
			while true:
				if opp in avail_opponents or opp == null:
					print("chose %s" % opp)
					break
				else:
					print("choose an adjacent enemy unit to fight!")
					opp = yield(self, "choose_opponent")
			_selecting_opponent = false
			_unit_overlay.clear()
			if (opp == null):
				print("no fight")
			else:
				print(_active_unit, " fights ", avail_opponents[opp])
				attack(_active_unit, avail_opponents[opp])
		
		# Have AIBrain select a player unit to fight
		elif (_current_turn == ENEMY):
			print("EMITTING SIGNAL FOR END MOVEMENT")
			emit_signal("action_completed")
			print("EMITTED SIGNAL FOR END MOVEMENT")

	# for now we say the unit is done
	_active_unit.finished = true
	_clear_active_unit()

	if (_current_turn == ENEMY):
		print("EMITTING SIGNAL FOR END ATTACK AND/OR MOVEMENT")
		emit_signal("action_completed")

	if len(unit_teams[ENEMY]) == 0:
		
		get_tree().change_scene("res://Scenes/VictoryScene.tscn")
	if len(unit_teams[PLAYER]) == 0:
		
		get_tree().change_scene("res://Scenes/DefeatScene.tscn")
	_check_turn_end()
	
# A attacks B
func attack(unitA: Unit, unitB: Unit):
	# instance fight scene
	instance = _fight_scene.instance()
	add_child(instance)
	
	var roll = rng.randf()
	if roll < unitA.hit_rate:
		var prev_health = unitB.health
		# not factoring in evasion for now
		print("unit A hits for ", unitA.attack)
		# defense cannot block an entire attack with this formula: https://rpg.fandom.com/wiki/Damage_Formula
		unitB.health -= unitA.attack
		print("unit B health: ", unitB.health)
		instance.playHit(1.0, _current_turn, unitA, unitB, prev_health, unitB.health)
		yield(get_tree().create_timer(1), "timeout")
		if unitB.health <= 0:
			print("unit B is defeated!")
			
			_remove_unit(unitB)
			if len(unit_teams[ENEMY]) == 0:
				get_tree().change_scene("res://Scenes/VictoryScene.tscn")
				SceneTracker.victory_occured = true
			print("remain enemy ", len(unit_teams[ENEMY]))
			
	else:
		instance.playMiss(1.0, _current_turn, unitA, unitB)
	
		
		print("unit A misses")
	yield(get_tree().create_timer(2), "timeout")
	emit_signal("combat_ended")	
	instance.queue_free()

func _on_Cursor_moved(new_cell: Vector2) -> void:
	if (_current_turn != PLAYER): return
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)


func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	#replace this with an FSM?
	if (_current_turn != PLAYER): return
	if not _active_unit:
		_select_unit(cell)
		_cursor.play_select_sound()
	elif _active_unit.is_selected:
		_move_active_unit(cell)
	elif _selecting_opponent:
		emit_signal("choose_opponent", cell)
		

func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		if _active_unit.is_selected:
			_cursor.play_deselect_sound()
			_deselect_active_unit()
			_clear_active_unit()
		# press esc while choosing opponents to choose no opponent (not fight)
	
		if _selecting_opponent:
			_cursor.play_deselect_sound()
			emit_signal("choose_opponent", null)
	if enemy_ui_on and event.is_action_pressed("ui_cancel"):
		print("enemy ui off")
		_cursor.play_deselect_sound()
		_enemy_UI.visible = false

#
# AI-Related Methods
#

func execute_enemy_turn():
	# i Imagine we'll have the actual AI activate on some signal, then it sends
	# a signal back on finishing or something
	print("enemy makes some plays...")
	_cursor.not_movable = true
	
	#$Cursor/Camera2D.current = false
	#_enemy_camera.current = true
	print("Attack occured?: ", attack_occured)
	
	yield(get_tree().create_timer(3.5), "timeout")
	

	# Failsafe in case this method is called with no enemy units remaining
	if (unit_teams[ENEMY].values().size() == 0):
		printerr("No enemy units remain!")
		_check_turn_end()
		return

	# Select an enemy unit
	_select_unit(unit_teams[ENEMY].values()[0].cell)

	# Keep passing the current game state to AIBrain until enemy turn is over
	while (true):
		# The AIBrain may return something here, but it will mainly use signals for its actions
		var ai_brain_return_value = _ai_brain.calculate_action(get_current_game_state())
		#call_deferred("_ai_brain.calculate_action(get_current_game_state())")
		# Yield to allow animations to finish
		print("WAITING FOR ACTION")
		yield(self, "action_completed")
		print("ACTION COMPLETED")

		# Current unit still in play or different unit was selected; keep passing game state to
		# AIBrain
		if (_active_unit != null and not _active_unit.finished):
			continue

		# If at least one enemy unit can still act and one wasn't selected by AIBrain, select the
		# next available one
		for unit in unit_teams[ENEMY].values():
			
			if (not unit.finished):
				yield(self, "combat_ended")
				_select_unit(unit.cell)
				break
		if (_active_unit == null):
			break

	# Player's turn now
	_cursor.not_movable = false
	_check_turn_end()
	emit_signal("enemy_turn_finished") # It works without this line for some reason

func get_adjacent_units(cell: Vector2, team: int) -> Dictionary:
	# get the units that are adjacent to the given cell and are on the given 
	# team
	var adj = {};
	# this currently counts diagonals as adjacent. Not sure if that is desired but it can be changed
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0: continue
			var loc = Vector2(cell.x + i, cell.y + j)
			if _units.has(loc) and _units[loc].team == team:
				adj[loc] = _units[loc]
	return adj
	
#
# remove all references to it in the board, then remove the node
func _remove_unit(unit: Unit):
	_units.erase(unit.cell)
	unit_teams[unit.team].erase(unit.cell)
	unit.queue_free()
	print("removed unit")
	return

# Returns the current state of the game as a dictionary
func get_current_game_state():
	var game_state = {
		# Index of the currently active unit in the unit_properties array
		"active_unit_index": -1,
		"current_turn": _current_turn,
		# Holds the index in the unit_properties array of the first enemy unit properties dictionary
		"enemy_start_index": unit_teams[0].size(),
		# Array of dictionaries that will contain relevant properties of units
		# All of the player unit properties come first, followed by all enemy unit properties
		"unit_properties": [],
		# The current phase of the turn
		"turn_phase": _turn_phase,
		# A reference to the tilemap. This should not be written to by AIBrain.
		"tilemap": _map,
		# A reference to the tilemap's grid. This should not be written to by AIBrain.
		"grid": grid,
	}

	for team in unit_teams:
		for unit in team.values():
			if (_active_unit == unit):
				game_state["active_unit_index"] = game_state["unit_properties"].size()

			game_state["unit_properties"].push_back({
				"cell": unit.cell,
				"move_range": unit.move_range,
				"health": unit.health,
				"max_health": unit.max_health,
				"attack": unit.attack,
				"defense": unit.defense,
				"hit_rate": unit.hit_rate,
				"evasion": unit.evasion,
				"is_queen": unit == get_node_or_null("./Unit") # TODO: Change this if needed
			})

	return game_state

# Method used by the AI to change the currently selected unit to a different one.
# cell is the cell of the unit to be selected
# TODO: Check that this actually works when there's more than 1 enemy
func _on_AIBrain_change_active_unit(cell: Vector2):
	_deselect_active_unit()
	_select_unit(cell)

func _on_AIBrain_move(new_cell):
	print("new cell", new_cell)
	print(_active_unit)
	_unit_path.draw(_active_unit.cell, new_cell)
	_move_active_unit(new_cell)

func _on_AIBrain_skip_turn():
	# TODO: Implement this
	print("TURN SKIPPED?")
	pass

func _on_AIBrain_attack_select(selected_unit):
	attack(_active_unit, selected_unit)

#
#
#UI functions
func _init_UI():
	_UI.visible = true
	_UI.on_max_health_updated(_active_unit.max_health)
	_UI.on_health_updated(_active_unit.health)
	
func _init_enemy_UI(cell):
	_enemy_UI.visible = true
	_enemy_UI_health_bar.max_value = _units[cell].max_health
	_enemy_UI_health_bar.value = _units[cell].health
	_enemy_UI_health_label.text = str(_units[cell].health)

func change_scene():
	if len(unit_teams[ENEMY]) == 0:
		get_tree().change_scene("res://Scenes/VictoryScene.tscn")
	return
