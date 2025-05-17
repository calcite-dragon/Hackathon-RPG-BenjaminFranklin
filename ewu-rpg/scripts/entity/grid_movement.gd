extends Node2D

@export var world_position: Vector2

func _process(delta: float) -> void:
	handle_world_pos()

func handle_world_pos():
	world_position.x = roundi(position.x / 4)
	world_position.y = roundi(position.y / 4)
	position = world_position
