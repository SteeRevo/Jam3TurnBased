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

var unit_teams = [[], []]

onready var _unit_path: UnitPath = $UnitPath
onready var _map: TileMap = $TileMap

func _ready():
	print(_map.get_movement_costs(grid))
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
	# for now we say the unit is done
	_active_unit.finished = true
	_clear_active_unit()
	_check_turn_end()


func _on_Cursor_moved(new_cell: Vector2) -> void:
	if (_current_turn != PLAYER): return
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)


func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	if (_current_turn != PLAYER): return
	if not _active_unit:
		_select_unit(cell)
	elif _active_unit.is_selected:
		_move_active_unit(cell)


func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()

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
	
	
	

