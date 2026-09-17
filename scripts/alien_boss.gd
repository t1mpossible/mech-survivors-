class_name AlienBoss
extends AlienScout

const ENEMY_ROCKET := preload("res://scenes/enemy_rocket.tscn")
const BOSS_MINE := preload("res://scenes/boss_mine.tscn")
const PHASE_HEALTH := 2000

var phase := 1
var rocket_time_left := 1.5
var mine_time_left := 2.5


func _ready() -> void:
	movement_speed = 12.0
	max_health = PHASE_HEALTH
	health = PHASE_HEALTH
	contact_damage_per_second = 24.0
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
			rocket_time_left = 3.0
	if phase == 2 or phase == 3:
		mine_time_left -= delta
		if mine_time_left <= 0.0:
			_launch_mine_pair()
			mine_time_left = 2.5 if phase == 2 else 5.0


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health == 0:
		if phase < 3:
			phase += 1
			health = PHASE_HEALTH
			health_changed.emit(health, max_health)
			queue_redraw()
			rocket_time_left = 0.8
			mine_time_left = 1.2
		else:
			died.emit()
			queue_free()


func _launch_rocket_pair() -> void:
	for side in [-30.0, 30.0]:
		var rocket: EnemyRocket = get_parent().call("acquire_enemy_rocket") as EnemyRocket
		if rocket != null:
			var start_position := global_position + Vector2(side, -13)
			rocket.activate(start_position, (target_position - start_position).normalized(), 36.0, 19.0, 3.0, 6.0, Vector2(1.6, 1.6))


func _launch_mine_pair() -> void:
	if not get_parent().call("allow_enemy_hazard"):
		return
	for side in [-30.0, 30.0]:
		var mine := BOSS_MINE.instantiate() as BossMine
		get_parent().add_child(mine)
		mine.global_position = global_position + Vector2(side, 13)
		mine.direction = (target_position - mine.global_position).normalized()
		mine.speed = 60.0


func _draw() -> void:
	# Four turret sockets: upper pair launches rockets, lower pair launches mines.
	draw_circle(Vector2(3, 8), 42.0, Color("09111c"))
	draw_rect(Rect2(-36, -25, 72, 54), Color("586879"))
	draw_rect(Rect2(-28, -19, 56, 40), Color("7d90a0"))
	draw_circle(Vector2.ZERO, 15.0, Color("aee6ee"))
	draw_circle(Vector2.ZERO, 7.0, Color("47a6c5"))
	for turret in [Vector2(-30, -19), Vector2(30, -19), Vector2(-30, 19), Vector2(30, 19)]:
		draw_circle(turret, 10.0, Color("293746"))
		draw_rect(Rect2(turret + Vector2(-4, -10), Vector2(8, 14)), Color("d1e1e4"))
	draw_rect(Rect2(-48, -54, 96, 5), Color("0d1420"))
	draw_rect(Rect2(-47, -53, 94.0 * float(health) / float(max_health), 3), Color("54d8e6"))
