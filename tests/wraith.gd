extends SceneTree

var failures := 0
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var house = load("res://scenes/house.tscn").instantiate()
	root.add_child(house)
	await physics_frame
	await physics_frame
	var player = house.get_node("Player")
	var night = house.get_node("NightManager")
	var ghost = house.get_node("Wraith")
	var light = player.get_node("FlashlightPivot")
	player.set_physics_process(false)
	light.set_process(false)
	house.get_node("KnockManager").set_process(false)
	check(not ghost.active, "Wraith absent before Night 1")
	night.start_night()
	check(not ghost.active, "Wraith absent on Night 1")
	night.advance_night()
	check(not ghost.active and not night.game_running, "Wraith absent while waiting for phone")
	night.start_night()
	check(ghost.active and ghost.visible and ghost.grace_remaining > 0.0, "Night 2 activates Wraith with grace")
	check(ghost.global_position.distance_to(player.global_position) > 400.0, "Wraith spawns away from player")
	ghost.set_physics_process(false)
	ghost.grace_remaining = 0.0
	player.global_position = Vector2(1250, 100)
	ghost.global_position = Vector2(1000, 100)
	ghost._physics_process(2.0)
	check(is_equal_approx(ghost.global_position.x, 1200.0) and ghost.speed < player.walk_speed, "Wraith moves through wall slower than walking")
	player.global_position = Vector2(600, 320)
	ghost.global_position = Vector2(900, 320)
	light.global_rotation = 0.0
	await physics_frame
	await physics_frame
	check(light.enemy_in_flash(ghost), "Wraith can be targeted by existing flash ray")
	light.attempt_flash()
	check(ghost.disable_remaining >= 6.0 and ghost.global_position.x > 1100.0, "Flash disables and repels Wraith")
	var held: Vector2 = ghost.global_position
	ghost._physics_process(1.0)
	check(ghost.global_position == held, "Disabled Wraith does not pursue")
	ghost._physics_process(6.0)
	ghost._physics_process(0.5)
	check(ghost.global_position.x < held.x, "Wraith resumes pursuit")
	night.advance_night()
	check(not ghost.active and not ghost.visible, "Night transition deactivates Wraith")
	for n in range(3, 6):
		night.start_night()
		check(ghost.active, "Wraith active on Night %d" % n)
		night.advance_night()
	check(not ghost.active and not night.game_running, "Completion deactivates Wraith")
	house.queue_free()
	print("Wraith checks completed; failures: ", failures)
	quit(1 if failures else 0)
