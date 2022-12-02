class_name Grid
extends Resource

export var size := Vector2(20,20)

export var cell_size := Vector2(128,128)

var half_cell_size = cell_size / 2


# Returns the position of a cell's center in pixels.
func calculate_map_position(grid_position: Vector2) -> Vector2:
	return grid_position * cell_size + half_cell_size


func calculate_grid_coordinates(map_position: Vector2) -> Vector2:
	return (map_position / cell_size).floor()
	
func is_within_bounds(cell_coordinates: Vector2) -> bool:
	var out := cell_coordinates.x >= 0 and cell_coordinates.x < size.x
	var output = out and cell_coordinates.y >= 0 and cell_coordinates.y < size.y
	return output
	
func clamp(grid_position: Vector2) -> Vector2:
	var output := grid_position
	output.x = clamp(output.x, 0, size.x - 1.0)
	output.y = clamp(output.y, 0, size.y - 1.0)
	return output
	
func as_index(cell: Vector2) -> int:
	return int(cell.x + size.x * cell.y)
