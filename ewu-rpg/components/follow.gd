extends Sprite2D

const FOLLOW_SPEED = 10.0

func _physics_process(delta):
	var follow_pos = $"../Player".position

	position = position.lerp(follow_pos, delta * FOLLOW_SPEED)
