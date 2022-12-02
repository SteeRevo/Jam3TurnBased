class_name AIBrain
extends Node

# The entire point of this scene node is to determine what action to make given a game state.
# This is done using the calculate_action method.
# Note: Lots of the functionality here is currently really inefficient, but I don't currently feel
# like improving it.

# Signals
signal move
signal attack_select
signal skip_turn
signal change_active_unit

enum UnitTeamIDs {PLAYER, ENEMY}
enum TurnPhases {MOVEMENT_SELECTION, ATTACK_SELECTION}

var _current_game_state
var my_decision_tree = null
var my_memory := {} # Used to store data while evaluating decision tree

# Called when the node enters the scene tree for the first time.
func _ready():
	my_decision_tree = DecisionTree.new(decision_tree_1, self)

# Use this method to calculate what action to make given a game state.
func calculate_action(game_state):
	_current_game_state = game_state

	# If it's currently the player's turn, then this method was called when it wasn't supposed to.
	if (game_state["current_turn"] == UnitTeamIDs.PLAYER):
		printerr("AIBrain was used during the player's turn. Skipping calculations for actions...")
		return

	var resulting_action = my_decision_tree.evaluate_using_game_state(game_state)
	return resulting_action

# Select the decision tree by name for this object to use
func select_decision_tree(tree_name: String):
	# TODO: Implement this
	pass

#
# Helper Methods
#

func _get_active_unit_properties():
	return _current_game_state["unit_properties"][_current_game_state["active_unit_index"]]

func _get_walkable_cells_of_active_unit() -> Array:
	var active_unit_properties = _get_active_unit_properties()
	var walkable_cells = get_node("..").dijkstra(active_unit_properties["cell"], active_unit_properties["move_range"])
	walkable_cells.erase(active_unit_properties["cell"])

	return walkable_cells

# Returns true if two cells are adjacent, otherwise returns false.
# Counts diagonal cells as adjacent.
func _cells_are_adjacent(cell_A, cell_B):
	return abs(cell_B.x - cell_A.x) <= 1 and abs(cell_B.y - cell_A.y) <= 1

# Returns the cell of the queen bee unit if it is still on the board, else returns null
func _get_cell_of_queen():
	for unit_props in _current_game_state["unit_properties"]:
		# TODO: Change this to match queen properties and update game state representation
		if (unit_props["is_queen"] == true):
			return unit_props.cell

	# No cell for queen bee unit found
	return null

func _queen_unit_is_alive():
	return true if _get_cell_of_queen() != null else false

# Returns all cells that are currently occupied by units that aren't the active unit
func _get_non_active_unit_occupied_cells() -> Array:
	var occupied_cells = []
	for i in range(_current_game_state["unit_properties"].size()):
		if (i != _current_game_state["active_unit_index"]):
			occupied_cells.append(_current_game_state["unit_properties"][i]["cell"])
	return occupied_cells

func _get_all_currently_occupiable_cells() -> Array:
	var all_tilemap_cells = _current_game_state["tilemap"].get_used_cells()
	var tilemap_movement_costs = _current_game_state["tilemap"].get_movement_costs(_current_game_state["grid"])
	var occupiable_path_cells = []
	for cell in all_tilemap_cells:
		if (tilemap_movement_costs[cell.y][cell.x] < 1000 # Arbitrary value that's less than the movement cost for barrier cells
		and not cell in _get_non_active_unit_occupied_cells()):
			occupiable_path_cells.append(cell)

	return occupiable_path_cells

# Returns all cells that can have a unit moved onto it (not necessarily in the current turn)
func _get_all_ground_cells() -> Array:
	var all_tilemap_cells = _current_game_state["tilemap"].get_used_cells()
	var tilemap_movement_costs = _current_game_state["tilemap"].get_movement_costs(_current_game_state["grid"])
	var ground_cells = []
	for cell in all_tilemap_cells:
		if (tilemap_movement_costs[cell.y][cell.x] < 1000):
			ground_cells.append(cell)

	return ground_cells

# Returns true if the current active unit currently can't move out of a 1 by 1 space
func _is_stuck_in_1_by_1():
	var offsets = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var active_unit_pos = _get_active_unit_properties()["cell"]

	var tilemap_movement_costs = _current_game_state["tilemap"].get_movement_costs(_current_game_state["grid"])

	for i in range(4):
		var neighboring_cell = active_unit_pos + offsets[i]
		if (not _current_game_state["grid"].is_within_bounds(neighboring_cell)):
			continue
		if (tilemap_movement_costs[neighboring_cell.y][neighboring_cell.x] < 1000
		and not neighboring_cell in _get_non_active_unit_occupied_cells()):
			return false

	return true

#
#
#

# Returns true if the current active unit is the preferable one to play with, else returns false
func _active_unit_is_preferable():
	# TODO: Implement this
	return true

func _in_range_of_queen():
	var cell_of_queen = _get_cell_of_queen()

	# If the queen bee unit doesn't exist anymore, return false
	if (cell_of_queen == null):
		return false

	var walkable_cells = _get_walkable_cells_of_active_unit()
	for cell in walkable_cells:
		if (_cells_are_adjacent(cell, cell_of_queen)):
			return true
	return false

func _move_towards_queen_from_afar():
	#var valid_path_cells = _get_walkable_cells_of_active_unit()
	var valid_path_cells = _get_all_ground_cells()
	valid_path_cells.append(_get_cell_of_queen())
	var pathfinder = PathFinder.new(_current_game_state["grid"], valid_path_cells)
	# This technically makes the destination the same cell as the queen unit instead of one of the
	# cells adjacent to it, but whatever.
	var point_path = pathfinder.calculate_point_path(_get_active_unit_properties()["cell"], _get_cell_of_queen())

	if (point_path.size() - 1 > 0):
		var closest_cell = point_path[0]
		# Iteratively find the farthest valid point on point_path to use
		for i in range(1, _get_active_unit_properties()["move_range"]):
			if (point_path[i] in _get_non_active_unit_occupied_cells()):
				break
			closest_cell = point_path[i]

		if (closest_cell != point_path[0]):
			emit_signal("move", closest_cell)
			return

	# A path wasn't able to be formed
	if (_is_stuck_in_1_by_1()):
		print("Skipping turn because unit with the following properties can't move!\n", _get_active_unit_properties())
		emit_signal("skip_turn")
		return

	# Try to find the walkable cell that's closest
	var walkable_cells = _get_walkable_cells_of_active_unit()
	var min_distance = INF
	var cell_with_min_distance = walkable_cells[0]
	for cell in walkable_cells:
		# Get the distance if there were no units in the way
		var min_pathfinder = PathFinder.new(_current_game_state["grid"], _get_all_ground_cells())
		var min_point_path = min_pathfinder.calculate_point_path(cell, _get_cell_of_queen())
		if (min_point_path.size() - 1 < min_distance):
			min_distance = min_point_path.size() - 1
			cell_with_min_distance = cell

	emit_signal("move", cell_with_min_distance)

# Active unit can move to queen unit and attack it
func _move_to_attack_queen():
	var possible_attack_cells = []
	var queen_unit_cell = _get_cell_of_queen()
	var walkable_cells = _get_walkable_cells_of_active_unit()
	for cell in walkable_cells:
		if (_cells_are_adjacent(cell, queen_unit_cell)):
			possible_attack_cells.append(cell)

	if (possible_attack_cells.size() == 0):
		printerr("Unit with the following properties wasn't able to attack the queen!\n", _get_active_unit_properties())
		emit_signal("skip_turn")
		return

	# Try to go to a cell with maximal distance from all other player units than the queen unit
	var max_dist = 0
	var cell_with_max_distance = possible_attack_cells[0]
	for target_cell in possible_attack_cells:
		var distance_sum = 0
		for i in range(_current_game_state["enemy_start_index"]):
			if (_current_game_state["unit_properties"][i]["is_queen"]):
				continue
			var pathfinding_cells = _get_all_currently_occupiable_cells()
			pathfinding_cells.append(_current_game_state["unit_properties"][i].cell)
			var pathfinder = PathFinder.new(_current_game_state["grid"], pathfinding_cells)
			var point_path = pathfinder.calculate_point_path(_current_game_state["unit_properties"][i].cell, target_cell)
			distance_sum += point_path.size() - 1

		if (distance_sum > max_dist):
			max_dist = distance_sum
			cell_with_max_distance = target_cell

	emit_signal("move", cell_with_max_distance)

func _move_towards_lowest_health_opponent_from_afar():
	pass

# Selects the player unit with the least health to attack
# If there are multiple player units with the same health, it will choose one at random to attack
func _attack_lowest_health_opponent():
	# This code's kinda bad in my opinion because it directly accesses unit properties instead of
	# using the one from the game state passed to this object, but I'm running out of time to finish
	# this and I guess this way would be a little more efficient
	var adjacent_units = get_node("..").get_adjacent_units(_get_active_unit_properties()["cell"], UnitTeamIDs.PLAYER)
	if (adjacent_units.empty()):
		printerr("There's no units for the enemy to attack!")
		return

	var lowest_health_units = [adjacent_units.values()[0]]
	var lowest_health = lowest_health_units[0].health
	print("lowest_health_units: ", lowest_health_units)
	for i in range(1, adjacent_units.values().size()):
		var curr_adj_unit = adjacent_units.values()[i]
		if (curr_adj_unit.health < lowest_health_units[0].health):
			lowest_health = curr_adj_unit.health
			lowest_health_units = [curr_adj_unit]
		elif (curr_adj_unit.health == lowest_health):
			lowest_health_units.append(curr_adj_unit)

	emit_signal("attack_select", lowest_health_units[randi() % lowest_health_units.size()])

func _move_to_random_cell_in_range():
	if (_is_stuck_in_1_by_1()):
		emit_signal("skip_turn")
		return

	var possible_cells = _get_walkable_cells_of_active_unit()

	var chosen_cell = possible_cells[randi() % possible_cells.size()]
	print("here are chosen cells ", chosen_cell)
	emit_signal("move", chosen_cell)

# TODO: Delete this method later
func _dummy_method():
	print("decision tree print thing")
	return _move_to_random_cell_in_range()

#
# Decision Trees
#

# Example tree that just moves the enemy unit around randomly
var example_tree = [
	"_in_range_of_queen()", [
		"_move_to_random_cell_in_range()"
	], [
		funcref(self, "_dummy_method")
	]
]

var decision_tree_1 = [
	'_current_game_state["turn_phase"] == TurnPhases.MOVEMENT_SELECTION', [
		"_queen_unit_is_alive()", [
			"_in_range_of_queen()", [
				"_move_to_attack_queen()"
			], [
				"_move_towards_queen_from_afar()"
			]
		], [
			"_move_to_random_cell_in_range()"
		]
	], [
		"_attack_lowest_health_opponent()"
	]
]
