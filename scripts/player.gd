extends CharacterBody2D

# Controls how quickly the player moves
@export var speed: float = 300.0

# Allows other systems to disable player movement when needed
var can_move := true


func _physics_process(_delta: float) -> void:
	# Stop all movement if control has been disabled
	if not can_move:
		velocity = Vector2.ZERO
		return

	# Combine the four movement inputs into one direction vector
	# Input.get_vector also prevents diagonal movement being faster
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	# Convert the input direction into the player's velocity
	velocity = direction * speed

	# Move the CharacterBody2D while respecting collisions
	move_and_slide()
