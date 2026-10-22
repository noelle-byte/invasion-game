extends Node2D

signal battery_changed(current_battery: float, max_battery: float)

# Maximum amount of flashlight charge
@export var max_battery: float = 100.0

# Amount of battery consumed each second
@export var battery_drain_rate: float = 3.0

# Used later to increase battery drain on harder nights
@export var drain_increase_per_night: float = 0.5

@onready var flashlight: PointLight2D = $flashlight
@onready var battery_label: Label = $"../BatteryLabel"

var battery: float
var flashlight_on := true


func _ready() -> void:
	# Begin each game with a fully charged flashlight
	battery = max_battery
	flashlight.enabled = true
	update_battery_display()


func _process(delta: float) -> void:
	# Rotate the flashlight towards the mouse
	look_at(get_global_mouse_position())

	# Toggle the flashlight when the flashlight input is pressed
	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()

	# Consume battery while the flashlight is active
	if flashlight_on:
		drain_battery(delta)


func toggle_flashlight() -> void:
	# A completely empty flashlight cannot be switched back on
	if battery <= 0.0 and not flashlight_on:
		return

	flashlight_on = not flashlight_on
	flashlight.enabled = flashlight_on


func drain_battery(delta: float) -> void:
	battery -= battery_drain_rate * delta
	battery = max(battery, 0.0)

	update_battery_display()
	battery_changed.emit(battery, max_battery)

	if battery <= 0.0:
		flashlight_on = false
		flashlight.enabled = false


func set_difficulty(night: int) -> void:
	battery_drain_rate = 3.0 + ((night - 1) * drain_increase_per_night)
	print("Battery drain: ", battery_drain_rate)

func add_battery(amount: float) -> void:
	battery += amount
	battery = min(battery, max_battery)

	update_battery_display()
	battery_changed.emit(battery, max_battery)

func update_battery_display() -> void:
	battery_label.text = str(roundi(battery))
