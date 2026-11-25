extends CharacterBody2D

# Unlike the Knocker, the Wraith always knows where the player is. It moves
# directly, without collision movement or a navigation path, so walls cannot stop it.
@export var target: PlayerCharacter
@export var speed: float = 100.0
@export var spawn_grace: float = 3.0
@export var flash_disable_duration: float = 6.0
@export var repel_distance: float = 250.0
@export var attack_distance: float = 45.0

var active := false
var grace_remaining := 0.0
var disable_remaining := 0.0

func _ready() -> void:
	add_to_group("flashable")
	set_active(false)

func set_active(value: bool) -> void:
	active = value
	visible = value
	grace_remaining = spawn_grace if value else 0.0
	disable_remaining = 0.0
	# The body can be hit by the flash ray, but never blocks movement.
	$CollisionShape2D.set_deferred("disabled", not value)

func _physics_process(delta: float) -> void:
	if not active or target == null or target.is_dead:
		return
	if grace_remaining > 0.0:
		grace_remaining = maxf(0.0, grace_remaining - delta)
		return
	if disable_remaining > 0.0:
		disable_remaining = maxf(0.0, disable_remaining - delta)
		return

	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_distance:
		target.die()
		return
	# Clamp the step so a large frame cannot skip past the player.
	global_position = global_position.move_toward(target.global_position, speed * delta)
	if global_position.distance_to(target.global_position) <= attack_distance:
		target.die()

func receive_flash() -> void:
	if not active or target == null:
		return
	disable_remaining = maxf(disable_remaining, flash_disable_duration)
	var away := target.global_position.direction_to(global_position)
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	global_position += away * repel_distance
