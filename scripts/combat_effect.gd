class_name CombatEffect
extends Node2D

enum Type { PLASMA_IMPACT, ROCKET_EXPLOSION, ENEMY_DEATH, PLAYER_IMPACT, REPAIR, SPEED_BOOST, FIRE_RATE_BOOST }

var effect_type := Type.PLASMA_IMPACT
var duration := 0.18
var time_left := 0.0
var effect_scale := 1.0
var active := false
var spark_offset := 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func activate(world_position: Vector2, new_type: int, new_scale: float = 1.0) -> void:
	global_position = world_position
	effect_type = new_type
	effect_scale = new_scale
	duration = 0.34 if effect_type == Type.ROCKET_EXPLOSION else 0.24
	if effect_type == Type.ENEMY_DEATH:
		duration = 0.30
	elif effect_type == Type.PLAYER_IMPACT:
		duration = 0.20
	time_left = duration
	spark_offset = randf_range(0.0, TAU)
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	queue_redraw()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		active = false
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	queue_redraw()


func _draw() -> void:
	var progress := 1.0 - time_left / duration
	var color := Color("64dcff")
	var radius := lerpf(3.0, 12.0, progress) * effect_scale
	var spark_count := 5
	if effect_type == Type.ROCKET_EXPLOSION:
		color = Color("ff9a3d")
		radius = lerpf(5.0, 28.0, progress) * effect_scale
		spark_count = 8
	elif effect_type == Type.ENEMY_DEATH:
		color = Color("e77aff")
		radius = lerpf(4.0, 20.0, progress) * effect_scale
		spark_count = 7
	elif effect_type == Type.PLAYER_IMPACT:
		color = Color("ff5b5b")
		radius = lerpf(3.0, 15.0, progress) * effect_scale
		spark_count = 6
	elif effect_type == Type.REPAIR:
		color = Color("62f5a1")
		radius = lerpf(7.0, 24.0, progress) * effect_scale
		spark_count = 8
	elif effect_type == Type.SPEED_BOOST:
		color = Color("48cfff")
		radius = lerpf(7.0, 23.0, progress) * effect_scale
		spark_count = 7
	elif effect_type == Type.FIRE_RATE_BOOST:
		color = Color("ffad4a")
		radius = lerpf(7.0, 23.0, progress) * effect_scale
		spark_count = 7
	var fade := (1.0 - progress) * (1.0 - progress)
	draw_circle(Vector2.ZERO, maxf(radius * 0.28, 1.5), Color(color, fade * 0.9))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 18, Color(color, fade * 0.75), 1.3)
	for index in range(spark_count):
		var angle := spark_offset + TAU * float(index) / float(spark_count)
		var start := Vector2.from_angle(angle) * radius * 0.50
		var finish := Vector2.from_angle(angle) * radius * (0.85 + progress * 0.55)
		draw_line(start, finish, Color(color, fade), 1.4)
