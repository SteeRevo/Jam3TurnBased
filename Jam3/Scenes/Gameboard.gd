class_name GameBoard
extends YSort

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

export var grid: Resource = preload("res://Grid.tres")

onready var _unit_overlay: Overlay = $Overlay

var _units := {}

func _ready():
	_reinitialize()
	print(_units)
	_unit_overlay.draw(get_walkable_cells($Unit))
	print(get_walkable_cells($Unit))

func is_occupied(cell: Vector2):
	return true if _units.has(cell) else false
	
func _reinitialize():
	_units.clear()
	
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
			
		_units[unit.cell] = unit
		
func get_walkable_cells(unit: Unit):
	return _flood_fill(unit.cell, unit.move_range)	
	
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	var array := []
	var stack := [cell]
	while not stack.empty():
		var current = stack.pop_back()

		if not grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			if is_occupied(coordinates):
				continue
			if coordinates in array:
				continue

			stack.append(coordinates)
	return array
		
		
		
		
		
		
		
		


