class_name GameBoard
extends YSort

enum {PLAYER, ENEMY}

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

export var grid: Resource = preload("res://Grid.tres")

onready var _unit_overlay: Overlay = $Overlay

var _units := {}

var _active_unit: Unit

var _walkable_cells := []

# is it the player's turn?
var _current_turn = PLAYER

var _selecting_opponent = false

var unit_teams = [[], []]

onready var _unit_path: UnitPath = $UnitPath

signal choose_opponent

func _ready():
	_reinitialize()
	

func is_occupied(cell: Vector2):
	return true if _units.has(cell) else false
	
func _reinitialize():
	_units.clear()
	
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		if unit.team == PLAYER:
			unit_teams[PLAYER].push_back(unit)
		if unit.team == ENEMY:
			unit_teams[ENEMY].push_back(unit)
			unit.finished = true
			
		_units[unit.cell] = unit
		
func get_walkable_cells(unit: Unit):
	return _flood_fill(unit.cell, unit.move_range)
	
func _check_turn_end():
	for unit in _units.values():
		if not unit.finished:
			print(unit)
			return
	# flips the turn between 1 and 0
	_set_turn(1 - _current_turn)
	
	
func _set_turn(turn):
	_current_turn = turn
	print("turn: %s" % _current_turn)
	# reset all units of the next player to ready
	for unit in unit_teams[_current_turn]:
		unit.finished = false
	
	# maybe send some signal to enemy AI or player?
	# temp turn-passing code:
	if _current_turn == ENEMY:
		temp_enemy_turn()
	
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
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

func _select_unit(cell: Vector2) -> void:
	if not _units.has(cell) or _units[cell].finished or _units[cell].team != _current_turn:
		return

	_active_unit = _units[cell]
	_active_unit.is_selected = true
	_walkable_cells = get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path.initialize(_walkable_cells)
	print(_active_unit)


func _deselect_active_unit() -> void:
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()


func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


func _move_active_unit(new_cell: Vector2) -> void:
	if is_occupied(new_cell) or not new_cell in _walkable_cells:
		return

	_units.erase(_active_unit.cell)
	_units[new_cell] = _active_unit
	
	_deselect_active_unit()
	_active_unit.walk_along(_unit_path.current_path)
	yield(_active_unit, "walk_finished")
	# process combat choices
	_combat_step()
	
	# for now we say the unit is done
	_active_unit.finished = true
	_clear_active_unit()
	_check_turn_end()

func _combat_step() :
	# yield again and wait for opponent choice (if any)
	var avail_opponents = _get_adjacent_units(_active_unit.cell, 1 - _current_turn)
	if avail_opponents.size() > 0:
		_selecting_opponent = true
		var opp = yield(self, "choose_opponent")
		while true:
			if opp in avail_opponents or opp == null:
				print("chose %s" % opp)
				break
			else:
				print("choose an adjacent enemy unit to fight!")
				opp = yield(self, "choose_opponent")
		_selecting_opponent = false
		if (opp == null):
			print("no fight")
		else:
			print(_active_unit, " fights ", avail_opponents[opp])

func _on_Cursor_moved(new_cell: Vector2) -> void:
	if (_current_turn != PLAYER): return
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)


func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	#replace this with an FSM?
	if (_current_turn != PLAYER): return
	if not _active_unit:
		_select_unit(cell)
	elif _active_unit.is_selected:
		_move_active_unit(cell)
	elif _selecting_opponent:
		emit_signal("choose_opponent", cell)
		

func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and _active_unit.is_selected and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()
	# press esc while choosing opponents to choose no opponent (not fight)
	if _selecting_opponent: emit_signal("choose_opponent", null)

func temp_enemy_turn():
	# i Imagine we'll have the actual AI activate on some signal, then it sends
	# a signal back on finishing or something
	print("enemy makes some plays...")
	yield(get_tree().create_timer(2.0), "timeout")
	print("return the turn")
	for unit in unit_teams[ENEMY]:
		unit.finished = true;
	_check_turn_end()
	return
	
func _get_adjacent_units(cell: Vector2, team: int) -> Dictionary:
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
	
	
	

