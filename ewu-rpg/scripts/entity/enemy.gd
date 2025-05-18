class_name Monster
extends GridMovement

# Detection range (in grid cells)
@export var detection_range: int = 5
# How often the monster makes a move (in seconds)
@export var move_interval: float = 0.5
# Entity stats reference if you want to use the Entity system
@export var entity_stats: Entity

# Timer for movement
var move_timer: float = 0.0
# Reference to the player
var player: Node2D

# Called when the node enters the scene tree
func _ready() -> void:
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		# Fallback to finding by node path if not in a group
		player = get_node_or_null("/root/World/Player")

func _process(delta: float) -> void:
	# Call parent process which handles position updates
	super._process(delta)
	
	# Update move timer
	move_timer += delta
	
	# Only move after the interval has elapsed
	if move_timer >= move_interval:
		move_timer = 0.0
		
		# Choose action based on player detection
		if is_player_detected():
			chase_player()
		else:
			wander_randomly()

# Check if player is within detection range
func is_player_detected() -> bool:
	if player == null:
		return false
	
	# Calculate Manhattan distance (grid-based distance)
	var distance = abs(world_position.x - player.world_position.x) + abs(world_position.y - player.world_position.y)
	
	return distance <= detection_range

# Move toward the player
func chase_player() -> void:
	# Determine the direction that gets us closer to the player
	var x_diff = player.world_position.x - world_position.x
	var y_diff = player.world_position.y - world_position.y
	
	# Choose which direction to move (prioritize larger difference)
	if abs(x_diff) > abs(y_diff):
		# Move horizontally
		if x_diff > 0:
			move(direction.E)
		else:
			move(direction.W)
	else:
		# Move vertically
		if y_diff > 0:
			move(direction.S)
		else:
			move(direction.N)

# Move in a random direction
func wander_randomly() -> void:
	# Generate a random direction
	var random_dir = randi() % 4
	
	# Attempt to move in that direction
	move(random_dir)

# Handle collision with player (if needed)
func _on_area_entered(area):
	if area.is_in_group("player"):
		# Attack the player if you want combat
		if entity_stats != null and player.entity_stats != null:
			var damage = entity_stats.get_attack_damage() - player.entity_stats.get_defense()
			# Apply damage to player
			# This would depend on how your game handles damage
