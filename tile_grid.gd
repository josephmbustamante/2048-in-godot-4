extends Node3D
class_name TileGrid


enum Move { UP, DOWN, LEFT, RIGHT }

const TILE_CONTENT = preload("res://tile_content.tscn")

@export var display_tile_numbers := false

# Format: [ _1, 2, 3, 4,_   _5, 6, 7, 8,_   _9, 10, 11, 12,_   _13, 14, 15, 16_ ]
# IMPORTANT: this depends on adding tiles as children in the correct way, so that the first tile is
# the top left tile, and the last one is the bottom right (column-first, starting at top left)
var tiles: Array[Area3D] = []
var tile_contents: Array[TileContent] = []
var tile_size := Vector2.ZERO

var is_moving := false


func _ready():
	var tile_index := 0
	for tile in get_children():
		tiles.append(tile)
		tile.tile_index = tile_index
		if tile_size == Vector2.ZERO:
			tile_size = tile.get_tile_size()

		if display_tile_numbers:
			var t := Label3D.new()
			tile.add_child(t)
			t.text = str(tile_index + 1)
			t.font_size = 12
			t.global_rotation = Vector3(deg2rad(-90), 0, 0)
			t.position += Vector3(0, 0.25, 0.25)

		tile_index += 1

	spawn_block()
	spawn_block()


func move(direction: Move):
	is_moving = true
	# Get a list of the current tile contents, sorted by parent tile index
	var content_list = tile_contents.duplicate()
	content_list.sort_custom(func(a, b): return a.tile.tile_index < b.tile.tile_index)

	if direction == Move.RIGHT or direction == Move.DOWN:
		content_list.reverse()

	var tile_move_dir := Vector2.ZERO
	match direction:
		Move.UP:
			tile_move_dir = Vector2(0, -1)
		Move.DOWN:
			tile_move_dir = Vector2(0, 1)
		Move.RIGHT:
			tile_move_dir = Vector2(1, 0)
		Move.LEFT:
			tile_move_dir = Vector2(-1, 0)

	var did_a_move_happen := false
	for content in content_list:
		var current_tile = content.tile
		var original_position = current_tile.position
		var final_position = original_position

		# See if there is a valid tile in the move direction
		var next_tile := find_tile_for_coords(Vector2(current_tile.position.x, current_tile.position.z) + tile_move_dir)
		var finished_moving_tile := not is_instance_valid(next_tile)

		# Keep moving while there is room to move
		while not finished_moving_tile:
			# Check if the valid next tile already has something on it
			var next_tile_content = next_tile.content
			if is_instance_valid(next_tile_content):
				# The tile has something - try and combine it
				if next_tile_content.amount == content.amount:
					next_tile_content.change_amount(next_tile_content.amount * 2)

					# We're deleting this content when it merges, so set it to null
					current_tile.content = null
					content.tile = null
					did_a_move_happen = true

					# Delete the current content and just keep the combined one.
					tile_contents.erase(content)
					var nt: Tween = next_tile_content.create_tween()
					nt.tween_property(next_tile_content, "scale", Vector3.ONE * 1.1, 0.2)
					nt.tween_property(next_tile_content, "scale", Vector3.ONE, 0.2)

					var t: Tween = content.create_tween()
					t.set_parallel(true)
					t.tween_callback(content.queue_free).set_delay(0.15)
					t.tween_property(content.label, "modulate:a", 0.0, 0.05).set_delay(0.1)
					t.tween_property(content.label, "outline_modulate:a", 0.0, 0.05).set_delay(0.1)
					final_position = next_tile.position
				else:
					final_position = current_tile.position
				# Regardless of whether we combined or not, this tile is moved all the way over.
				finished_moving_tile = true
			else:
				# The tile doesn't have anything, so move over
				current_tile.content = null
				next_tile.content = content

				current_tile = next_tile
				content.tile = current_tile

				did_a_move_happen = true
				final_position = current_tile.position

				next_tile = find_tile_for_coords(Vector2(next_tile.position.x, next_tile.position.z) + tile_move_dir)
				finished_moving_tile = not is_instance_valid(next_tile)

		if final_position != original_position:
			var t: Tween = content.create_tween()
			t.tween_property(content, "position", final_position, 0.15)

	if did_a_move_happen:
		# Only spawn a new block if at least one tile moved or merged
		var t: Tween = self.create_tween()
		t.tween_callback(spawn_block).set_delay(0.2)

	var t = self.create_tween()
	t.tween_property(self, "is_moving", false, 0.5)


func find_tile_for_coords(coords: Vector2) -> Tile:
	if coords.x < 0 or coords.x > 3 or coords.y < 0 or coords.y > 3:
		return null

	var i = (coords.x * 4) + (coords.y)
	if i < 0 or i >= tiles.size():
		return null
	else:
		return tiles[i]


func spawn_block():
	var free_tiles = tiles.filter(func (tile): return not is_instance_valid(tile.content))
	var i := randi() % free_tiles.size()

	# Add the content as a child of the grid itself
	var content = TILE_CONTENT.instantiate()
	add_child(content)

	# Add the content to the content list, and let its current tile know it has content now
	var tile = free_tiles[i]
	tile.content = content
	content.tile = tile
	content.position = tile.position
	tile_contents.append(content)
	content.scale = Vector3(0.5, 0.5, 0.5)
	var t = content.create_tween()
	t.tween_property(content, "scale", Vector3.ONE * 1.2, 0.1)
	t.tween_property(content, "scale", Vector3.ONE, 0.1)


func _unhandled_key_input(event):
	if is_moving:
		return

	if event.is_action_pressed("up"):
		move(Move.UP)
	elif event.is_action_pressed("down"):
		move(Move.DOWN)
	elif event.is_action_pressed("right"):
		move(Move.RIGHT)
	elif event.is_action_pressed("left"):
		move(Move.LEFT)
