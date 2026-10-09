class_name CombatEffect
extends Node2D

const ROCKET_EXPLOSION_FRAMES := preload("res://assets/rocket_explosion_3frames_v1.png")
const ENEMY_EXPLOSION_FRAMES := preload("res://assets/enemy_explosion_4frames_v1.png")

enum Type { PLASMA_IMPACT, ROCKET_EXPLOSION, ENEMY_DEATH, PLAYER_IMPACT, REPAIR, SPEED_BOOST, FIRE_RATE_BOOST, ENEMY_DISSOLVE }

var effect_type := Type.PLASMA_IMPACT
var duration := 0.18
var time_left := 0.0
var effect_scale := 1.0
var active := false
var spark_offset := 0.0
var burst_sprite: Sprite2D


func _ready() -> void:
	z_index = 3
	burst_sprite = Sprite2D.new()
	burst_sprite.centered = true
	burst_sprite.visible = false
	add_child(burst_sprite)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func activate(world_position: Vector2, new_type: int, new_scale: float = 1.0) -> void:
	global_position = world_position
	effect_type = new_type
	effect_scale = new_scale
	duration = 0.34 if effect_type == Type.ROCKET_EXPLOSION else 0.24
	if effect_type == Type.ENEMY_DEATH:
		# Heavy weapons use the universal four-frame destruction explosion.
		duration = 0.54
	elif effect_type == Type.ENEMY_DISSOLVE:
		duration = 0.34
	elif effect_type == Type.PLAYER_IMPACT:
		duration = 0.20
	time_left = duration
	spark_offset = randf_range(0.0, TAU)
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_update_animated_burst(0.0)
	queue_redraw()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		active = false
		visible = false
		burst_sprite.visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	_update_animated_burst(1.0 - time_left / duration)
	queue_redraw()


func _draw() -> void:
	var progress := 1.0 - time_left / duration
	if effect_type == Type.ROCKET_EXPLOSION:
		return
	if effect_type == Type.ENEMY_DEATH:
		return
	var color := Color("64dcff")
	var radius := lerpf(3.0, 12.0, progress) * effect_scale
	var spark_count := 5
	if effect_type == Type.ENEMY_DISSOLVE:
		radius = lerpf(4.0, 18.0, progress) * effect_scale
		spark_count = 5
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


func _update_animated_burst(progress: float) -> void:
	if effect_type != Type.ROCKET_EXPLOSION and effect_type != Type.ENEMY_DEATH:
		burst_sprite.visible = false
		return
	var sprite_sheet: Texture2D = ROCKET_EXPLOSION_FRAMES
	var frame_count := 3
	if effect_type == Type.ENEMY_DEATH:
		sprite_sheet = ENEMY_EXPLOSION_FRAMES
		frame_count = 4
	var frame := mini(int(progress * float(frame_count)), frame_count - 1)
	var cell_width := float(sprite_sheet.get_width()) / float(frame_count)
	var burst_size := lerpf(18.0, 58.0, progress) * effect_scale
	if effect_type == Type.ENEMY_DEATH:
		burst_size = lerpf(20.0, 62.0, progress) * effect_scale
	burst_sprite.texture = sprite_sheet
	burst_sprite.region_enabled = false
	burst_sprite.hframes = frame_count
	burst_sprite.vframes = 1
	burst_sprite.frame = frame
	burst_sprite.scale = Vector2.ONE * burst_size / cell_width
	burst_sprite.modulate = Color(1.0, 1.0, 1.0, (1.0 - progress) * (1.0 - progress))
	burst_sprite.visible = true
