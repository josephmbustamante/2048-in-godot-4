extends Area3D
class_name Tile


var tile_index := -1
var content = null


func add_tile_content(tile_content):
	content = tile_content
	add_child(tile_content)


func clear_tile_content(should_free: bool = false) -> TileContent:
	if is_instance_valid(content):
		remove_child(content)
	else:
		printerr("Warning - tried clearing a tile content, but the content was already null!")

	var old_content = content
	content = null

	if should_free:
		old_content.queue_free()
		return null
	else:
		return old_content


func get_tile_size() -> Vector2:
	var scale = $Base.mesh.size
	return Vector2(scale.x, scale.z)
