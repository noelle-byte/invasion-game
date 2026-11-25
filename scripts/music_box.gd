extends Area2D

# Charge is measured in Night 1 seconds; later nights drain it faster.
@export var capacity: float = 45.0
@export var wind_rate: float = 6.0
@export var drain_increase_per_night: float = 0.15
@onready var player: PlayerCharacter = $"../Player"
@onready var night_manager: Node = $"../NightManager"

var remaining: float
var expired := false
var player_nearby := false

func _ready() -> void:
	remaining = capacity
	night_manager.waiting_for_call.connect(_reset_for_night)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _reset_for_night(_night: int) -> void:
	remaining = capacity
	expired = false
	night_manager.set_music_box_penalty(false)

func _process(delta: float) -> void:
	if not night_manager.game_running or player.is_dead or expired:
		return
	var drain_rate := 1.0 + maxf(0.0, night_manager.current_night - 1) * drain_increase_per_night
	if player_nearby and Input.is_action_pressed("interact"):
		remaining = clampf(remaining + (wind_rate - drain_rate) * delta, 0.0, capacity)
	else:
		remaining = maxf(0.0, remaining - drain_rate * delta)
	if remaining <= 0.0:
		expired = true
		night_manager.set_music_box_penalty(true)

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_nearby = false
