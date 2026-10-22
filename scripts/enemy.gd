extends CharacterBody2D

@export var starts_active := false

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea

# How quickly the creature can move through the house
@export var base_speed: float = 120.0
@export var speed_increase_per_night: float = 15.0

var speed: float
var can_move := true

@export var target: CharacterBody2D

# NavigationAgent2D calculates the route around walls and through rooms
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var breach_grace_period: float = 2.5

var can_attack := false


func _ready() -> void:
	speed = base_speed

	set_active(starts_active)

	await get_tree().physics_frame
	navigation_agent.target_position = target.global_position

func set_active(value: bool) -> void:
	can_move = value
	visible = value

	# Disable physical collision while the creature is outside
	body_collision.set_deferred("disabled", not value)

	# Disable its kill area while outside
	attack_area.set_deferred("monitoring", value)


func breach_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	set_active(true)

	# Give the player time to react to the breach
	can_move = false
	can_attack = false

	print("Enemy entered the house")

	await get_tree().create_timer(breach_grace_period).timeout

	can_move = true
	can_attack = true

	try_attack_player()

	print("Enemy is now hunting")

func set_difficulty(night: int) -> void:
	speed = base_speed + ((night - 1) * speed_increase_per_night)
	print("Enemy speed: ", speed)

func _physics_process(_delta: float) -> void:
	# no moving when your not supposed to be moving
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	# Continuously update the target because the player is moving
	navigation_agent.target_position = target.global_position

	# Stop moving once the creature has reached the target
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	# Ask the navigation system for the next point along the calculated path
	var next_position := navigation_agent.get_next_path_position()

	# Move toward the next path point rather than directly toward the player
	var direction := global_position.direction_to(next_position)
	velocity = direction * speed

	# no moving through walls please
	move_and_slide()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if can_attack and body == target:
		target.die()

func try_attack_player() -> void:
	if not can_attack:
		return

	for body in attack_area.get_overlapping_bodies():
		if body == target:
			target.die()
			return
