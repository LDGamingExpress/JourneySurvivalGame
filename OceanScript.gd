extends MeshInstance3D
var Rising = false

func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	Rising = true

func _physics_process(delta: float) -> void:
	position.y = Globals.OceanHeight
	if Rising:
		Globals.OceanHeight += 0.001
