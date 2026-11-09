extends SceneTree

var failures: int = 0
var events: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func record(kind: StringName, source: Vector2, hearing_radius: float) -> void:
	events.append({"kind": kind, "source": source, "radius": hearing_radius})

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var house = load("res://scenes/house.tscn").instantiate()
	root.add_child(house)
	await physics_frame
	await physics_frame
	var player = house.get_node("Player")
	var ring = player.get_node("SoundRing")
	var bus = house.get_node("SoundCues")
	var night = house.get_node("NightManager")
	var knocker = house.get_node("KnockManager")
	var enemy = house.get_node("enemy")
	player.set_physics_process(false)
	player.global_position = Vector2(600, 320)
	ring.set_process(false)
	bus.sound_emitted.connect(record)
	bus.emit_sound(&"knock", Vector2(600, 0))
	check(ring.pulses.is_empty(), "No cues before phone starts the night")
	night.start_night()
	knocker.set_process(false)
	for section in range(8):
		var source: Vector2 = player.global_position + Vector2.RIGHT.rotated(section * PI / 4.0) * 100.0
		check(ring.direction_section(source) == section, "Correct directional section")
	knocker.start_knock(knocker.KnockType.REAL)
	check(ring.pulses.size() == 1, "First knock pulses immediately")
	check(knocker.response_time_remaining == 8.0, "Eight-second response window")
	knocker.update_knock_sounds(0.44)
	check(ring.pulses.size() == 1, "Real knock gap")
	knocker.update_knock_sounds(0.02)
	knocker.update_knock_sounds(0.45)
	check(ring.pulses.size() == 3, "Three real knock pulses")
	var pink: Color = ring.pulses[0]["colour"]
	knocker.clear_encounter()
	ring.pulses.clear()
	knocker.start_knock(knocker.KnockType.FALSE)
	knocker.update_knock_sounds(0.46)
	check(ring.pulses.size() == 1, "False knock has a longer first gap")
	knocker.update_knock_sounds(0.45)
	knocker.update_knock_sounds(0.25)
	check(ring.pulses.size() == 3 and ring.pulses[2]["colour"] == pink, "False knock uses same colour and its own rhythm")
	knocker.clear_encounter()
	knocker.update_knock_sounds(5.0)
	check(ring.pulses.size() == 3, "Resolved encounters cancel remaining knocks")
	ring.pulses.clear()
	bus.emit_sound(&"footstep", player.global_position + Vector2(900, 0), 850.0)
	check(ring.pulses.is_empty(), "Distant footsteps are hidden")
	bus.emit_sound(&"footstep", player.global_position + Vector2(-200, 200), 850.0)
	check(ring.pulses.size() == 1 and ring.pulses[0]["section"] == 3, "Nearby footstep points down-left")
	var captured: int = ring.pulses[0]["section"]
	player.global_position += Vector2(500, 500)
	check(ring.pulses[0]["section"] == captured, "Existing cue never tracks source")
	ring._process(0.3)
	check(ring.pulses.is_empty(), "Footstep fades out")
	enemy.breach_grace_period = 0.01
	enemy.breach_at(Vector2(575, 100))
	check(ring.pulses.size() == 1 and ring.pulses[0]["breach"], "Breach emits stronger cue")
	await create_timer(0.03).timeout
	enemy.set_physics_process(false)
	check(enemy.aggression_decay_rate == 9.0, "Faster aggression decay")
	night.prepare_night()
	check(ring.pulses.is_empty(), "New night clears cues")
	check(not player.has_node("BatteryLabel"), "Floating battery label removed")
	print("Sound cue checks completed; failures: ", failures)
	house.queue_free()
	await process_frame
	quit(1 if failures else 0)
