extends CharacterBody2D

# How quickly the creature can move through the house
@export var speed: float = 120.0

@export var target: CharacterBody2D

# NavigationAgent2D calculates the route around walls and through rooms
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	# Wait for Godot's navigation map to initialise before requesting a path
	await get_tree().physics_frame

	# Set the player's position as the creature's destination
	navigation_agent.target_position = target.global_position


func _physics_process(_delta: float) -> void:
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
