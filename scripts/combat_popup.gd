class_name CombatPopup
extends Node2D

var message := ""
var text_color := Color.WHITE
var time_left := 0.75
var active := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func activate(world_position: Vector2, new_message: String, new_color: Color) -> void:
	global_position = world_position + Vector2(0.0, -16.0)
	message = new_message
	text_color = new_color
	time_left = 0.75
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	queue_redraw()


func _process(delta: float) -> void:
	time_left -= delta
	global_position.y -= 12.0 * delta
	if time_left <= 0.0:
		active = false
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 8
	var width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var alpha := minf(time_left / 0.16, 1.0)
	draw_string(font, Vector2(-width * 0.5, 0.0), message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.0, 0.03, 0.06, alpha))
	draw_string(font, Vector2(-width * 0.5, -1.0), message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(text_color, alpha))
