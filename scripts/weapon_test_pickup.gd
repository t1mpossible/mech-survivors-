extends Node2D

signal selected(key: String)

const PROJECTILES := preload("res://assets/projectiles_v1.png")
const EFFECTS := preload("res://assets/hero_weapon_effects_v1.png")

var weapon_key := ""
var display_name := ""
var player_position := Vector2.ZERO
var equipped := false
var player_inside := false
var tint := Color("ffc762")


func _ready() -> void:
	var label := Label.new()
	label.text = display_name
	label.position = Vector2(-65, 25)
	label.size = Vector2(130, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", tint)
	add_child(label)


func _process(_delta: float) -> void:
	var inside := global_position.distance_to(player_position) < 20.0
	if inside and not player_inside:
		selected.emit(weapon_key)
	player_inside = inside
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 21.0, Color(tint, 0.12))
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(tint, 0.9 if equipped else 0.4), 1.5, true)
	if weapon_key == "heat":
		draw_circle(Vector2.ZERO, 13.0, Color(tint, 0.18))
		draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 32, tint, 1.5, true)
		for index in range(3):
			var direction := Vector2.from_angle(index * TAU / 3.0 - PI * 0.5)
			draw_line(direction * 4.0, direction * 9.0, Color("ffdc89"), 2.0, true)
		return
	var texture := PROJECTILES
	var column := 0
	if weapon_key in ["swarm", "siege"]:
		column = 1
	elif weapon_key in ["burn", "pulse", "shuriken"]:
		texture = EFFECTS
		column = 2 if weapon_key == "shuriken" else 0
	var cell := texture.get_size() / Vector2(4, 2)
	draw_texture_rect_region(texture, Rect2(-Vector2(18, 18), Vector2(36, 36)), Rect2(Vector2(column * cell.x, 0), cell), tint)
