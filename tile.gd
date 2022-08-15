extends Area3D
class_name Tile


var tile_index := -1
var content = null


func get_tile_size() -> Vector2:
	var scale = $Base.mesh.size
	return Vector2(scale.x, scale.z)
