extends CharacterBody2D

@export var starts_active := false

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea

# How quickly the creature can move through the house
@export var base_speed: float = 340.0
@export var speed_increase_per_night: float = 15.0

var speed: float
var can_move := true

@export var target: PlayerCharacter

# NavigationAgent2D calculates the route around walls and through rooms
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var breach_grace_period: float = 2.5

var can_attack := false

enum BehaviourState {
	ROAM,
	HUNT,
	CHASE
}

@export_range(0.0, 100.0) var aggression: float = 0.0

@export var sight_aggression_rate: float = 30.0
@export var running_aggression_rate: float = 18.0
@export var aggression_decay_rate: float = 6.0

@export var running_hearing_radius: float = 550.0

@onready var sight_ray: RayCast2D = $SightRay

var behaviour_state := BehaviourState.ROAM
var last_known_position := Vector2.ZERO
var sees_player := false

func _ready() -> void:
	speed = base_speed

	set_active(starts_active)

	await get_tree().physics_frame

func set_active(value: bool) -> void:
	can_move = value
	visible = value

	if not value:
		can_attack = false
		aggression = 0.0
		behaviour_state = BehaviourState.ROAM
		last_known_position = Vector2.ZERO
		sees_player = false

	body_collision.set_deferred("disabled", not value)
	attack_area.set_deferred("monitoring", value)

func update_awareness(delta: float) -> void:
	sees_player = can_see_player()

	var distance_to_player := global_position.distance_to(
		target.global_position
	)

	var hears_running := (
		target.is_running
		and distance_to_player <= running_hearing_radius
	)

	# Seeing the player strongly increases aggression
	if sees_player:
		aggression += sight_aggression_rate * delta
		last_known_position = target.global_position

	# Running is noisy even through walls
	if hears_running:
		aggression += running_aggression_rate * delta
		last_known_position = target.global_position

	# Calm down if neither sense is currently detecting the player
	if not sees_player and not hears_running:
		aggression -= aggression_decay_rate * delta

	aggression = clamp(aggression, 0.0, 100.0)

	update_behaviour_state()

func can_see_player() -> bool:
	sight_ray.target_position = to_local(target.global_position)
	sight_ray.force_raycast_update()

	if not sight_ray.is_colliding():
		return false

	return sight_ray.get_collider() == target

func update_behaviour_state() -> void:
	match behaviour_state:
		BehaviourState.ROAM:
			if aggression >= 35.0:
				behaviour_state = BehaviourState.HUNT
				print("Enemy is hunting")

		BehaviourState.HUNT:
			if aggression >= 70.0:
				behaviour_state = BehaviourState.CHASE
				print("Enemy is chasing")
			elif aggression < 20.0:
				behaviour_state = BehaviourState.ROAM
				print("Enemy calmed down")

		BehaviourState.CHASE:
			if aggression < 55.0:
				behaviour_state = BehaviourState.HUNT
				print("Enemy lost the player")

func update_navigation_target() -> void:
	match behaviour_state:
		BehaviourState.ROAM:
			return

		BehaviourState.HUNT:
			navigation_agent.target_position = last_known_position

		BehaviourState.CHASE:
			if sees_player:
				navigation_agent.target_position = target.global_position
			else:
				navigation_agent.target_position = last_known_position

func breach_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	set_active(true)

	can_move = false
	can_attack = false

	# The creature knows roughly where the player was when it entered
	last_known_position = target.global_position

	print("Enemy entered the house")

	await get_tree().create_timer(breach_grace_period).timeout

	if not visible:
		return

	aggression = 35.0
	behaviour_state = BehaviourState.HUNT

	can_move = true
	can_attack = true

	try_attack_player()

	print("Enemy is now hunting")

func set_difficulty(night: int) -> void:
	speed = base_speed + ((night - 1) * speed_increase_per_night)
	print("Enemy speed: ", speed)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	update_awareness(delta)
	update_navigation_target()

	if behaviour_state == BehaviourState.ROAM:
		velocity = Vector2.ZERO
		return

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)

	velocity = direction * speed
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
