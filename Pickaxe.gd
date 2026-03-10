extends Node3D
@export var boost : float

func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and $Pickaxe/AnimationPlayer.is_playing() == false:
		$Pickaxe/AnimationPlayer.play("Pickaxe")
