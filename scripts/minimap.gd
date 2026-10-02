extends Control

@export_range(0.1, 1.0) var terrain_opacity := 0.6
@export var marker_color := Color(0.45, 0.95, 1.0)

var terrain: Texture2D
var terrain_region := Rect2()
var world_size := Vector2(1600, 900)
var player_position := Vector2.ZERO


func configure(ground: Sprite2D, map_size: Vector2) -> void:
	terrain = ground.texture
	world_size = map_size
	# The complete painting now covers the playable rectangle edge to edge.
	terrain_region = Rect2(Vector2.ZERO, terrain.get_size())
	queue_redraw()


func set_player_position(location: Vector2) -> void:
	if player_position != location:
		player_position = location
		queue_redraw()


func marker_position() -> Vector2:
	var ratio := player_position / world_size
	return (ratio * size).clamp(Vector2.ONE * 2.0, size - Vector2.ONE * 2.0)


func _draw() -> void:
	if terrain == null:
		return
	draw_rect(Rect2(Vector2(-3, -3), size + Vector2(6, 6)), Color(0.02, 0.04, 0.06, 0.3))
	draw_texture_rect_region(terrain, Rect2(Vector2.ZERO, size), terrain_region,
		Color(0.88, 0.87, 0.84, terrain_opacity))
	var marker := marker_position()
	draw_circle(marker, 3.2, Color(0.02, 0.08, 0.1, 0.8))
	draw_circle(marker, 1.8, marker_color)
	draw_circle(marker, 0.65, Color.WHITE)
