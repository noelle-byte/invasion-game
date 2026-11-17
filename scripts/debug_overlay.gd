extends Node2D

@onready var enemy = $"../enemy"
@onready var player = $"../Player"
@onready var night = $"../NightManager"
@onready var knocks = $"../KnockManager"
@onready var light = $"../Player/FlashlightPivot"
var enabled: bool = false
var world_drawing: Node2D
var frame: PanelContainer
var panel: Label
var history: Array[String] = []
var previous_state: int = -1
var previous_sight: bool = false
var enemy_was_active: bool = false
var previous_position: Vector2
var measured_speed: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_position = enemy.global_position
	var world_canvas := CanvasLayer.new()
	world_canvas.layer = 4
	world_canvas.follow_viewport_enabled = true
	add_child(world_canvas)
	world_drawing = Node2D.new()
	world_canvas.add_child(world_drawing)
	world_drawing.draw.connect(draw_world)
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	frame = PanelContainer.new()
	root.add_child(frame)
	frame.anchor_left = 0.64
	frame.anchor_right = 1.0
	frame.anchor_bottom = 0.5
	frame.offset_left = 0
	frame.offset_right = -20
	frame.offset_top = 20
	frame.offset_bottom = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.85)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	frame.add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	panel = Label.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_theme_font_size_override("font_size", 15)
	scroll.add_child(panel)
	panel.hide()
	frame.hide()
	get_node("../SoundCues").sound_emitted.connect(_sound_event)
	enemy.flashed.connect(func(): log_event("Flashed"))

func _sound_event(kind: StringName, _source: Vector2, _radius: float) -> void:
	if kind == &"breach":
		log_event("Breach")

func log_event(message: String) -> void:
	history.append(message)
	if history.size() > 6:
		history.pop_front()

func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		enabled = not enabled
		panel.visible = enabled
		frame.visible = enabled
		world_drawing.queue_redraw()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not OS.is_debug_build():
		return
	measured_speed = previous_position.distance_to(enemy.global_position) / delta if delta > 0.0 and not get_tree().paused else 0.0
	previous_position = enemy.global_position
	if enemy.behaviour_state != previous_state or enemy.visible != enemy_was_active:
		log_event("Enemy: " + (enemy.BehaviourState.keys()[enemy.behaviour_state] if enemy.visible else "Inactive"))
		previous_state = enemy.behaviour_state
		enemy_was_active = enemy.visible
	if enemy.sees_player != previous_sight:
		log_event("Sight acquired" if enemy.sees_player else "Sight lost")
		previous_sight = enemy.sees_player
	if not enabled:
		return
	var distance: float = enemy.global_position.distance_to(player.global_position)
	var hears: bool = player.is_running and distance <= enemy.running_hearing_radius
	var path: PackedVector2Array = enemy.navigation_agent.get_current_navigation_path()
	var remaining: float = 0.0
	var last: Vector2 = enemy.global_position
	for index in range(enemy.navigation_agent.get_current_navigation_path_index(), path.size()):
		remaining += last.distance_to(path[index])
		last = path[index]
	var game_seconds: int = int(night.get_hours_since_midnight() * 3600.0)
	if night.current_night > night.total_nights:
		game_seconds = 21600
	var game_hour: int = game_seconds / 3600
	var precise_clock: String = "%d:%02d:%02d AM" % [12 if game_hour == 0 else game_hour, (game_seconds / 60) % 60, game_seconds % 60]
	panel.text = "DEBUG · F3 to hide\nEnemy: %s · active %s · aggression %.1f\nSpeed %.1f / %.1f · distance %.1f\nSees %s · hears running %s · grace %.2f · stun %.2f\nTarget %s · route %.1f\nNight %d · %.1fs · %s\nTime %s\nKnock %s · response %.2f · next check %.2f\nPlayer %s · running %s · exhausted %s\nStamina %.2f · battery %.2f\n%s" % [
		enemy.BehaviourState.keys()[enemy.behaviour_state], enemy.visible, enemy.aggression,
		measured_speed, enemy.speed, distance,
		enemy.sees_player, hears, enemy.breach_time_remaining, enemy.stun_time_remaining,
		enemy.navigation_agent.target_position, remaining,
		night.current_night, night.time_remaining, "paused" if get_tree().paused else ("running" if night.game_running else "waiting"),
		precise_clock,
		knocks.KnockType.keys()[knocks.current_knock], knocks.response_time_remaining, knocks.check_time_remaining,
		player.global_position, player.is_running, player.exhausted, player.stamina, light.battery,
		"\n".join(history)]
	world_drawing.queue_redraw()

func draw_world() -> void:
	if not enabled or not enemy.visible:
		return
	var origin: Vector2 = to_local(enemy.global_position)
	world_drawing.draw_arc(origin, enemy.running_hearing_radius, 0, TAU, 64, Color(1, 0.8, 0.2, 0.5), 2)
	world_drawing.draw_line(origin, to_local(player.global_position), Color.GREEN if enemy.sees_player else Color.RED, 2)
	world_drawing.draw_circle(to_local(enemy.last_known_position), 9, Color.ORANGE)
	world_drawing.draw_circle(to_local(enemy.navigation_agent.target_position), 6, Color.CYAN)
	var path: PackedVector2Array = enemy.navigation_agent.get_current_navigation_path()
	for index in range(1, path.size()):
		world_drawing.draw_line(to_local(path[index - 1]), to_local(path[index]), Color.CYAN, 3)
	world_drawing.draw_string(ThemeDB.fallback_font, origin + Vector2(45, -45), "%s %.0f" % [enemy.BehaviourState.keys()[enemy.behaviour_state], enemy.aggression], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
