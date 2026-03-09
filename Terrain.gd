@tool
extends MeshInstance3D

const size = 256

@export_tool_button("Generate") var generate = update_mesh

@export_category("Mesh Details")

@export_range(4, 256, 4) var resolution := 128

@export_range(1.0,256.0,1.0) var height := 3

@export var height_map : FastNoiseLite

@export_category("Colors")

@export var sand_color := Color.from_rgba8(172, 99, 29, 255)

@export var grass_color := Color.from_rgba8(0, 75, 0, 255)

@export var snow_color := Color.from_rgba8(248, 248, 255, 255)

@export var rock_color := Color.from_rgba8(68, 68, 68, 255)

@export_category("Color Settings")

@export_range(-size, size, 1.0) var sand_full := 0
@export_range(-size, size, 1.0) var sand_max := 10

@export_range(-size, size, 1.0) var snow_min := 30
@export_range(-size, size, 1.0) var snow_max := 40

@export_range(0.0, 1.0, 0.01) var rock_min := 0.3
@export_range(0.0, 1.0, 0.01) var rock_max := 0.5

var plane : PlaneMesh
var plane_arrays
var vertex_array : PackedVector3Array
var index_array : PackedInt32Array
var normal_array : PackedVector3Array
var tangent_array : PackedFloat32Array
var color_array : PackedColorArray

#func _ready() -> void:
#	update_mesh()

func update_mesh():
	plane = PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size,size)
	
	plane_arrays = plane.get_mesh_arrays()
	vertex_array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	index_array = plane_arrays[ArrayMesh.ARRAY_INDEX]
	normal_array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	tangent_array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	color_array.resize(vertex_array.size())
	
	for i in range(0, vertex_array.size()):
		var vertex := global_transform * vertex_array[i]
		#var tangent := Vector3.RIGHT
		
		if height_map:
			var distToCenter = sqrt(pow(vertex.x,2.0) + pow(vertex.z,2.0))
			if distToCenter <= resolution/10.0:
				distToCenter = resolution/10.0
			vertex.y = pow(height_map.get_noise_2d(vertex.x,vertex.z) * height,2) * pow(resolution/distToCenter,1.1)
			if distToCenter >= resolution/10.0*2.5:
				vertex.y -= (distToCenter - resolution/10.0*2.5) * 0.25
			vertex_array[i] = vertex
	
	for i in range(0, index_array.size(), 3):
		var i0 = index_array[i]
		var i1 = index_array[i + 1]
		var i2 = index_array[i + 2]
		
		var A = vertex_array[i0]
		var B = vertex_array[i1]
		var C = vertex_array[i2]
		
		var edge1 = C - A
		var edge2 = B - A
		
		var normal = edge1.cross(edge2)
		
		normal_array[i0] += normal
		normal_array[i1] += normal
		normal_array[i2] += normal
		
		normal_array[i0] = normal_array[i0].normalized()
		normal_array[i1] = normal_array[i1].normalized()
		normal_array[i2] = normal_array[i2].normalized()
		
		get_tangent(i0)
		get_tangent(i1)
		get_tangent(i2)
		
		get_color(i0)
		get_color(i1)
		get_color(i2)
	
	plane_arrays[ArrayMesh.ARRAY_COLOR] = color_array
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)


func get_tangent(i : int):
	var tangent := normal_array[i].cross(Vector3.UP)
	
	tangent_array[4 * i] = tangent.x
	tangent_array[4 * i + 1] = tangent.y
	tangent_array[4 * i + 2] = tangent.z
	

func get_color(i : int):
	var steepness := 1.0 - normal_array[i].dot(Vector3.UP)
	
	var sand_weight : float = clamp(-1 * ((vertex_array[i].y - sand_max) / (sand_max - sand_full)), 0.0, 1.0)
	var snow_weight : float = clamp((vertex_array[i].y - snow_max) / (snow_max - snow_min), 0.0, 1.0)
	var rock_weight : float = clamp((steepness - rock_min) / (rock_max - rock_min), 0.0, 1.0)
	var grass_weight : float = clamp(1.0 - sand_weight - snow_weight - rock_weight, 0.0, 1.0)
	
	var total_weight := sand_weight + snow_weight + rock_weight + grass_weight
	color_array[i] = (sand_color * sand_weight + grass_color * grass_weight + snow_color * snow_weight + rock_color * rock_weight) / total_weight
	
	
