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

# onready var anim_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = textSpeed
	dialog = getDialog()
	assert(dialog, "Dialog not found")
	nextPhrase()
	
func _process(_delta):
	$Indicator.visible = finished
	if Input.is_action_just_pressed("ui_accept"):
		if finished:
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
		anim_player.play("cut to black")
		queue_free()
		start_game()
		return
	
	if phraseNum == 1:
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
