extends Area2D

@export var battery_amount: float = 40.0


func _on_body_entered(body: Node2D) -> void:
	if not body.has_node("FlashlightPivot"):
		return

	var flashlight = body.get_node("FlashlightPivot")

	# Do not waste the pickup if the battery is already full
	if flashlight.battery >= flashlight.max_battery:
		return

	flashlight.add_battery(battery_amount)

	queue_free()
