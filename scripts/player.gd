extends CharacterBody2D

@onready var camera: Camera2D = $"../house/Camera2D"
# rename the camera to make my life easier

@export var speed = 300.0
var can_move := true # conditions to take control away if the player dies or something
var failed := false 


func _physics_process(_delta: float) -> void:
	if not can_move: # force stop the player if they should not be able to move
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)
	velocity = (direction * speed)

	move_and_slide()

	_check_rock_collisions()

	if failed:
		return


func _check_rock_collisions() -> void:
	var screen_height := get_viewport_rect().size.y

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider == null:
			continue

		if not collider.is_in_group("obstacle"):
			continue
