tool
class_name Cursor
extends Node2D

signal accept_pressed(cell)
signal moved(new_cell)
signal hello()

export var grid: Resource = preload("res://Grid.tres")
export var ui_cooldown := 0.1

var cell := Vector2.ZERO setget set_cell

onready var _move_sound = $MoveCursorSound
onready var _select_sound = $SelectCursorSound
onready var _timer: Timer = $Timer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_timer.wait_time = ui_cooldown
	position = grid.calculate_grid_coordinates(cell)
	emit_signal("hello")
	
func _unhandled_input(event):
	#if event is InputEventMouseMotion:
	#	self.cell = grid.calculate_grid_coordinates(event.position)
	#	print(event.position)
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):

		emit_signal("accept_pressed", cell)
		get_tree().set_input_as_handled()
		
	var should_move = event.is_pressed()
	
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()
	
	if not should_move:
		return
	
	if event.is_action("ui_right"):
		self.cell += Vector2.RIGHT
		_play_move_sound()
	elif event.is_action("ui_up"):
		self.cell += Vector2.UP
		_play_move_sound()
	elif event.is_action("ui_left"):
		self.cell += Vector2.LEFT
		_play_move_sound()
	elif event.is_action("ui_down"):
		self.cell += Vector2.DOWN
		_play_move_sound()
	

func _draw():
	draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.aliceblue, false, 2.0)

func set_cell(value: Vector2):

	if not grid.is_within_bounds(value):

		cell = grid.clamp(value)
	else:
		cell = value
	
	position = grid.calculate_map_position(cell)
	emit_signal("moved", cell)
	_timer.start()
		

func _play_move_sound():
	randomize()
	_move_sound.pitch_scale = rand_range(0.9, 1.2)
	_move_sound.play() 
	
func play_select_sound():
	_select_sound.volume_db = -1
	_select_sound.pitch_scale = 1.0
	_select_sound.play()
	
func play_deselect_sound():
	_select_sound.volume_db = -11
	_select_sound.pitch_scale = 0.5
	_select_sound.play()
		
