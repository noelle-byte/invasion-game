extends Area2D

@onready var player = $"../../Player"
@onready var night_manager = $"../../NightManager"

# Temporary until the actual phone audio exists
@export var call_duration: float = 5.0

var player_nearby := false
var ringing := false
var call_playing := false


func _ready() -> void:
	night_manager.waiting_for_call.connect(_on_waiting_for_call)

	# NightManager may already have entered its safe state
	# before this node's _ready() runs.
	if not night_manager.game_running:
		start_ringing(night_manager.current_night)


func _process(_delta: float) -> void:
	if (
		ringing
		and player_nearby
		and Input.is_action_just_pressed("interact")
	):
		answer_phone()


func start_ringing(night: int) -> void:
	ringing = true

	print("PHONE RINGING - Night ", night)


func answer_phone() -> void:
	if call_playing:
		return

	ringing = false
	call_playing = true

	print("Phone answered")

	if night_manager.current_night == 1:
		print(
			"One of them will knock on your doors. "
			+ "Just knock back and you'll be fine. "
			+ "After a while it'll try to trick you and knock weird. "
			+ "Ignore it if it does that."
			+ "Call you back tomorrow."
		)

	await get_tree().create_timer(call_duration).timeout

	call_playing = false

	night_manager.start_night()


func _on_waiting_for_call(night: int) -> void:
	start_ringing(night)


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_nearby = false
