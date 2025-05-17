extends Node2D

@export var world_position: Vector2i

@onready var tile_map_layer: TileMapLayer = $"../Environment/TileMapLayer"

enum direction {N, S, E, W}

func _process(delta: float) -> void:
	
	world_position = get_world_pos(position)
	
	if (Input.is_action_just_pressed("Test")):
		move(direction.S)

func get_world_pos(pos: Vector2i) -> Vector2i:
	var ret_pos: Vector2i
	
	ret_pos.x = pos.x / 8
	ret_pos.y = pos.y / 8
	
	return ret_pos

func get_real_pos(pos: Vector2i) -> Vector2i:
	var ret_pos: Vector2i
	
	ret_pos.x = pos.x * 8
	ret_pos.y = pos.y * 8
	
	return ret_pos

func grid_snap():
	pass

func get_tile(pos: Vector2i) -> TileData:
	return tile_map_layer.get_cell_tile_data(pos)

func move(dir: direction):
	var offset: Vector2i
	
	if(dir == direction.N):
		offset = Vector2(0, -1)
	elif(dir == direction.S):
		offset = Vector2(0, 1)
	elif(dir == direction.E):
		offset = Vector2(1, 0)
	elif(dir == direction.W):
		offset = Vector2(-1, 1)
	
	var tile_position: Vector2i = world_position + offset
	
	print(tile_position)
	
	var new_tile:= get_tile(tile_position)
	
	print(new_tile.get_custom_data("obstacle"))
	
	if(new_tile.get_custom_data("obstacle") == false):
		position = lerp(position, get_real_pos(tile_position) as Vector2, 1)
