extends Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Hides and keeps the mouse centered

func _input(event): # Checks for input
	if event is InputEventMouseMotion and !get_parent().isCrafting: # Checks if the input is the mouse moving and if the player is not crafting
		rotate(Vector3.LEFT, event.relative.y * 0.001) # Rotates the player vertically with the mouse
