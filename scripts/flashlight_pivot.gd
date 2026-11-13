extends Node2D

signal battery_changed(current_battery: float, max_battery: float)

# Maximum amount of flashlight charge
@export var max_battery: float = 100.0

# Amount of battery consumed each second
@export var battery_drain_rate: float = 3.5

# Used later to increase battery drain on harder nights
@export var drain_increase_per_night: float = 0.5

@onready var flashlight: PointLight2D = $flashlight

@export var flash_range: float = 700.0
@export var flash_half_angle_degrees: float = 30.0
@export var flash_visual_duration: float = 0.12
@export var flash_energy: float = 4.0

@onready var flash_ray: RayCast2D = $FlashRay

var current_night: int = 1
var flash_in_progress := false

var battery: float
var flashlight_on := true


func _ready() -> void:
	# Begin each game with a fully charged flashlight
	flash_ray.add_exception(get_parent())
	battery = max_battery
	flashlight.enabled = true


func _process(delta: float) -> void:
	# Rotate the flashlight towards the mouse
	look_at(get_global_mouse_position())

	# Toggle the flashlight when the flashlight input is pressed
	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()

	# Consume battery while the flashlight is active
	if flashlight_on and not flash_in_progress:
		drain_battery(delta)
	
	if Input.is_action_just_pressed("flash"):
		attempt_flash()


func toggle_flashlight() -> void:
	# An empty flashlight cannot be switched back on
	if battery <= 0.0 and not flashlight_on:
		return

	flashlight_on = not flashlight_on
	flashlight.enabled = flash_in_progress or flashlight_on


func drain_battery(delta: float) -> void:
	battery -= battery_drain_rate * delta
	battery = max(battery, 0.0)

	battery_changed.emit(battery, max_battery)

	if battery <= 0.0:
		flashlight_on = false
		flashlight.enabled = false


func set_difficulty(night: int) -> void:
	current_night = night
	battery_drain_rate = 3.0 + ((night - 1) * drain_increase_per_night)
	print("Battery drain: ", battery_drain_rate)

func add_battery(amount: float) -> void:
	battery += amount
	battery = min(battery, max_battery)

	battery_changed.emit(battery, max_battery)

func attempt_flash() -> void:
	if flash_in_progress:
		return

	var flash_cost: float = 10.0 + (3.0 * current_night)

	if battery < flash_cost:
		print("Not enough battery to flash")
		return

	battery -= flash_cost
	battery_changed.emit(battery, max_battery)

	flash_in_progress = true

	# Briefly make the flashlight extremely bright
	var normal_energy: float = flashlight.energy
	flashlight.enabled = true
	flashlight.energy = flash_energy

	for enemy in get_tree().get_nodes_in_group("flashable"):
		if enemy is Node2D and enemy.has_method("receive_flash") and enemy_in_flash(enemy):
			enemy.receive_flash()

	await get_tree().create_timer(flash_visual_duration).timeout

	if battery <= 0.0:
		flashlight_on = false
	flashlight.energy = normal_energy
	flashlight.enabled = flashlight_on
	flash_in_progress = false

func enemy_in_flash(enemy: Node2D) -> bool:
	if not enemy.is_visible_in_tree():
		return false
	var to_enemy: Vector2 = enemy.global_position - global_position

	if to_enemy.length() > flash_range:
		return false

	var flashlight_direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	var angle: float = absf(flashlight_direction.angle_to(to_enemy.normalized()))

	if angle > deg_to_rad(flash_half_angle_degrees):
		return false

	# Make sure a wall isn't between the flashlight and the creature
	flash_ray.target_position = flash_ray.to_local(enemy.global_position)
	flash_ray.force_raycast_update()

	return flash_ray.is_colliding() and flash_ray.get_collider() == enemy
