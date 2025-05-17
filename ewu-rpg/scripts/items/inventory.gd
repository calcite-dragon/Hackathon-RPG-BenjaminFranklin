extends Control

@export var selected_container = 0

var armor
var weapon
enum items {Empty = 0, WoodSword = 1, IronSword = 2, DiamondSword = 3, Potion = 4, LeatherArmor = 5, IronArmor = 6, DiamondArmor = 7}

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
	
	
