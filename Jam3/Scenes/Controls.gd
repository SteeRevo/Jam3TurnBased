extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play_backwards("Fade")
	yield(get_tree().create_timer(9),"timeout")
	#$AnimationPlayer.play_backwards("Fade")
	get_tree().change_scene("res://Scenes/intro.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
