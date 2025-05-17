class_name Entity
extends Node

@export var base_health: int
@export var base_attack_damage: int
@export var base_defense: int

var location: Vector2i

var held_item: Item
var armor_item: Item
	
func get_health() -> int:
	return base_health + held_item.health + armor_item.health

func get_attack_damage() -> int:
	return base_attack_damage + held_item.attack_damage + armor_item.attack_damage
	
func get_defense() -> int:
	return base_defense + held_item.defense + armor_item.defense
