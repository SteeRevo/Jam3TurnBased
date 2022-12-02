extends ColorRect

export var dialogPath = "res://Text/dialog.json"
export(float) var textSpeed = 0.05

# From Dialog Tutorial at https://youtu.be/GzPvN5wsp7Y
# Tutorial written by use Afely

var dialog: Array
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var phraseNum := 0
var finished := false


onready var anim_player = get_node("../../AnimationPlayer")
onready var anim_player_i = get_node("Indicator/AnimationPlayerIndicator")

onready var timerScreeenchange = get_node("TimerScreenchange")

onready var laser_sound = get_node("../../laser")

# onready var anim_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = textSpeed
	timerScreeenchange.wait_time = 1
	dialog = getDialog()
	assert(dialog, "Dialog not found")
	nextPhrase()
	
func _process(_delta):
	$Indicator.visible = finished
	if Input.is_action_just_pressed("ui_accept"):
		if finished:
			finished = false
			nextPhrase()
		else:
			$Text.visible_characters = len($Text.text)

	
func getDialog() -> Array:
	var f = File.new()
	assert(f.file_exists(dialogPath), "File path does not exist")
	
	f.open(dialogPath, File.READ)
	var json = f.get_as_text()
	
	var output = parse_json(json)
	
	if typeof(output) == TYPE_ARRAY:
		return output
	else:
		return []

func nextPhrase() -> void:
	anim_player_i.play("indicatorbounce")
	if phraseNum >= len(dialog):
		self.visible = false
		yield(get_tree().create_timer(.75), "timeout")
		anim_player.play("cut to black")
		
		yield(get_tree().create_timer(.75), "timeout")
		
		print("scene tracker", SceneTracker.victory_occured)
		if (SceneTracker.victory_occured):
			print("changing to credits")
			get_tree().change_scene("res://Scenes/Credits.tscn")
		else:
			SceneTracker.victory_occured = true
			start_game()
		
		return
	
	if phraseNum == 1:
		play_sound()
		yield(get_tree().create_timer(2.2), "timeout")
		anim_player.play("fade in pic")
		
	finished = false
	
	$Text.bbcode_text = dialog[phraseNum]["Text"]
	
	$Text.visible_characters = 0
	
	while $Text.visible_characters < len($Text.text):
		$Text.visible_characters += 1
		
		$Timer.start()
		yield($Timer, "timeout")
		
	finished = true
	phraseNum += 1
	return

func start_game():
	get_tree().change_scene("res://Scenes/BaseLevel.tscn")

func play_sound():
	laser_sound.play()
	yield(get_tree().create_timer(2.4), "timeout")
	laser_sound.stop()
	return
