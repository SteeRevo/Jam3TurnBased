extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/StartButton.grab_focus()
	yield(get_tree().create_timer(1),"timeout")
	$AnimationPlayer.play("Fade")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_StartButton_pressed():
	get_tree().change_scene("res://Scenes/intro.tscn")

func _on_ControlsButton_pressed():
	get_tree().change_scene("res://Scenes/Controls.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
