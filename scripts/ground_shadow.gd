class_name GroundShadow
extends Node2D

const MECH_SHADOW_TEXTURE := preload("res://assets/mech_ground_shadow_v2.png")

@export var radius := Vector2(17.0, 4.5)
@export var opacity := 0.24


func _draw() -> void:
	# This separate texture is centered and symmetrical, without the cropped edge
	# that the shared enemy-shadow source had on the mech.
	var size := Vector2(radius.x * 2.7, radius.y * 6.8)
	draw_texture_rect(
		MECH_SHADOW_TEXTURE,
		Rect2(-size * 0.5, size),
		false,
		Color(0.42, 0.24, 0.12, opacity * 1.45)
	)
