extends Camera2D

const MOVEMENT_BORDER_SIZE = 10
func _process(delta):
	var mouse_position = get_viewport().get_mouse_position()
	var screen_size = get_viewport_rect().size
	#print("screen size x",screen_size.x)
	#print("screen size y",screen_size.y)
	#print(mouse_position.x)
	#print("Test: ",screen_size.x - MOVEMENT_BORDER_SIZE)
	# horizontal movement
	if (mouse_position.x <= MOVEMENT_BORDER_SIZE):
		self.position.x -= 200 * delta #left
	elif (mouse_position.x >= screen_size.x - MOVEMENT_BORDER_SIZE):
		self.position.x += 200 * delta #right
	
	#print("Movement Border",screen_size.x - MOVEMENT_BORDER_SIZE)
	
	# vertical movement
	if (mouse_position.y <= MOVEMENT_BORDER_SIZE):
		self.position.y -= 200 * delta # up
	elif (mouse_position.y >= screen_size.y - MOVEMENT_BORDER_SIZE):
		self.position.y += 200 * delta # down
