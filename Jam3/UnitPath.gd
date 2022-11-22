class_name UnitPath
extends TileMap

export var grid: Resource

var _pathfinder: PathFinder

var current_path := PoolVector2Array()

func _ready():
	var rect_start := Vector2(4, 4)
	var rect_end := Vector2(10,8)
	
	var points := []
	
	for x in rect_end.x - rect_start.x + 1:
		for y in rect_end.y - rect_start.y + 1:
			points.append(rect_start + Vector2(x, y))
			
	initialize(points)
	draw(rect_start, Vector2(8, 7))

func initialize(walkable_cells):
	_pathfinder = PathFinder.new(grid, walkable_cells)
	
	
func draw(cell_start: Vector2, cell_end: Vector2):
	clear()
	current_path = _pathfinder.calculate_point_path(cell_start, cell_end)
	
	for cell in current_path:
		set_cellv(cell, 0)
		
	#update_bitmask_region()
	
func stop():
	_pathfinder = null
	clear()
