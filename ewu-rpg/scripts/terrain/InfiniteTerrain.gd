class_name InfiniteTerrain
extends Node2D

# Tilemap configuration
@export var tile_size: int = 8
@export_category("Chunk Settings")
@export var chunk_size: int = 32  # Size in tiles
@export var view_distance: int = 3  # Number of chunks in each direction
@export var player_node_path: NodePath

@export_category("Noise Settings")
@export var height_noise_scale: float = 0.05
@export var height_noise_octaves: int = 4
@export var height_noise_seed: int = 1234
@export var temp_noise_scale: float = 0.03
@export var temp_noise_octaves: int = 3
@export var temp_noise_seed: int = 5678

@export_category("Biome Settings")
@export var snow_threshold: float = 0.45  # Temperature below this is snow
@export var mountain_threshold: float = 0.75  # Height above this is mountain (rockier)
@export var forest_threshold: float = 0.45  # Height below this is forest (more trees)

@export_category("Decoration Settings")
@export var tree_density: float = 0.3  # Higher means more trees
@export var rock_density: float = 0.15  # Higher means more rocks
@export var poisson_radius: float = 2.5  # Minimum distance between objects in tiles

# Internal variables
var _height_noise: FastNoiseLite
var _temp_noise: FastNoiseLite
var _loaded_chunks = {}
var _player: Node2D
var _current_player_chunk: Vector2i
var _thread: Thread
var _exit_thread: bool = false

# Tile atlas coordinates based on user's tileset
var GRASS_TILE = Vector2i(0, 0)
var TREE_TILE = Vector2i(1, 0)
var ROCK_TILE = Vector2i(2, 0)
var SNOW_TILE = Vector2i(0, 1)
var SNOW_TREE_TILE = Vector2i(1, 1)
var SNOW_ROCK_TILE = Vector2i(2, 1)

func _ready():
	if player_node_path:
		_player = get_node(player_node_path)
	
	# Setup noise generators
	_setup_noise()
	
	# Start thread for chunk management
	_thread = Thread.new()
	_thread.start(_thread_function)

func _exit_tree():
	_exit_thread = true
	_thread.wait_to_finish()

func _setup_noise():
	# Height noise
	_height_noise = FastNoiseLite.new()
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_height_noise.seed = height_noise_seed
	_height_noise.frequency = height_noise_scale
	_height_noise.fractal_octaves = height_noise_octaves
	
	# Temperature noise
	_temp_noise = FastNoiseLite.new()
	_temp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_temp_noise.seed = temp_noise_seed
	_temp_noise.frequency = temp_noise_scale
	_temp_noise.fractal_octaves = temp_noise_octaves

func _thread_function():
	while not _exit_thread:
		if _player != null:
			var player_pos = _player.world_position
			var current_chunk = Vector2i(
				floor(float(player_pos.x) / (chunk_size)),
				floor(float(player_pos.y) / (chunk_size))
			)
			
			if current_chunk != _current_player_chunk:
				_current_player_chunk = current_chunk
				call_deferred("_update_chunks", current_chunk)
		
		OS.delay_msec(500)  # Check every half second

func _update_chunks(center_chunk: Vector2i):
	var chunks_to_remove = []
	var chunks_to_keep = []
	
	# Determine which chunks to keep/load
	for x in range(center_chunk.x - view_distance, center_chunk.x + view_distance + 1):
		for y in range(center_chunk.y - view_distance, center_chunk.y + view_distance + 1):
			var chunk_pos = Vector2i(x, y)
			chunks_to_keep.append(chunk_pos)
			
			if not _loaded_chunks.has(chunk_pos):
				call_deferred("_generate_chunk", chunk_pos)
	
	# Find chunks to remove
	for chunk_pos in _loaded_chunks.keys():
		if not chunks_to_keep.has(chunk_pos):
			chunks_to_remove.append(chunk_pos)
	
	# Remove out-of-range chunks
	for chunk_pos in chunks_to_remove:
		call_deferred("_remove_chunk", chunk_pos)

func _generate_chunk(chunk_pos: Vector2i):
	# Get the tilemap layer
	var parent_node = get_parent()
	var tilemap_layer = parent_node.get_node("Environment/TileMapLayer")
	
	# Calculate world coordinates for chunk
	var chunk_world_x = chunk_pos.x * chunk_size
	var chunk_world_y = chunk_pos.y * chunk_size
	
	# Generate the base terrain first
	for y in range(chunk_size):
		for x in range(chunk_size):
			var world_x = chunk_world_x + x
			var world_y = chunk_world_y + y
			
			# Get height and temperature values (using rotated coordinates for more interesting patterns)
			var height = get_height_at(world_x, world_y)
			var temperature = get_temperature_at(world_x, world_y)
			
			# Determine base tile type based on temperature
			var tile_pos = Vector2i(world_x, world_y)
			var atlas_coords: Vector2i
			
			if temperature < snow_threshold:
				atlas_coords = SNOW_TILE  # Snow
			else:
				atlas_coords = GRASS_TILE  # Grass
			
			# Set base terrain tile
			tilemap_layer.set_cell(tile_pos, 0, atlas_coords, 0)
			
			# No obstacles for base terrain
			var tile_data = tilemap_layer.get_cell_tile_data(tile_pos)
			if tile_data:
				tile_data.set_custom_data("obstacle", false)
	
	# Now place decorations using Poisson disk sampling
	var points = _generate_poisson_disk_samples(chunk_pos)
	
	for point in points:
		var world_x = chunk_world_x + point.x
		var world_y = chunk_world_y + point.y
		var tile_pos = Vector2i(world_x, world_y)
		
		# Get height and temperature again for this specific point
		var height = get_height_at(world_x, world_y)
		var temperature = get_temperature_at(world_x, world_y)
		
		# Determine if this should be a tree or rock
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(str(world_x) + str(world_y))
		var random_val = rng.randf()
		
		# Tree-to-rock ratio varies based on height
		var local_tree_density = tree_density
		var local_rock_density = rock_density
		
		if height > mountain_threshold:
			# Rocky terrain: more rocks, fewer trees
			local_tree_density *= 0.3
			local_rock_density *= 2.0
		elif height < forest_threshold:
			# Forest terrain: more trees, fewer rocks
			local_tree_density *= 1.5
			local_rock_density *= 0.5
		
		var tile_type: Vector2i
		var is_obstacle = true
		
		if random_val < local_tree_density:
			# Place a tree
			if temperature < snow_threshold:
				tile_type = SNOW_TREE_TILE
			else:
				tile_type = TREE_TILE
		elif random_val < local_tree_density + local_rock_density:
			# Place a rock
			if temperature < snow_threshold:
				tile_type = SNOW_ROCK_TILE
			else:
				tile_type = ROCK_TILE
		else:
			# Skip this point
			continue
		
		# Set the decoration tile
		tilemap_layer.set_cell(tile_pos, 0, tile_type, 0)
		
		# Set as obstacle
		var tile_data = tilemap_layer.get_cell_tile_data(tile_pos)
		if tile_data:
			tile_data.set_custom_data("obstacle", true)
	
	# Mark chunk as loaded
	_loaded_chunks[chunk_pos] = true

func _remove_chunk(chunk_pos: Vector2i):
	if _loaded_chunks.has(chunk_pos):
		# Clear the tiles in this chunk
		var parent_node = get_parent()
		var tilemap_layer = parent_node.get_node("Environment/TileMapLayer")
		
		var chunk_world_x = chunk_pos.x * chunk_size
		var chunk_world_y = chunk_pos.y * chunk_size
		
		for y in range(chunk_size):
			for x in range(chunk_size):
				var world_x = chunk_world_x + x
				var world_y = chunk_world_y + y
				var tile_pos = Vector2i(world_x, world_y)
				
				# Remove tile
				tilemap_layer.erase_cell(tile_pos)
		
		# Remove from loaded chunks
		_loaded_chunks.erase(chunk_pos)

func _generate_poisson_disk_samples(chunk_pos: Vector2i) -> Array:
	var points = []
	var active_points = []
	var cell_size = poisson_radius / sqrt(2)
	
	# Grid dimensions
	var grid_width = int(ceil(chunk_size / cell_size))
	var grid_height = int(ceil(chunk_size / cell_size))
	
	# Initialize grid
	var grid = []
	grid.resize(grid_width * grid_height)
	for i in range(grid.size()):
		grid[i] = -1
	
	# Add initial random point
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(chunk_pos.x) + str(chunk_pos.y))
	
	var initial_point = Vector2(rng.randf() * chunk_size, rng.randf() * chunk_size)
	var initial_index = _point_to_grid_index(initial_point, cell_size, grid_width)
	
	if initial_index >= 0 and initial_index < grid.size():
		points.append(initial_point)
		grid[initial_index] = 0
		active_points.append(0)
	
	# Try to add new points
	while active_points.size() > 0:
		var random_index = rng.randi() % active_points.size()
		var point_index = active_points[random_index]
		var point = points[point_index]
		
		var found_new_point = false
		
		# Try to find a valid new point
		for k in range(30):
			var angle = rng.randf() * TAU
			var distance = poisson_radius + rng.randf() * poisson_radius
			var new_point = Vector2(point.x + cos(angle) * distance, point.y + sin(angle) * distance)
			
			# Check if point is in bounds
			if new_point.x < 0 or new_point.x >= chunk_size or new_point.y < 0 or new_point.y >= chunk_size:
				continue
			
			# Check if point is valid
			if _is_point_valid(new_point, grid, points, cell_size, grid_width):
				var new_index = _point_to_grid_index(new_point, cell_size, grid_width)
				
				if new_index >= 0 and new_index < grid.size():
					points.append(new_point)
					grid[new_index] = points.size() - 1
					active_points.append(points.size() - 1)
					found_new_point = true
					break
		
		if not found_new_point:
			active_points.remove_at(random_index)
	
	return points

func _is_point_valid(point: Vector2, grid: Array, points: Array, cell_size: float, grid_width: int) -> bool:
	var grid_x = int(point.x / cell_size)
	var grid_y = int(point.y / cell_size)
	
	# Check neighborhood
	for y in range(max(0, grid_y - 2), min(int(ceil(chunk_size / cell_size)), grid_y + 3)):
		for x in range(max(0, grid_x - 2), min(grid_width, grid_x + 3)):
			var grid_index = y * grid_width + x
			
			if grid_index < 0 or grid_index >= grid.size():
				continue
				
			var neighbor_index = grid[grid_index]
			
			if neighbor_index != -1:
				var neighbor_point = points[neighbor_index]
				var distance = point.distance_to(neighbor_point)
				
				if distance < poisson_radius:
					return false
	
	return true

func _point_to_grid_index(point: Vector2, cell_size: float, grid_width: int) -> int:
	var grid_x = int(point.x / cell_size)
	var grid_y = int(point.y / cell_size)
	return grid_y * grid_width + grid_x

# Get height value at a specific world position
func get_height_at(world_x: float, world_y: float) -> float:
	var angle = 0.5
	var rotated_x = world_x * cos(angle) - world_y * sin(angle)
	var rotated_y = world_x * sin(angle) + world_y * cos(angle)
	return (_height_noise.get_noise_2d(rotated_x, rotated_y) + 1) * 0.5

# Get temperature value at a specific world position
func get_temperature_at(world_x: float, world_y: float) -> float:
	var temp_angle = 1.3
	var temp_rotated_x = world_x * cos(temp_angle) - world_y * sin(temp_angle)
	var temp_rotated_y = world_x * sin(temp_angle) + world_y * cos(temp_angle)
	return (_temp_noise.get_noise_2d(temp_rotated_x, temp_rotated_y) + 1) * 0.5
