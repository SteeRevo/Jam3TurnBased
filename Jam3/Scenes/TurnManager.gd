extends Node

class_name TurnManager

var active_team

func initialize():
	active_team = get_child(0)

func play_turn():
	# wait until turn is over
	#yield(active_team.play_turn(), "completed")
	# flips 1/0
	var new_index : int = 1 - active_team.get_index()
	active_team = new_index
