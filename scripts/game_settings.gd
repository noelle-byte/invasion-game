extends Node

var sound_indicators: bool = true
var ring_outline: bool = true
var starting_night: int = 1

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		sound_indicators = config.get_value("accessibility", "sound_indicators", true)
		ring_outline = config.get_value("accessibility", "ring_outline", true)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "sound_indicators", sound_indicators)
	config.set_value("accessibility", "ring_outline", ring_outline)
	config.save("user://settings.cfg")

func start_game(night: int = 1) -> void:
	starting_night = night
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/house.tscn")

func main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
