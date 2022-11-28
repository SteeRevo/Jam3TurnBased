class_name DecisionTree
extends Reference

#
# Format of Data for Decision Trees
#
# Tree data will be represented as array with nested arrays.
# Every internal node of the array has the following format: [<data>, [<node if true>], [<node if false>]]
# Every leaf node will have the following format: [<data>]
# <data> is either a string for an Expression object or a FuncRef object.
# 
# For internal nodes, <data> should always return true or false when evaluated.
# 
# For leaf nodes, <data> should indicate an action to be done. This might be represented as a
# FuncRef for a method in the provided base_instance object. It may also be a string for an
# Expression object. This may optionally return something, which will be returned when the entire
# tree is evaluated.

var root_node
# The object instance in which expressions and function references will be executed with respect to.
var _my_base_instance 

# Constructor
func _init(tree_data, base_instance):
	root_node = DecisionTreeNode.new()
	_my_base_instance = base_instance
	_set_up_node(root_node, tree_data)

func evaluate_using_game_state(game_state):
	return root_node.evaluate(game_state, _my_base_instance)

# Recursively creates decision tree nodes
func _set_up_node(tree_node: DecisionTreeNode, tree_data):
	if (tree_data.size() != 1 and tree_data.size() != 3):
		printerr("Incorrect number of elements for node in decision tree input:\n", tree_data)
		print(tree_data.size())
		return
	
	# Set the current node's data
	var data = tree_data[0]
	if (typeof(data) == TYPE_STRING):
		tree_node.node_data = Expression.new()
		var error = tree_node.node_data.parse(data)
		if (error != OK):
			printerr("There was an error parsing the string ", data)
			print(tree_node.node_data.get_error_text())
			return
		tree_node.node_data_string = data
	elif (typeof(data) == TYPE_OBJECT and data.get_class() == "FuncRef"):
		tree_node.node_data = data
		tree_node.node_data_string = data.function
		tree_node.node_data.set_instance(_my_base_instance)
	else:
		printerr("Node data needs to be represented as a string for an expression or as a FuncRef:\n", tree_data)
		return

	# Set this node's children, if any
	if (tree_data.size() == 3):
		if (typeof(tree_data[1]) != TYPE_ARRAY or typeof(tree_data) != TYPE_ARRAY):
			printerr("Child nodes need to be represented as arrays:\n", tree_data)
			return

		tree_node.is_leaf = false
		tree_node.child_true = DecisionTreeNode.new()
		tree_node.child_false = DecisionTreeNode.new()

		# Recursive Step
		_set_up_node(tree_node.child_true, tree_data[1])
		_set_up_node(tree_node.child_false, tree_data[2])
	else:
		tree_node.is_leaf = true
