extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame

func run() -> void:
	root.size = Vector2i(1152, 648)
	var settings = root.get_node("GameSettings")
	settings.main_menu()
	await settle()
	check(current_scene.name == "MainMenu", "Main menu scene loads")
	check(current_scene.buttons.get_child_count() == 4, "Start, settings, quit available")
	current_scene.show_settings(current_scene.show_main)
	check(current_scene.buttons.get_child(1) is CheckButton, "Settings options exist")
	settings.start_game(3)
	await settle()
	var house = current_scene
	var night = house.get_node("NightManager")
	var player = house.get_node("Player")
	var light = player.get_node("FlashlightPivot")
	var enemy = house.get_node("enemy")
	var phone = house.get_node("WallPhone/Area2D")
	var hud = house.get_node("HUD")
	check(night.current_night == 3 and not night.game_running, "Retry starts requested night behind phone gate")
	check(light.current_night == 3 and light.battery > 99.0 and player.stamina == 100.0, "Retry resources and difficulty reset")
	check(house.get_node("Pickups").get_child_count() == 5, "Retry restores all pickups")
	check(hud.clock.get_global_rect().end.x <= root.size.x, "Clock fits viewport")
	for item in [hud.night_label, hud.stamina_bar, hud.battery_bar]:
		var bounds: Rect2 = item.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y, "Objective and resource bars fully inside viewport")
	check(hud.stamina_bar.get_global_rect().position.y > root.size.y * 0.5, "Resource bars sit in bottom half")
	phone.call_duration = 0.08
	phone.answer_phone()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	hud._unhandled_key_input(escape)
	check(paused and hud.menu.visible, "Escape pauses and opens menu")
	await create_timer(0.12, true).timeout
	check(phone.call_playing and not night.game_running, "Phone timer freezes while paused")
	hud.resume()
	await create_timer(0.12).timeout
	check(night.game_running, "Phone completes after resume")
	var time_before: float = night.time_remaining
	enemy.breach_grace_period = 0.08
	enemy.breach_at(Vector2(575, 100))
	light.attempt_flash()
	var paused_battery: float = light.battery
	hud._unhandled_key_input(escape)
	await create_timer(0.2, true).timeout
	check(is_equal_approx(night.time_remaining, time_before) and is_equal_approx(light.battery, paused_battery), "Night clock freezes")
	check(not enemy.can_move and light.flash_in_progress, "Breach and flash timers freeze")
	hud.resume()
	await create_timer(0.15).timeout
	check(enemy.can_move and not light.flash_in_progress, "Breach and flash resume")
	var debug = house.get_node("DebugOverlay")
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	debug._unhandled_key_input(f3)
	debug._process(0.0)
	check(debug.enabled and debug.panel.visible and debug.panel.text.contains("aggression"), "F3 enables AI diagnostics")
	player.die()
	check(paused and hud.ended and hud.menu.heading.text == "You were caught", "Death opens retry menu")
	settings.start_game(3)
	await settle()
	check(not paused and not current_scene.get_node("Player").is_dead, "Retry clears death and pause")
	current_scene.get_node("NightManager").current_night = 5
	current_scene.get_node("NightManager").advance_night()
	check(paused and current_scene.get_node("HUD").menu.heading.text == "Five nights survived", "Completion opens win menu")
	settings.main_menu()
	await settle()
	check(not paused and current_scene.name == "MainMenu", "Return to menu unpauses")
	# Leaving with an active timer must not start a night in the next scene.
	settings.start_game()
	await settle()
	current_scene.get_node("WallPhone/Area2D").call_duration = 0.05
	current_scene.get_node("WallPhone/Area2D").answer_phone()
	settings.main_menu()
	await settle()
	await create_timer(0.1).timeout
	check(current_scene.name == "MainMenu", "Pending phone callback cannot affect new scene")
	print("Menu flow checks completed; failures: ", failures)
	quit(1 if failures else 0)
