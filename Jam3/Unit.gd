tool
class_name Unit
extends Path2D

enum sides {PLAYER, ENEMY}

export var grid: Resource = preload("res://Grid.tres")
export var move_range := 6
export var skin: Texture setget set_skin
export var move_speed := 100
export (sides) var team

export var health := 5 setget set_health
export var max_health := 5 setget set_max_health
export var attack := 2
export var defense := 2
export var hit_rate := 0.7
export var evasion := 0.4


var cell := Vector2.ZERO setget set_cell
var is_selected := false setget set_is_selected
var is_walking := false setget set_is_walking
# this unit has no more moves left this turn.
var finished := false

signal walk_finished

onready var _sprite: Sprite = $PathFollow2D/Sprite
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var path_follow: PathFollow2D = $PathFollow2D



func _ready():
	set_process(false)
	
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	anim_player.play("idle")
	
	if not Engine.editor_hint:
		curve = Curve2D.new()
		

func _process(delta):
	path_follow.offset += move_speed * delta
	
	if path_follow.unit_offset >= 1.0:
		self.is_walking = false
		path_follow.offset = 0.0
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		
		emit_signal("walk_finished")
		
func walk_along(path: PoolVector2Array) -> void:
	if path.empty():
		return

	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	self.is_walking = true

func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)

func set_is_selected(value: bool) -> void:
	is_selected = value
	if is_selected:
		anim_player.play("selected")
	else:
		anim_player.play("idle")
		
func set_skin(value: Texture) -> void:
	skin = value
	if not _sprite:
		yield(self, "ready")
	_sprite.texture = value
	

func set_is_walking(value: bool) -> void:
	is_walking = value
	set_process(is_walking)
	
func set_health(val: int):
	health = clamp(val, 0, max_health)
	
func set_max_health(val: int):
	max_health = max(val, 1)
	
	



	
