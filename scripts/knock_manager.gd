extends Node

@export var night_manager: Node
@onready var door = $"../Door"
@export var enemy: CharacterBody2D

enum KnockType {
	NONE,
	REAL,
	FALSE
}

# Chance of getting a knock opportunity:
# roll 1-20, success if roll <= AI level
@export_range(1, 20) var base_ai_level: int = 4

# AI becomes more active each night
@export var ai_increase_per_night: int = 3

# How often the AI gets a chance to attempt a knock
@export var check_interval: float = 5.0

# How long the player has to respond
@export var response_window: float = 4.0

# Hours after midnight when false knocks become possible
# Night 1 = 3AM
# Night 2 = 2:30AM
# Night 3 = 2AM
# Night 4 = 1AM
# Night 5 = immediately
@export var false_start_hours: Array[float] = [
	3.0,
	2.5,
	2.0,
	1.0,
	0.0
]

var ai_level: int
var false_start_hour: float

var check_time_remaining: float
var response_time_remaining: float

var current_knock = KnockType.NONE

# Temporary limitation while we only have one indoor enemy
var breach_active := false


func _ready() -> void:
	door.knocked_back.connect(_on_knocked_back)
	night_manager.night_changed.connect(_on_night_changed)

	check_time_remaining = check_interval


func _process(delta: float) -> void:
	if not night_manager.game_running:
		check_time_remaining = check_interval
		current_knock = KnockType.NONE
		return

	# For now, stop creating new knock encounters after a breach
	if breach_active:
		return

	# Deal with an active knock encounter first
	if current_knock != KnockType.NONE:
		response_time_remaining -= delta

		if response_time_remaining <= 0.0:
			_resolve_timeout()

		return

	# No current encounter, so count down to the next AI opportunity
	check_time_remaining -= delta

	if check_time_remaining <= 0.0:
		check_time_remaining = check_interval
		attempt_knock()


func _on_night_changed(night: int) -> void:
	ai_level = min(
		base_ai_level + ((night - 1) * ai_increase_per_night),
		20
	)

	var index: int = mini(night - 1, false_start_hours.size() - 1)
	false_start_hour = false_start_hours[index]

	breach_active = false
	current_knock = KnockType.NONE
	check_time_remaining = check_interval

	print("Knocker AI: ", ai_level)
	print("False knocks allowed after: ", false_start_hour, " AM")


func attempt_knock() -> void:
	var roll := randi_range(1, 20)

	print("Knock roll: ", roll, " / AI ", ai_level)

	if roll > ai_level:
		return

	var can_false: bool = (
		night_manager.get_hours_since_midnight() >= false_start_hour
	)

	if can_false and randi_range(0, 1) == 1:
		start_knock(KnockType.FALSE)
	else:
		start_knock(KnockType.REAL)


func start_knock(type: KnockType) -> void:
	current_knock = type
	response_time_remaining = response_window

	if type == KnockType.REAL:
		print("KNOCK KNOCK KNOCK - normal")
	else:
		print("KNOCK... KNOCK KNOCK - weird")


func _on_knocked_back() -> void:
	# Knocking when there is no encounter does nothing
	if current_knock == KnockType.NONE:
		print("Nothing answered")
		return

	# Correct response to a real knock
	if current_knock == KnockType.REAL:
		print("Real Knocker repelled")
		clear_encounter()
		return

	# Wrong response to a false knock
	if current_knock == KnockType.FALSE:
		print("You answered the false knock")
		breach()


func _resolve_timeout() -> void:
	# Ignoring a real knock lets it inside
	if current_knock == KnockType.REAL:
		print("Real knock was ignored")
		breach()
		return

	# Ignoring a false knock is the correct response
	if current_knock == KnockType.FALSE:
		print("False knock successfully ignored")
		clear_encounter()


func breach() -> void:
	breach_active = true

	enemy.breach_at(door.get_breach_position())

	clear_encounter()


func clear_encounter() -> void:
	current_knock = KnockType.NONE
	response_time_remaining = 0.0
