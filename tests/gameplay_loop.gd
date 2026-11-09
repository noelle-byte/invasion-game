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
	await physics_frame
	await physics_frame
	var player = house.get_node("Player")
	var enemy = house.get_node("enemy")
	var light = player.get_node("FlashlightPivot")
	var night = house.get_node("NightManager")
	check(not night.game_running and not enemy.visible, "Phone must gate the night")
	night.start_night()
	player.set_physics_process(false)
	light.set_process(false)
	house.get_node("KnockManager").set_process(false)
	enemy.breach_grace_period = 0.05
	player.global_position = Vector2(800, 320)
	enemy.breach_at(Vector2(575, 100))
	check(not enemy.can_move and not enemy.can_attack, "Breach grace period")
	await create_timer(0.08).timeout
	check(enemy.can_move and enemy.can_attack and enemy.behaviour_state == enemy.BehaviourState.HUNT, "Breach starts hunting")
	enemy.set_physics_process(false)
	enemy.global_position = Vector2(600, 320)
	player.global_position = Vector2(900, 320)
	await physics_frame
	await physics_frame
	enemy.update_awareness(2.0)
	check(enemy.sees_player and enemy.behaviour_state == enemy.BehaviourState.CHASE, "Sight escalates to chase")
	# Opposite sides of the central wall, within hearing range.
	enemy.global_position = Vector2(1000, 100)
	player.global_position = Vector2(1250, 100)
	await physics_frame
	await physics_frame
	player.is_running = true
	var remembered: Vector2 = enemy.last_known_position
	var before: float = enemy.aggression
	enemy.update_awareness(0.5)
	check(not enemy.sees_player and enemy.aggression > before, "Running heard through wall")
	check(enemy.last_known_position == remembered, "Hearing must not track exact position")
	player.is_running = false
	enemy.update_awareness(9.0)
	enemy.update_awareness(9.0)
	check(enemy.behaviour_state == enemy.BehaviourState.ROAM, "Enemy calms to roam")
	enemy.update_navigation_target(0.1)
	check(enemy.roam_destination != null, "Roam chooses a marker")
	enemy.global_position = Vector2(600, 320)
	enemy.last_known_position = enemy.global_position
	enemy.behaviour_state = enemy.BehaviourState.HUNT
	enemy.update_navigation_target(0.1)
	var search_point: Marker2D = enemy.roam_destination
	enemy.global_position += Vector2(50, 0)
	enemy.update_navigation_target(0.1)
	check(enemy.reached_last_known_position and enemy.navigation_agent.target_position == search_point.global_position, "Search continues after leaving last sighting")
	# Real navigation movement while the player is out of sight.
	enemy.global_position = Vector2(600, 320)
	player.global_position = Vector2(2100, 1000)
	enemy.behaviour_state = enemy.BehaviourState.ROAM
	enemy.aggression = 0.0
	enemy.roam_destination = house.get_node("RoamPoints/FrontRoom")
	var roam_start: Vector2 = enemy.global_position
	enemy.set_physics_process(true)
	await create_timer(0.25).timeout
	enemy.set_physics_process(false)
	check(enemy.global_position.distance_to(roam_start) > 20.0, "Roaming physically moves on the navigation mesh")
	# Every placed marker must remain reachable on the existing navigation mesh.
	var map: RID = enemy.navigation_agent.get_navigation_map()
	for point in house.get_node("RoamPoints").get_children():
		var route := NavigationServer2D.map_get_path(map, Vector2(600, 320), point.global_position, true)
		check(route.size() > 1 and route[-1].distance_to(point.global_position) < 30.0, "Reachable marker: " + point.name)
	player.global_position = Vector2(600, 320)
	await physics_frame
	await physics_frame
	enemy.global_position = Vector2(2100, 1000)
	await physics_frame
	await physics_frame
	Input.action_press("right")
	Input.action_press("run")
	var old_stamina: float = player.stamina
	player._physics_process(0.1)
	check(player.is_running and is_equal_approx(player.velocity.length(), player.run_speed) and player.stamina < old_stamina, "Sprint moves faster and drains stamina")
	Input.action_release("run")
	Input.action_release("right")
	player._physics_process(0.1)
	check(not player.is_running and player.stamina > old_stamina - 3.0, "Walking recovers stamina")
	# Flash in an unobstructed part of the front room.
	player.global_position = Vector2(600, 320)
	enemy.global_position = Vector2(900, 320)
	light.global_rotation = 0.0
	await physics_frame
	await physics_frame
	check(light.enemy_in_flash(enemy), "Flash cone and LOS accepts visible enemy")
	light.global_rotation = PI
	check(not light.enemy_in_flash(enemy), "Flash rejects enemy behind cone")
	light.global_rotation = 0.0
	light.flash_range = 100.0
	check(not light.enemy_in_flash(enemy), "Flash rejects out of range")
	light.flash_range = 700.0
	light.set_difficulty(3)
	light.battery = 100.0
	enemy.aggression = 80.0
	light.attempt_flash()
	check(is_equal_approx(light.battery, 81.0), "Night 3 flash costs 19")
	check(enemy.stun_time_remaining > 0.0 and enemy.aggression == 55.0, "Flash stuns and lowers aggression")
	enemy._on_attack_area_body_entered(player)
	check(not player.is_dead, "Stunned enemy cannot attack")
	await create_timer(0.15).timeout
	check(not light.flash_in_progress and is_equal_approx(light.flashlight.energy, 0.8), "Burst restores normal light")
	player.global_position = Vector2(1000, 100)
	enemy.global_position = Vector2(1250, 100)
	await physics_frame
	await physics_frame
	check(not light.enemy_in_flash(enemy), "Wall blocks flash")
	enemy.set_active(false)
	check(enemy.stun_time_remaining == 0.0, "Night reset clears stun")
	print("Gameplay checks completed; failures: ", failures)
	house.queue_free()
	await process_frame
	quit(1 if failures else 0)
