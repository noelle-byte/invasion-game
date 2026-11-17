extends Control

signal resume_requested

var buttons: VBoxContainer
var heading: Label
var return_action: Callable

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.025, 0.045, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	buttons = VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(360, 0)
	buttons.add_theme_constant_override("separation", 14)
	centre.add_child(buttons)
	if name == "MainMenu":
		show_main()

func clear(title: String) -> void:
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	heading = Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	buttons.add_child(heading)

func button(text: String, action: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 46
	item.pressed.connect(action)
	buttons.add_child(item)
	if buttons.get_child_count() == 2:
		focus_first.call_deferred()

func show_main() -> void:
	clear("INVASION")
	button("Start Game", func(): GameSettings.start_game())
	button("Settings", func(): show_settings(show_main))
	button("Quit", func(): get_tree().quit())

func show_pause() -> void:
	show()
	clear("Paused")
	button("Resume", func(): resume_requested.emit())
	button("Settings", func(): show_settings(show_pause))
	button("Restart Game", func(): GameSettings.start_game())
	button("Main Menu", GameSettings.main_menu)

func show_end(won: bool, night: int) -> void:
	show()
	clear("Five nights survived" if won else "You were caught")
	if won:
		button("Play Again", func(): GameSettings.start_game())
	else:
		button("Retry Night %d" % night, func(): GameSettings.start_game(night))
	button("Main Menu", GameSettings.main_menu)

func show_settings(back: Callable) -> void:
	clear("Settings")
	return_action = back
	var cues := CheckButton.new()
	cues.text = "Visual sound indicators"
	cues.button_pressed = GameSettings.sound_indicators
	cues.toggled.connect(func(value: bool):
		GameSettings.sound_indicators = value
		GameSettings.save_settings())
	buttons.add_child(cues)
	focus_first.call_deferred()
	var outline := CheckButton.new()
	outline.text = "Always show ring outline"
	outline.button_pressed = GameSettings.ring_outline
	outline.toggled.connect(func(value: bool):
		GameSettings.ring_outline = value
		GameSettings.save_settings())
	buttons.add_child(outline)
	button("Back", back)

func focus_first() -> void:
	if not is_inside_tree() or not visible:
		return
	for child in buttons.get_children():
		if child is BaseButton:
			child.grab_focus()
			return
