extends Sprite2D

@export var item: items = 1
@export var type: cont_type

enum cont_type {Armor, Weapon, Item1, Item2, Item3}
enum items {Empty = 0, WoodSword = 1, IronSword = 2, DiamondSword = 3, LeatherArmor = 6, IronArmor = 7, DiamondArmor = 8}

func _process(delta: float) -> void:
	$Sprite2D.frame = item
	
	if(type == cont_type.Item1):
		if(self.get_parent().selected_container == 0):
			frame = 0
		else:
			frame = 1
	if(type == cont_type.Item2):
		if(self.get_parent().selected_container == 1):
			frame = 0
		else:
			frame = 1
	if(type == cont_type.Item3):
		if(self.get_parent().selected_container == 2):
			frame = 0
		else:
			frame = 1
