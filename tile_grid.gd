extends Node3D
class_name TileGrid


enum Move { UP, DOWN, LEFT, RIGHT }

const TILE_CONTENT = preload("res://tile_content.tscn")

# Format: [ _1, 2, 3, 4,_   _5, 6, 7, 8,_   _9, 10, 11, 12,_   _13, 14, 15, 16_ ]
# IMPORTANT: this depends on adding tiles as children in the correct way, so that the first tile is
# the top left tile, and the last one is the bottom right (column-first, starting at top left)
var tiles: Array[Area3D] = []
var tile_size := Vector2.ZERO


func _ready():
	var tile_index := 0
	for tile in get_children():
		tiles.append(tile)
		tile.tile_index = tile_index
		if tile_size == Vector2.ZERO:
			tile_size = tile.get_tile_size()
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
	var ordered_list = tiles.filter(func(tile): return is_instance_valid(tile.content))
	if direction == Move.RIGHT or direction == Move.DOWN:
		ordered_list.reverse()

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
	for tile in ordered_list:
		# See if there is a valid tile in the move direction
		var next_tile := find_tile_for_coords(Vector2(tile.position.x, tile.position.z) + tile_move_dir)
		var has_merged := false
		# Keep moving while there is room to move, but only merge once
		while is_instance_valid(next_tile):
			# Check if the valid next tile already has something on it
			var next_tile_content = next_tile.content
			if is_instance_valid(next_tile_content):
				# The tile has something - try and combine it
				if not has_merged and next_tile_content.amount == tile.content.amount:
					next_tile_content.change_amount(next_tile_content.amount * 2)
					tile.clear_tile_content(true)
					did_a_move_happen = true
					tile = next_tile
					next_tile = find_tile_for_coords(Vector2(next_tile.position.x, next_tile.position.z) + tile_move_dir)
					has_merged = true
				else:
					# We can't combine, so move on to the next tile
					next_tile = null
			else:
				# The tile doesn't have anything, so move over
				var content = tile.clear_tile_content(false)
				next_tile.add_tile_content(content)
				did_a_move_happen = true
				tile = next_tile
				next_tile = find_tile_for_coords(Vector2(next_tile.position.x, next_tile.position.z) + tile_move_dir)

	if did_a_move_happen:
		# Only spawn a new block if at least one tile moved or merged
		spawn_block()


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
	free_tiles[i].add_tile_content(TILE_CONTENT.instantiate())


func _unhandled_input(event):
	if event.is_action_pressed("up"):
		move(Move.UP)
	elif event.is_action_pressed("down"):
		move(Move.DOWN)
	elif event.is_action_pressed("right"):
		move(Move.RIGHT)
	elif event.is_action_pressed("left"):
		move(Move.LEFT)
