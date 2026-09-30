extends Camera2D

# Size of one camera screen in world coordinates
@export var cell_size := Vector2(1152.0, 648.0)

@onready var player: CharacterBody2D = $"../Player"

# Stores which camera grid position is currently being displayed
var current_cell := Vector2i(-1, -1)


func _ready() -> void:
	# Place the camera correctly when the game starts
	_update_camera_position()


func _process(_delta: float) -> void:
	# Check whether the player has crossed into another screen
	_update_camera_position()


func _update_camera_position() -> void:
	# Convert the player's world position into a grid coordinate
	var player_cell := Vector2i(
		floori(player.global_position.x / cell_size.x),
		floori(player.global_position.y / cell_size.y)
	)

	# Do nothing while the player remains within the current screen
	if player_cell == current_cell:
		return

	# Store the new grid cell
	current_cell = player_cell

	# Move the camera to the centre of that screen
	global_position = Vector2(
		(current_cell.x + 0.5) * cell_size.x,
		(current_cell.y + 0.5) * cell_size.y
	)
