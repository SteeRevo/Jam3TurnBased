class_name DecisionTreeNode
extends Reference

# Depending on the tree data that was passed to this node's decision tree, this will either be an
# Expression object or a FuncRef object.
var node_data

# If node_data is an Expression, this holds the input string for node_data.
# Else, if node_data is a FuncRef, it holds the name of the function for node_data.
var node_data_string

var child_true
var child_false
var is_leaf

func evaluate(game_state, base_instance):
	var result # Value that's the result of evaluating this node's node_data

	# node_data is an Expression object
	if (node_data.get_class() == "Expression"):
		result = node_data.execute([], base_instance)
		if (node_data.has_execute_failed()):
			printerr("Execution of expression ", node_data_string, " has failed!")
			return

	# node_data is a FuncRef object
	elif (node_data.get_class() == "FuncRef"):
		if (not node_data.is_valid()):
			printerr("The specified method \"", node_data_string, "\" doesn't exist!")
			return
		result = node_data.call_func()

	if (not is_leaf):
		var child_to_evaluate = child_true if result == true else child_false
		return child_to_evaluate.evaluate(game_state, base_instance)

	return result
