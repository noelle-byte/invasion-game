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
	var box = house.get_node("MusicBox")
	var night = house.get_node("NightManager")
	var enemy = house.get_node("enemy")
	var ghost = house.get_node("Wraith")
	var knocks = house.get_node("KnockManager")
	var player = house.get_node("Player")
	box.set_process(false)
	knocks.set_process(false)
	player.set_physics_process(false)
	box._process(10.0)
	check(box.remaining == box.capacity, "Phone wait does not drain the box")
	night.start_night()
	box._process(10.0)
	check(is_equal_approx(box.remaining, 35.0), "Box drains during the night")
	player.global_position = box.global_position
	await physics_frame
	await physics_frame
	check(box.player_nearby, "Player enters music box interaction area")
	Input.action_press("interact")
	box._process(1.0)
	check(is_equal_approx(box.remaining, 40.0), "Holding interact winds the box")
	box._process(5.0)
	check(is_equal_approx(box.remaining, box.capacity), "Winding is capped")
	Input.action_release("interact")
	box._process(45.0)
	check(box.expired and enemy.music_box_penalty and ghost.music_box_penalty and knocks.music_box_penalty, "Empty box empowers enemies")
	check(knocks.get_effective_ai_level() == 8, "Penalty increases effective AI by four")
	night.set_music_box_penalty(true)
	check(knocks.get_effective_ai_level() == 8, "Penalty does not stack")
	# Running beyond the normal hearing radius still increases aggression.
	enemy.global_position = Vector2(100, 100)
	player.global_position = Vector2(800, 100)
	player.is_running = true
	enemy.sees_player = false
	enemy.aggression = 0.0
	enemy.update_awareness(0.5)
	check(enemy.aggression > 0.0, "Penalty extends running hearing range")
	player.is_running = false
	ghost.set_difficulty(5)
	ghost.set_active(true)
	ghost.set_physics_process(false)
	ghost.grace_remaining = 0.0
	ghost.global_position = Vector2(100, 300)
	player.global_position = Vector2(1000, 300)
	ghost._physics_process(1.0)
	check(is_equal_approx(ghost.global_position.x, 100.0 + player.walk_speed), "Buffed Wraith respects walk speed cap")
	Input.action_press("interact")
	box._process(10.0)
	check(box.expired and box.remaining == 0.0, "Expiry cannot be reversed this night")
	Input.action_release("interact")
	knocks.current_knock = knocks.KnockType.NONE
	knocks.check_time_remaining = 4.0
	knocks._process(1.0)
	check(is_equal_approx(knocks.check_time_remaining, 2.75), "Knock opportunity timer runs faster")
	knocks.start_knock(knocks.KnockType.REAL)
	var before: float = knocks.response_time_remaining
	knocks._process(1.0)
	check(is_equal_approx(knocks.response_time_remaining, before - 1.25), "Knock response timer runs faster")
	night.advance_night()
	check(not box.expired and box.remaining == box.capacity and not enemy.music_box_penalty and not ghost.music_box_penalty and not knocks.music_box_penalty, "Night transition resets box and penalty")
	box._process(10.0)
	check(box.remaining == box.capacity, "Box remains full while waiting for next call")
	check(knocks.get_effective_ai_level() == 4, "AI bonus resets between nights")
	night.start_night()
	box._process(10.0)
	check(is_equal_approx(box.remaining, 33.5), "Night 2 drains faster")
	night.prepare_night()
	night.current_night = 5
	night.start_night()
	box._process(10.0)
	check(is_equal_approx(box.remaining, 29.0), "Night 5 drains faster again")
	night.set_music_box_penalty(true)
	check(knocks.get_effective_ai_level() == 20, "AI bonus is capped at 20")
	house.queue_free()
	print("Music box checks completed; failures: ", failures)
	quit(1 if failures else 0)
