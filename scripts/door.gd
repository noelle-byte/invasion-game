extends Area2D

signal knocked_back

@onready var player: CharacterBody2D = $"../../Player"
@onready var breach_spawn: Marker2D = $BreachSpawn

var player_nearby := false


func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		print("Player knocked on door")
		knocked_back.emit()


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_nearby = false


func get_breach_position() -> Vector2:
	return breach_spawn.global_position
