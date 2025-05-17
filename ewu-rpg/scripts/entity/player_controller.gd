extends GridMovement

func _process(delta: float) -> void:
	
	if(Input.is_action_just_pressed("move_N")):
		move(direction.N)
	elif(Input.is_action_just_pressed("move_S")):
		move(direction.S)
	elif(Input.is_action_just_pressed("move_E")):
		move(direction.E)
	elif(Input.is_action_just_pressed("move_W")):
		move(direction.W)
	
	set_pos()
