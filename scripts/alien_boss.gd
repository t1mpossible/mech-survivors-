class_name AlienBoss
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")
const BOSS_MINE := preload("res://scenes/boss_mine.tscn")
const PHASE_HEALTH := 2000
const PHASE_THREE_HEALTH := 2660

var phase := 1
var rocket_time_left := 1.5
var mine_time_left := 2.5
var delayed_mine_pair_time_left := -1.0
const ROCKET_INTERVAL_PHASE_ONE := 3.0 * 0.85
const BOSS_ROCKET_SPEED := 36.0 * 1.44
const MINE_PROJECTILE_SPEED := 60.0 * 1.25
const MINE_PROJECTILE_FLIGHT_TIME := 1.3


func _ready() -> void:
	movement_speed = 12.0
	max_health = PHASE_HEALTH
	health = PHASE_HEALTH
	contact_damage_per_second = 24.0
	hit_radius = 36.0
	experience_amount = 500
	xp_tier = XpOrb.Tier.ELITE_BLUE
	super._ready()
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	if phase == 1 or phase == 3:
		rocket_time_left -= delta
		if rocket_time_left <= 0.0:
			_launch_rocket_pair()
			rocket_time_left = ROCKET_INTERVAL_PHASE_ONE if phase == 1 else 3.0
	if phase == 2 or phase == 3:
		if delayed_mine_pair_time_left >= 0.0:
			delayed_mine_pair_time_left -= delta
			if delayed_mine_pair_time_left <= 0.0:
				_launch_mine_pair()
				delayed_mine_pair_time_left = -1.0
		mine_time_left -= delta
		if mine_time_left <= 0.0:
			if _launch_mine_pair():
				delayed_mine_pair_time_left = 0.3
			mine_time_left = 2.5 if phase == 2 else 5.0


func take_damage(amount: int, death_effect_type: int = CombatEffect.Type.ENEMY_DISSOLVE) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health == 0:
		if phase < 3:
			phase += 1
			max_health = PHASE_THREE_HEALTH if phase == 3 else PHASE_HEALTH
			health = max_health
			health_changed.emit(health, max_health)
			queue_redraw()
			rocket_time_left = 0.8
			mine_time_left = 1.2
		else:
			_spawn_death_effect(death_effect_type)
			died.emit()
			queue_free()


func _launch_rocket_pair() -> void:
	for side in [-30.0, 30.0]:
		var rocket: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if rocket != null:
			var start_position := global_position + Vector2(side, -13)
			rocket.activate(start_position, (target_position - start_position).normalized(), BOSS_ROCKET_SPEED, 19.0, 3.0, 6.0, Vector2(1.6, 1.6))


func _launch_mine_pair() -> bool:
	if not get_parent().call("allow_enemy_hazard"):
		return false
	for side in [-30.0, 30.0]:
		var mine := BOSS_MINE.instantiate() as BossMine
		get_parent().add_child(mine)
		mine.global_position = global_position + Vector2(side, 13)
		mine.direction = (target_position - mine.global_position).normalized()
		mine.speed = MINE_PROJECTILE_SPEED
		mine.fall_time = MINE_PROJECTILE_FLIGHT_TIME
	return true


func _draw() -> void:
	_draw_enemy_art(6, 94.0, Color("ff654f"))
