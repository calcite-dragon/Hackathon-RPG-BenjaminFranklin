extends GridMovement
@onready var healthbar = $"../CharacterSprite/Camera2D/Control/HealthBar"

@export var health: int

func _ready() -> void:
	health = 100

func _process(delta: float) -> void:
	
	healthbar.value = health
	
	if(Input.is_action_just_pressed("move_N")):
		move(direction.N)
	elif(Input.is_action_just_pressed("move_S")):
		move(direction.S)
	elif(Input.is_action_just_pressed("move_E")):
		move(direction.E)
	elif(Input.is_action_just_pressed("move_W")):
		move(direction.W)
	
	set_pos()

func take_damage(amount: int) -> void:
	if(health > 0 && health-amount > 0):
		health -= amount

func heal(amount: int) -> void:
	if(health+amount <= 100):
		health += amount
	if(health+amount > 100):
		health = 100
