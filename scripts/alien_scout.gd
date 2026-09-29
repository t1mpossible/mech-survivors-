class_name AlienScout
extends Node2D

const ENEMY_ART := preload("res://assets/enemies_desert_v1.png")
const ENEMY_ART_MOTION := preload("res://assets/enemies_desert_motion_v1.png")
const THERMAL_FIRE := preload("res://assets/thermal_fire_3frames_v1.png")
const THERMAL_FIRE_FRAME_COUNT := 3
const THERMAL_FIRE_FPS := 7.0
# Individually fitted atlas bounds: the generated artwork is not an exact tile grid.
const ART_REGIONS: Array[Rect2] = [
	Rect2(0.020, 0.105, 0.208, 0.322),
	Rect2(0.274, 0.043, 0.190, 0.383),
	Rect2(0.498, 0.025, 0.254, 0.401),
	Rect2(0.780, 0.025, 0.204, 0.401),
	Rect2(0.010, 0.539, 0.245, 0.400),
	Rect2(0.232, 0.444, 0.263, 0.510),
	Rect2(0.503, 0.445, 0.270, 0.515),
]
# The turret barrel and mortar feet overlap neighbouring rectangular atlas cells.
# Clip different horizontal bands independently, preserving each unit's silhouette.
const ART_CLIP_BANDS := {
	4: [Rect2(0.010, 0.539, 0.245, 0.181), Rect2(0.010, 0.720, 0.218, 0.219)],
	5: [Rect2(0.268, 0.444, 0.227, 0.276), Rect2(0.238, 0.720, 0.257, 0.234)],
}

@export var movement_speed := 24.0
@export var max_health := 30
@export var contact_damage_per_second := 8.0
var experience_amount := 10
var xp_tier := XpOrb.Tier.SMALL_YELLOW
var target_position := Vector2.ZERO
var travel_direction := Vector2.DOWN
var health := max_health
var hit_radius := 12.0
var visual_time := 0.0
var damage_flash_time := 0.0
var base_visual_scale := Vector2.ONE
var movement_animation_active := false
var training_dummy := false
var thermal_active := false
var thermal_visual_time := 0.0
var thermal_fire_frame := 0

signal health_changed(current_health: int, maximum_health: int)
signal died


func _ready() -> void:
	add_to_group("enemies")
	base_visual_scale = scale
	queue_redraw()


func _process(delta: float) -> void:
	visual_time += delta
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	modulate = Color(1.0, 0.55, 0.55) if damage_flash_time > 0.0 else Color.WHITE
	var offset := target_position - global_position
	movement_animation_active = false
	if offset.length() > 18.0:
		travel_direction = offset.normalized()
		global_position += travel_direction * movement_speed * delta
		movement_animation_active = movement_speed > 0.0
		scale = base_visual_scale * (1.0 + sin(visual_time * 7.0) * 0.01)
		queue_redraw()


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	damage_flash_time = 0.1
	health_changed.emit(health, max_health)
	if health == 0:
		_spawn_death_effect()
		died.emit()
		queue_free()


func _draw() -> void:
	_draw_enemy_art(0, 30.0, Color("f06a9d"))


func set_thermal_visual(active: bool, animation_time: float) -> void:
	var changed := thermal_active != active
	thermal_active = active
	thermal_visual_time = animation_time + float(get_instance_id() % 29) * 0.19
	var frame := int(thermal_visual_time * THERMAL_FIRE_FPS) % THERMAL_FIRE_FRAME_COUNT
	var frame_changed := frame != thermal_fire_frame
	thermal_fire_frame = frame
	if changed or (active and frame_changed):
		queue_redraw()


func _spawn_death_effect() -> void:
	var game := get_parent()
	if game != null and game.has_method("spawn_combat_effect"):
		game.spawn_combat_effect(global_position, CombatEffect.Type.ENEMY_DEATH, maxf(hit_radius / 14.0, 0.8))


func _draw_enemy_art(kind: int, width: float, bar_color: Color) -> void:
	var bounds := ART_REGIONS[kind]
	var art := ENEMY_ART
	if movement_animation_active and int(visual_time * 5.0) % 2 == 1:
		art = ENEMY_ART_MOTION
	var source := Rect2(bounds.position * art.get_size(), bounds.size * art.get_size())
	if kind < 6:
		width *= 1.2
	var size := Vector2(width, width * source.size.y / source.size.x)
	# The walking mine (kind 3) faces left in the atlas; the other art faces right.
	# Mirror only the sprite, so the health bar remains readable.
	var player_is_left := target_position.x < global_position.x
	var flip_art := not player_is_left if kind == 3 else player_is_left
	var art_tint := Color(1.0, 0.78, 0.60) if thermal_active else Color.WHITE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if flip_art else 1.0, 1.0))
	if ART_CLIP_BANDS.has(kind):
		for band: Rect2 in ART_CLIP_BANDS[kind]:
			var relative_position := (band.position - bounds.position) / bounds.size
			var relative_size := band.size / bounds.size
			var destination := Rect2(-size * 0.5 + relative_position * size, relative_size * size)
			draw_texture_rect_region(art, destination, Rect2(band.position * art.get_size(), band.size * art.get_size()), art_tint, false, true)
	else:
		draw_texture_rect_region(art, Rect2(-size * 0.5, size), source, art_tint, false, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if thermal_active:
		_draw_thermal_flames(size)
	var bar_width := width * 0.75
	var bar_y := -size.y * 0.5 - 5.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 3.0), Color("160d18"))
	draw_rect(Rect2(-bar_width * 0.5 + 1.0, bar_y + 1.0,
		(bar_width - 2.0) * float(health) / float(max_health), 1.0), bar_color)


func _draw_thermal_flames(size: Vector2) -> void:
	# One shared atlas / one quad per burning enemy, no polygons or particles.
	var cell := Vector2(THERMAL_FIRE.get_width() / float(THERMAL_FIRE_FRAME_COUNT), THERMAL_FIRE.get_height())
	var source := Rect2(Vector2(thermal_fire_frame * cell.x, 0), cell)
	var width := clampf(size.x * 0.9, 26.0, 90.0)
	var destination_size := Vector2(width, width * cell.y / cell.x)
	var destination := Rect2(Vector2(-width * 0.5, size.y * 0.3 - destination_size.y * 0.85), destination_size)
	draw_texture_rect_region(THERMAL_FIRE, destination, source, Color(1.0, 1.0, 1.0, 0.72), false, true)
