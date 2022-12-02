extends Node2D
 
onready var introvisual = $YSort/Introvisual

onready var vic_img = preload("res://Scenes/victory.png")

func _ready():
	if SceneTracker.victory_occured:
		introvisual.texture = vic_img
