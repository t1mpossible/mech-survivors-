class_name AlienTurret
extends AlienScout

const ROCKET := preload("res://scenes/enemy_rocket.tscn")
const TURRET_BASE_ART := preload("res://assets/alien_turret_mount_v2.png")
const TURRET_GUN_ART := preload("res://assets/alien_turret_gun_v3.png")

# The lower chassis is stationary. The vertically symmetrical cannon module can
# rotate freely around the circular joint without looking top- or bottom-heavy.
const TURRET_DRAW_WIDTH := 52.0
const TURRET_PIVOT := Vector2(0.0, -8.0)
# Texture-space landmarks include transparent padding. The gun anchor is the
# solid armour plate marked by the user, not the empty fork at the rear.
const BASE_PIVOT_UV := Vector2(0.531, 0.226)
const GUN_PIVOT_UV := Vector2(0.390, 0.500)
const GUN_MUZZLE_UV := Vector2(0.945, 0.500)
const GUN_DRAW_SIZE := Vector2(60.0, 30.0)
const TURRET_TURN_SPEED := deg_to_rad(240.0)

var cooldown := 1.4
var gun_angle := -PI * 0.5
var gun_angle_initialized := false


func _ready() -> void:
	movement_speed = 0.0
	max_health = 90
	health = 90
	hit_radius = 14.0
	experience_amount = 30
	xp_tier = XpOrb.Tier.LARGE_RED
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	# AlienScout adds a walking scale pulse even at zero movement speed.
	scale = base_visual_scale
	var desired_angle := _desired_gun_angle()
	if not gun_angle_initialized:
		gun_angle = desired_angle
		gun_angle_initialized = true
	else:
		gun_angle = rotate_toward(gun_angle, desired_angle, TURRET_TURN_SPEED * delta)

	cooldown -= delta
	if cooldown <= 0.0 and target_position != Vector2.ZERO:
		var bullet: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if bullet != null:
			var aim_direction := global_transform.basis_xform(_turret_direction()).normalized()
			bullet.activate(_muzzle_global_position(), aim_direction, 90.0, 18.0, 0.5, 4.0, Vector2.ONE, EnemyRocket.ProjectileKind.TURRET_SHELL)
		cooldown = 1.4
	queue_redraw()


func _draw() -> void:
	_draw_turret_base_and_head()


func _desired_gun_angle() -> float:
	var target_offset := to_local(target_position) - TURRET_PIVOT
	if target_offset.length_squared() <= 0.001:
		return gun_angle
	return target_offset.angle()


func _turret_direction() -> Vector2:
	return Vector2.from_angle(gun_angle)


func _muzzle_global_position(aim_direction: Vector2 = Vector2.ZERO) -> Vector2:
	var angle := gun_angle if aim_direction == Vector2.ZERO else aim_direction.angle()
	var muzzle_offset := (GUN_MUZZLE_UV - GUN_PIVOT_UV) * GUN_DRAW_SIZE
	return to_global(TURRET_PIVOT + muzzle_offset.rotated(angle))


func _gun_draw_rect() -> Rect2:
	return Rect2(-GUN_PIVOT_UV * GUN_DRAW_SIZE, GUN_DRAW_SIZE)


func _base_draw_rect() -> Rect2:
	var size := Vector2.ONE * TURRET_DRAW_WIDTH
	return Rect2(TURRET_PIVOT - BASE_PIVOT_UV * size, size)


func _draw_turret_base_and_head() -> void:
	# New paired sprites: lower base is fixed; only the gun rotates at its socket.
	var tint := Color(1.0, 0.78, 0.60) if thermal_active else Color.WHITE
	var base_size := Vector2(TURRET_DRAW_WIDTH, TURRET_DRAW_WIDTH)
	_draw_ground_shadow(Vector2(0.0, base_size.y * 0.34), base_size.x * 0.38, base_size.y * 0.08)
	# Both texture landmarks coincide at exactly the same stationary axis.
	draw_texture_rect(TURRET_BASE_ART, _base_draw_rect(), false, tint)

	draw_set_transform(TURRET_PIVOT, gun_angle)
	draw_texture_rect(TURRET_GUN_ART, _gun_draw_rect(), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0)

	if thermal_active:
		_draw_thermal_flames(base_size)
	var bar_width := TURRET_DRAW_WIDTH * 0.75
	# Keep HP above the entire swept barrel, including when aiming straight up.
	var bar_y := TURRET_PIVOT.y - 46.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 3.0), Color("160d18"))
	draw_rect(Rect2(-bar_width * 0.5 + 1.0, bar_y + 1.0, (bar_width - 2.0) * float(health) / float(max_health), 1.0), Color("b38cff"))
