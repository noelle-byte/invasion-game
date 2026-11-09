extends Node

# Audio can subscribe to this same event when sound assets are added.
# A radius of zero means the cue can be heard throughout the house.
signal sound_emitted(kind: StringName, source_position: Vector2, hearing_radius: float)

func emit_sound(kind: StringName, source_position: Vector2, hearing_radius: float = 0.0) -> void:
	sound_emitted.emit(kind, source_position, hearing_radius)
