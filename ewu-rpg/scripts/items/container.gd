extends Sprite2D

@export var item: items = 1
@export var type: cont_type

enum cont_type {Armor, Weapon, Item1, Item2, Item3}
enum items {Empty = 0, WoodSword = 1, IronSword = 2, DiamondSword = 3, Potion = 4, LeatherArmor = 5, IronArmor = 6, DiamondArmor = 7}

func _process(delta: float) -> void:
	$Sprite2D.frame = item
	
	if(type == cont_type.Item1):
		if(self.get_parent().selected_container == 0):
			frame = 0
			handle_input()
		else:
			frame = 1
	
	if(type == cont_type.Item2):
		if(self.get_parent().selected_container == 1):
			frame = 0
			handle_input()
		else:
			frame = 1
	
	if(type == cont_type.Item3):
		if(self.get_parent().selected_container == 2):
			frame = 0
			handle_input()
		else:
			frame = 1
	
	if(type == cont_type.Armor):
		if(item == items.LeatherArmor):
			get_parent().get_parent().get_parent().frame = 4
		elif(item == items.IronArmor):
			get_parent().get_parent().get_parent().frame = 8
		elif(item == items.DiamondArmor):
			get_parent().get_parent().get_parent().frame = 12
	
	if(type == cont_type.Weapon):
		pass

func handle_input() -> void:
	if(Input.is_action_just_pressed("use")):
		if(item == items.Potion):
			if($"../../../../Player".health != 100):
				$"../../../../Player".heal(34)
				item = items.Empty
