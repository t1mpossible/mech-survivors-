class_name EnemyRocket
extends Node2D

const PROJECTILE_ART := preload("res://assets/projectiles_v1.png")
const TURRET_SHELL_ART := preload("res://assets/purple_turret_shell_v1.png")
const TURRET_SHELL_TRAIL := preload("res://assets/purple_turret_shell_trail_3frames_v1.png")

enum ProjectileKind { ROCKET, TURRET_SHELL }

var direction := Vector2.LEFT
var speed := 48.0
var damage := 7.0
var player_position := Vector2.ZERO
var lifetime := 4.0
var homing_time := 0.0
var active := false
var visual_time := 0.0
var projectile_kind := ProjectileKind.ROCKET

signal hit_player(amount: float)


func _ready() -> void:
	add_to_group("enemy_rockets")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_direction: Vector2, new_speed: float, new_damage: float, new_homing_time: float = 0.0, new_lifetime: float = 4.0, new_scale: Vector2 = Vector2.ONE, new_projectile_kind: int = ProjectileKind.ROCKET) -> void:
	global_position = start_position
	direction = new_direction
	speed = new_speed
	damage = new_damage
	homing_time = new_homing_time
	lifetime = new_lifetime
	scale = new_scale
	projectile_kind = new_projectile_kind
	visual_time = 0.0
	rotation = direction.angle()
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	visual_time += delta
	if homing_time > 0.0:
		direction = (player_position - global_position).normalized()
		homing_time -= delta
		rotation = direction.angle()
	global_position += direction * speed * delta
	queue_redraw()
	lifetime -= delta
	if global_position.distance_to(player_position) < 9.0:
		_spawn_player_impact()
		hit_player.emit(damage)
		deactivate()
	elif lifetime <= 0.0:
		deactivate()


func _draw() -> void:
	if projectile_kind == ProjectileKind.TURRET_SHELL:
		_draw_turret_shell()
		return
	_draw_projectile_frame(2, Vector2(23, 13))


func _draw_turret_shell() -> void:
	# Three baked frames replace procedural lines: still one draw per moving shell.
	var frame := int(visual_time * 12.0) % 3
	var cell := Vector2(TURRET_SHELL_TRAIL.get_width() / 3.0, TURRET_SHELL_TRAIL.get_height())
	var source := Rect2(Vector2(frame * cell.x, 0.0), cell)
	# An intentionally bold animated wake keeps the small shell readable in battle.
	draw_texture_rect_region(TURRET_SHELL_TRAIL, Rect2(-30.0, -7.5, 29.0, 15.0), source, Color.WHITE, false, true)
	# 20% thinner than the previous shell while keeping its readable length.
	draw_texture_rect(TURRET_SHELL_ART, Rect2(-10.2, -5.44, 20.4, 10.88), false)


func _draw_projectile_frame(column: int, size: Vector2) -> void:
	draw_line(Vector2(-17.0, 0.0), Vector2(-4.0, 0.0), Color(1.0, 0.22, 0.14, 0.52), 2.4)
	var frame := int(visual_time * 12.0) % 2
	var cell := Vector2(PROJECTILE_ART.get_width() / 4.0, PROJECTILE_ART.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_texture_rect_region(PROJECTILE_ART, Rect2(-size * 0.5, size), source)


func _spawn_player_impact() -> void:
	var game := get_parent()
	if game != null and game.has_method("spawn_combat_effect"):
		game.spawn_combat_effect(global_position, CombatEffect.Type.PLAYER_IMPACT)
