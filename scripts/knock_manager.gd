extends Node

@export var night_manager: Node
@onready var doors: Array[Area2D] = [
	$"../Door/Area2D",
	$"../Door2/Area2D"
]
@onready var sound_cues: Node = $"../SoundCues"
# Both patterns use the same cue; only their rhythm differs.
const REAL_KNOCK_TIMES: Array[float] = [0.0, 0.45, 0.9]
const FALSE_KNOCK_TIMES: Array[float] = [0.0, 0.9, 1.15]
var knock_times: Array[float] = []
var knock_elapsed: float = 0.0
var next_knock: int = 0

var current_door: Area2D
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
@export var response_window: float = 12.0

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
	for door in doors:
		door.knocked_back.connect(_on_knocked_back.bind(door))

	night_manager.night_changed.connect(_on_night_changed)

	check_time_remaining = check_interval

func start_knock(type: KnockType) -> void:
	current_knock = type
	current_door = doors.pick_random()
	response_time_remaining = response_window
	knock_times = REAL_KNOCK_TIMES if type == KnockType.REAL else FALSE_KNOCK_TIMES
	knock_elapsed = 0.0
	next_knock = 0
	update_knock_sounds(0.0)

	if type == KnockType.REAL:
		print("KNOCK KNOCK KNOCK - normal at ", current_door.get_parent().name)
	else:
		print("KNOCK... KNOCK KNOCK - weird at ", current_door.get_parent().name)

func update_knock_sounds(delta: float) -> void:
	knock_elapsed += delta
	while next_knock < knock_times.size() and knock_elapsed >= knock_times[next_knock]:
		sound_cues.emit_sound(&"knock", current_door.global_position)
		next_knock += 1

func _process(delta: float) -> void:
	if not night_manager.game_running:
		check_time_remaining = check_interval
		clear_encounter()
		return

	# For now, stop creating new knock encounters after a breach
	if breach_active:
		return

	# Deal with an active knock encounter first
	if current_knock != KnockType.NONE:
		update_knock_sounds(delta)
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


func _on_knocked_back(door: Area2D) -> void:
	if current_knock == KnockType.NONE:
		print("Nothing answered")
		return

	# The player knocked at the wrong door
	if door != current_door:
		print("Wrong door")
		return

	if current_knock == KnockType.REAL:
		print("Real Knocker repelled")
		clear_encounter()
		return

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

	enemy.breach_at(current_door.get_breach_position())

	clear_encounter()


func clear_encounter() -> void:
	knock_times = []
	next_knock = 0
	current_knock = KnockType.NONE
	current_door = null
	response_time_remaining = 0.0
