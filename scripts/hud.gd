extends CanvasLayer

@onready var player = $"../Player"
@onready var flashlight = $"../Player/FlashlightPivot"
@onready var night_manager = $"../NightManager"
@onready var status: Label = $Status

func _process(_delta: float) -> void:
	var minutes := int(night_manager.get_hours_since_midnight() * 60.0)
	var hour := minutes / 60
	if hour == 0:
		hour = 12
	var clock := "%d:%02d AM" % [hour, minutes % 60]
	var message := ""
	if player.is_dead:
		message = "  |  You were caught"
	elif night_manager.current_night > night_manager.total_nights:
		clock = "6:00 AM"
		message = "  |  All nights survived"
	elif not night_manager.game_running:
		message = "  |  Answer the phone (E)"
	status.text = "Night %d  |  %s%s\nStamina: %d%%  |  Battery: %d%%  |  Flash (F): %d" % [
		mini(night_manager.current_night, night_manager.total_nights), clock, message,
		roundi(100.0 * player.stamina / player.max_stamina),
		roundi(100.0 * flashlight.battery / flashlight.max_battery),
		10 + 3 * night_manager.current_night
	]
