extends CanvasLayer

@onready var player = $"../Player"
@onready var flashlight = $"../Player/FlashlightPivot"
@onready var night_manager = $"../NightManager"

var night_label: Label
var clock: Label
var stamina_bar: ProgressBar
var battery_bar: ProgressBar
var music_label: Label
var music_bar: ProgressBar
var menu: Control
var ended: bool = false
var denied_time: float = 0.0

func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Replace the old development text display.
	get_node("Status").queue_free()
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_left := column(root, Vector2(20, 10), false, false)
	clock = label(top_left, 44)
	var bottom_left := column(root, Vector2(20, -215), false, true)
	bottom_left.custom_minimum_size.x = 360
	bottom_left.add_theme_constant_override("separation", 8)
	night_label = label(bottom_left, 26)
	stamina_bar = bar(bottom_left, Color(0.04, 0.12, 0.85))
	stamina_bar.tooltip_text = "Stamina · Hold Shift to sprint"
	battery_bar = bar(bottom_left, Color(1.0, 0.8, 0.0))
	battery_bar.tooltip_text = "Flashlight battery · Space to toggle · F to flash"
	music_label = label(bottom_left, 20)
	music_bar = bar(bottom_left, Color(0.75, 0.4, 0.8))
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)
	menu = load("res://scenes/game_menu.tscn").instantiate()
	menu_layer.add_child(menu)
	menu.hide()
	menu.resume_requested.connect(resume)
	player.died.connect(func(): end_game(false))
	night_manager.game_completed.connect(func(): end_game(true))
	flashlight.flash_denied.connect(func(): denied_time = 0.8)

func column(parent: Control, offset: Vector2, right: bool, bottom: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	parent.add_child(box)
	box.anchor_left = 1.0 if right else 0.0
	box.anchor_right = box.anchor_left
	box.anchor_top = 1.0 if bottom else 0.0
	box.anchor_bottom = box.anchor_top
	# Offsets are relative to the anchors; position would override that placement.
	box.offset_left = offset.x
	box.offset_right = offset.x + 360.0
	box.offset_top = offset.y
	box.offset_bottom = offset.y
	box.custom_minimum_size.x = 260
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

func label(parent: Node, size: int) -> Label:
	var item := Label.new()
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_outline_color", Color.BLACK)
	item.add_theme_constant_override("outline_size", 6)
	item.add_theme_constant_override("shadow_offset_x", 2)
	item.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(item)
	return item

func bar(parent: Node, colour: Color) -> ProgressBar:
	var item := ProgressBar.new()
	item.custom_minimum_size = Vector2(360, 32)
	item.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.06, 0.08, 0.85)
	background.border_color = Color.WHITE
	background.set_border_width_all(2)
	item.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	fill.border_color = Color.WHITE
	fill.set_border_width_all(2)
	item.add_theme_stylebox_override("fill", fill)
	parent.add_child(item)
	return item

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if not ended:
			if menu.visible:
				resume()
			else:
				get_tree().paused = true
				menu.show_pause()
		get_viewport().set_input_as_handled()

func resume() -> void:
	menu.hide()
	get_tree().paused = false

func end_game(won: bool) -> void:
	ended = true
	get_tree().paused = true
	menu.show_end(won, night_manager.current_night)

func _process(delta: float) -> void:
	var minutes: int = int(night_manager.get_hours_since_midnight() * 60.0)
	if night_manager.current_night > night_manager.total_nights:
		minutes = 360
	# Keep the gameplay clock deliberately coarse: 12:00, 12:30, 1:00...
	minutes = (minutes / 30) * 30
	var hour: int = minutes / 60
	clock.text = "%d:%02d" % [12 if hour == 0 else hour, minutes % 60]
	var objective: String = "Survive until 6 AM" if night_manager.game_running else "Answer the phone (E)"
	var phone = get_node("../WallPhone/Area2D")
	if phone.call_playing:
		objective = "Listen to the call"
	denied_time = maxf(0.0, denied_time - delta)
	if denied_time > 0.0:
		objective = "Not enough battery to flash"
	night_label.text = objective
	night_label.modulate = Color.SALMON if denied_time > 0.0 else Color.WHITE
	var box = get_node("../MusicBox")
	music_label.text = "Music box empty — enemies empowered" if box.expired else ("Hold E to wind music box" if box.player_nearby and night_manager.game_running else "Music box")
	music_label.modulate = Color.SALMON if box.expired else Color.WHITE
	music_bar.value = 100.0 * box.remaining / box.capacity
	stamina_bar.value = 100.0 * player.stamina / player.max_stamina
	battery_bar.value = 100.0 * flashlight.battery / flashlight.max_battery
	stamina_bar.modulate = Color(0.65, 0.65, 0.8) if player.exhausted else Color.WHITE
