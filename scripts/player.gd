class_name PlayerCharacter
extends CharacterBody2D

signal stamina_changed(current_stamina: float, max_stamina: float)

@export var walk_speed: float = 300.0
@export var run_speed: float = 450.0

@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 30.0
@export var stamina_recovery_rate: float = 20.0
@export var stamina_resume_threshold: float = 25.0

var exhausted := false
var stamina: float = max_stamina
var is_running := false

var can_move := true
var is_dead := false

func die() -> void:
	print("ive been got")
	if is_dead:
		return
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	
	print("player died")

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		is_running = false
		return

	var direction := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)

	if stamina <= 0.0:
		exhausted = true

	if exhausted and stamina >= stamina_resume_threshold:
		exhausted = false
	
	var wants_to_run := (
		Input.is_action_pressed("run")
		and direction != Vector2.ZERO
		and not exhausted
	)

	is_running = wants_to_run

	var current_speed := walk_speed

	if is_running:
		current_speed = run_speed
		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0.0)
	else:
		stamina += stamina_recovery_rate * delta
		stamina = min(stamina, max_stamina)

	stamina_changed.emit(stamina, max_stamina)

	velocity = direction * current_speed
	move_and_slide()
