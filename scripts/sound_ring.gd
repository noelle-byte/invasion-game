extends Node2D

@export var radius: float = 68.0
@export var footstep_colour := Color(1.0, 1.0, 1.0)
@export var knock_colour := Color(1.0, 0.35, 0.65)
@export var breach_colour := Color(1.0, 0.65, 0.25)

@onready var player: Node2D = get_parent()
@onready var night_manager: Node = $"../../NightManager"
@onready var sound_cues: Node = $"../../SoundCues"

# Each pulse stores its direction when the sound happens, never a tracked source.
var pulses: Array[Dictionary] = []

# A separate canvas keeps accessibility cues clear of the house darkness.
var overlay: CanvasLayer
var drawing: Node2D

func _ready() -> void:
	sound_cues.sound_emitted.connect(_on_sound_emitted)
	night_manager.waiting_for_call.connect(_on_waiting_for_call)
	overlay = CanvasLayer.new()
	overlay.layer = 2
	add_child(overlay)
	drawing = Node2D.new()
	overlay.add_child(drawing)
	drawing.draw.connect(draw_ring)
	# Update after the room camera has chosen its position.
	process_priority = 10
	drawing.position = player.get_global_transform_with_canvas().origin

func _on_waiting_for_call(_night: int) -> void:
	pulses.clear()
	drawing.queue_redraw()

func direction_section(source_position: Vector2) -> int:
	var direction: Vector2 = source_position - player.global_position
	return posmod(roundi(direction.angle() / (PI / 4.0)), 8)

func _on_sound_emitted(kind: StringName, source_position: Vector2, hearing_radius: float) -> void:
	if not night_manager.game_running or player.is_dead:
		return
	if hearing_radius > 0.0 and player.global_position.distance_to(source_position) > hearing_radius:
		return
	var colour: Color
	var duration: float
	match kind:
		&"knock":
			colour = knock_colour
			duration = 0.22
		&"breach":
			colour = breach_colour
			duration = 0.7
		&"footstep":
			colour = footstep_colour
			duration = 0.18
		_:
			return
	pulses.append({"section": direction_section(source_position), "colour": colour,
		"remaining": duration, "duration": duration, "breach": kind == &"breach"})
	drawing.queue_redraw()

func _process(delta: float) -> void:
	drawing.position = player.get_global_transform_with_canvas().origin
	for index in range(pulses.size() - 1, -1, -1):
		pulses[index]["remaining"] -= delta
		if pulses[index]["remaining"] <= 0.0:
			pulses.remove_at(index)
	drawing.queue_redraw()

func draw_ring() -> void:
	for section in range(8):
		var angle: float = section * PI / 4.0
		drawing.draw_arc(Vector2.ZERO, radius, angle - 0.30, angle + 0.30, 16, Color(0.8, 0.85, 0.9, 0.18), 2.0, true)
	for pulse in pulses:
		var angle: float = float(pulse["section"]) * PI / 4.0
		var colour: Color = pulse["colour"]
		colour.a = float(pulse["remaining"]) / float(pulse["duration"])
		var width: float = 8.0 if pulse["breach"] else 5.0
		drawing.draw_arc(Vector2.ZERO, radius, angle - 0.30, angle + 0.30, 16, colour, width, true)
