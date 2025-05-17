class_name GridMovement
extends Node2D

@export var world_position: Vector2i
@export var speed: float = 4

@onready var tile_map_layer: TileMapLayer = $"../Environment/TileMapLayer"

enum direction {N, S, E, W}
var is_walking: bool = false

func _process(delta: float) -> void:
	set_pos()

func set_pos() -> void:
	if (position.x != world_position.x or position.y != world_position.y):
		position = get_real_pos(world_position) as Vector2

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
		offset = Vector2(-1, 0)
	
	var tile_position: Vector2i = world_position + offset
	
	var new_tile:= get_tile(tile_position)
	print(tile_position, "pos", new_tile)
	
	if(new_tile.get_custom_data("obstacle") == false):
		world_position = tile_position
