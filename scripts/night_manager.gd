extends Node

signal night_changed(night: int)
signal time_changed(time_remaining: float)
signal game_completed

# Length of one night in seconds
@export var night_duration: float = 120.0

# Total number of nights required to complete the game
@export var total_nights: int = 5

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D

@onready var flashlight = $"../Player/FlashlightPivot"

var current_night: int = 1
var time_remaining: float
var game_running := true


func _ready() -> void:
	start_night()


func _process(delta: float) -> void:
	if not game_running:
		return

	# Stop the night progressing after the player has died
	if player.is_dead:
		return

	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)

	time_changed.emit(time_remaining)

	if time_remaining <= 0.0:
		advance_night()


func start_night() -> void:
	time_remaining = night_duration

	# Update systems which become harder each night
	enemy.set_difficulty(current_night)
	flashlight.set_difficulty(current_night)

	night_changed.emit(current_night)

	print("Night ", current_night, " started")


func advance_night() -> void:
	current_night += 1

	if current_night > total_nights:
		game_running = false
		enemy.can_move = false
		print("All nights completed")
		game_completed.emit()
		return

	start_night()
