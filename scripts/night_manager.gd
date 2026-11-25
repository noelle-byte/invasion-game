extends Node

signal night_changed(night: int)
signal time_changed(time_remaining: float)
signal waiting_for_call(night: int)
signal game_completed

@export var night_duration: float = 120.0
@export var total_nights: int = 5

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var wraith: CharacterBody2D
@export var wraith_spawn_points: Node2D

@onready var flashlight = $"../Player/FlashlightPivot"

var current_night: int = 1
var time_remaining: float
var game_running := false


func _ready() -> void:
	current_night = GameSettings.starting_night
	flashlight.set_difficulty(current_night)
	prepare_night.call_deferred()


func _process(delta: float) -> void:
	if not game_running:
		return

	if player.is_dead:
		return

	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)

	time_changed.emit(time_remaining)

	if time_remaining <= 0.0:
		advance_night()


func prepare_night() -> void:
	game_running = false

	# Safe period before answering the phone
	enemy.set_active(false)
	wraith.set_active(false)

	waiting_for_call.emit(current_night)

	print("Night ", current_night, " waiting for phone")


func start_night() -> void:
	if game_running or player.is_dead:
		return

	game_running = true
	time_remaining = night_duration

	enemy.set_difficulty(current_night)
	flashlight.set_difficulty(current_night)

	if current_night >= 2 and current_night <= total_nights:
		wraith.set_difficulty(current_night)
		# Spawn at the furthest marker and give the player time to react.
		var furthest: Marker2D = null
		for point in wraith_spawn_points.get_children():
			if point is Marker2D and (furthest == null or point.global_position.distance_squared_to(player.global_position) > furthest.global_position.distance_squared_to(player.global_position)):
				furthest = point
		if furthest != null:
			wraith.global_position = furthest.global_position
			wraith.set_active(true)

	night_changed.emit(current_night)

	print("Night ", current_night, " started")


func advance_night() -> void:
	current_night += 1

	if current_night > total_nights:
		game_running = false
		enemy.set_active(false)
		wraith.set_active(false)

		print("All nights completed")
		game_completed.emit()
		return

	prepare_night()


# Returns a value from 0 to 6:
# 0 = 12 AM
# 3 = 3 AM
# 6 = 6 AM
func get_hours_since_midnight() -> float:
	if not game_running:
		return 0.0

	var progress := 1.0 - (time_remaining / night_duration)

	return clamp(progress * 6.0, 0.0, 6.0)
