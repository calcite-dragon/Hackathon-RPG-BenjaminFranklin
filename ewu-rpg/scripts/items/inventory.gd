extends Control

@export var selected_container = 0

var armor
var weapon

func _init() -> void:
	pass

func _process(delta: float) -> void:
	clamp(selected_container, 0, 2)
	
	if(Input.is_action_just_pressed("scroll_up")):
		if(selected_container < 2):
			selected_container += 1
		else:
			selected_container = 0
	elif(Input.is_action_just_pressed("scroll_down")):
		if(selected_container > 0):
			selected_container -= 1
		else:
			selected_container = 2
	
	get_parent().get_parent()
	
	
