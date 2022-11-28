class_name AIBrain
extends Node

# The entire point of this scene node is to determine what action to make given a game state.
# This is done using the calculate_action method.

enum UnitTeamIDs {PLAYER, ENEMY}

var _current_game_state
var my_decision_tree = null
var my_memory := {} # Used to store data while evaluating decision tree

# Signals
signal change_active_unit
signal move

# Called when the node enters the scene tree for the first time.
func _ready():
	my_decision_tree = DecisionTree.new(decision_tree1, self)

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

# Returns true is the current active unit is the prefarable one to play with, else returns false
func _active_unit_is_preferable():
	# TODO: Implement this
	return true

func _move_to_random_spot_in_range():
	var active_unit_properties = _current_game_state["unit_properties"][_current_game_state["active_unit_index"]]
	# TODO: Change this to a method that returns the correct set of cells
	var possible_cells = get_node("..").flood_fill(active_unit_properties["cell"], active_unit_properties["move_range"])
	possible_cells.erase(active_unit_properties["cell"])

	var chosen_cell = possible_cells[randi() % possible_cells.size()]
	emit_signal("move", chosen_cell)

# TODO: Delete this method later
func _dummy_method():
	print("decision tree print thing")
	return _move_to_random_spot_in_range()

# Example tree that just moves the enemy unit around randomly
var decision_tree1 = [
	"randi() % 2 == 0", [
		"_move_to_random_spot_in_range()"
	], [
		funcref(self, "_dummy_method")
	]
]
