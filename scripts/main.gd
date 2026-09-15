extends Node2D

const ARENA_SIZE := Vector2(320, 180)
const PLASMA_ROUND := preload("res://scenes/plasma_round.tscn")
const XP_ORB := preload("res://scenes/xp_orb.tscn")
const SCOUT_SCENE := preload("res://scenes/alien_scout.tscn")
const HUNTER_MISSILE := preload("res://scenes/hunter_missile.tscn")
const AUTOCANNON_COOLDOWN := 1.0
const MAX_SCOUTS := 3
const BASE_EXPERIENCE_TO_LEVEL := 25
const EXPERIENCE_PER_LEVEL := 12

var mech_position := ARENA_SIZE / 2.0
var touch_direction := {"up": false, "down": false, "left": false, "right": false}
var cannon_time_left := 0.0
var scout_respawn_time_left := 0.0
var pending_scout_respawns := 0
var scout_spawn_index := 1
var move_speed := 72.0
var mech_max_health := 100.0
var mech_health := 100.0
var repair_per_second := 0.0
var experience := 0
var level := 1
var experience_to_next_level := BASE_EXPERIENCE_TO_LEVEL
var weapon_level := 1
var weapon_damage := 10
var weapon_cooldown := AUTOCANNON_COOLDOWN
var autocannon_salvo := 1
var autocannon_evolved := false
var missile_unlocked := false
var missile_level := 0
var missile_damage := 20
var missile_cooldown := 3.0
var missile_time_left := 1.5
var missile_evolved := false
var upgrade_open := false
var mech_destroyed := false
var available_upgrades: Array[Dictionary] = []

@onready var initial_scout: AlienScout = $Scout


func _ready() -> void:
	_connect_scout(initial_scout)
	for index in range(MAX_SCOUTS - 1):
		_spawn_scout()
	_update_experience_label()
	_update_health_label()
	queue_redraw()


func _process(delta: float) -> void:
	if upgrade_open or mech_destroyed:
		return

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement += Vector2(
		float(touch_direction["right"]) - float(touch_direction["left"]),
		float(touch_direction["down"]) - float(touch_direction["up"])
	)

	if movement.length() > 1.0:
		movement = movement.normalized()

	mech_position += movement * move_speed * delta
	mech_position.x = clampf(mech_position.x, 15.0, ARENA_SIZE.x - 15.0)
	mech_position.y = clampf(mech_position.y, 30.0, ARENA_SIZE.y - 15.0)
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null:
			enemy.target_position = mech_position
			if enemy.global_position.distance_to(mech_position) < 24.0:
				_take_damage(enemy.contact_damage_per_second * delta)

	if pending_scout_respawns > 0:
		scout_respawn_time_left -= delta
		if scout_respawn_time_left <= 0.0:
			_spawn_scout()
			pending_scout_respawns -= 1
			if pending_scout_respawns > 0:
				scout_respawn_time_left = 0.7

	for orb_node in get_tree().get_nodes_in_group("xp_orbs"):
		var orb := orb_node as XpOrb
		if orb != null:
			orb.player_position = mech_position

	if repair_per_second > 0.0:
		mech_health = minf(mech_max_health, mech_health + repair_per_second * delta)
		_update_health_label()

	cannon_time_left -= delta
	if cannon_time_left <= 0.0:
		var target := _get_nearest_enemy()
		if target != null:
			_fire_autocannon(target)
			cannon_time_left = weapon_cooldown

	if missile_unlocked:
		missile_time_left -= delta
		if missile_time_left <= 0.0:
			var missile_target := _get_nearest_enemy()
			if missile_target != null:
				_fire_hunter_missile(missile_target)
				missile_time_left = missile_cooldown
	queue_redraw()


func _set_touch_direction(direction: String, pressed: bool) -> void:
	touch_direction[direction] = pressed


func _get_nearest_enemy() -> AlienScout:
	var nearest: AlienScout
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy == null:
			continue
		var distance := mech_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _fire_autocannon(target: AlienScout) -> void:
	for shot_index in autocannon_salvo:
		var round := PLASMA_ROUND.instantiate() as PlasmaRound
		$Projectiles.add_child(round)
		round.global_position = mech_position + Vector2(11, -2 + (shot_index - 1) * 4)
		round.target = target
		round.damage = weapon_damage


func _fire_hunter_missile(target: AlienScout) -> void:
	var missile := HUNTER_MISSILE.instantiate() as HunterMissile
	$Projectiles.add_child(missile)
	missile.global_position = mech_position + Vector2(-4, -9)
	missile.target = target
	missile.damage = missile_damage
	if missile_evolved:
		missile.speed = 55.0
		missile.explosion_radius = 46.0


func _on_scout_health_changed(current_health: int, maximum_health: int) -> void:
	$Hud/EnemyStatus.text = "РАЗВЕДЧИК: %d / %d HP" % [current_health, maximum_health]


func _on_scout_died(dead_scout: AlienScout) -> void:
	var orb := XP_ORB.instantiate() as XpOrb
	$Pickups.add_child(orb)
	orb.global_position = dead_scout.global_position
	orb.collected.connect(_collect_experience)
	pending_scout_respawns += 1
	scout_respawn_time_left = 2.0
	$Hud/EnemyStatus.text = "ОРБ ОПЫТА СБРОШЕН"


func _connect_scout(new_scout: AlienScout) -> void:
	new_scout.health_changed.connect(_on_scout_health_changed)
	new_scout.died.connect(_on_scout_died.bind(new_scout))


func _spawn_scout() -> void:
	var new_scout := SCOUT_SCENE.instantiate() as AlienScout
	add_child(new_scout)
	var spawn_positions := [Vector2(35, 48), Vector2(282, 52), Vector2(164, 155)]
	new_scout.global_position = spawn_positions[scout_spawn_index % spawn_positions.size()]
	scout_spawn_index += 1
	_connect_scout(new_scout)
	$Hud/EnemyStatus.text = "СИГНАЛ: РАЗВЕДЧИК ОБНАРУЖЕН"


func _collect_experience(amount: int) -> void:
	experience += amount
	if experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = BASE_EXPERIENCE_TO_LEVEL + (level - 1) * EXPERIENCE_PER_LEVEL
		_open_upgrade_choice()
	_update_experience_label()


func _update_experience_label() -> void:
	$Hud/Level.text = "LV %d" % level
	$Hud/ExperienceBar.max_value = experience_to_next_level
	$Hud/ExperienceBar.value = experience
	$Hud/ExperienceValue.text = "%d/%d" % [experience, experience_to_next_level]


func _open_upgrade_choice() -> void:
	upgrade_open = true
	if weapon_level == 6 and not autocannon_evolved:
		available_upgrades = [
			{"kind": "evolve_autocannon", "title": "УР. 7: ШКВАЛ — ТРОЙНОЙ ЗАЛП"},
			_get_other_weapon_upgrade(),
			_get_character_upgrade()
		]
	elif missile_unlocked and missile_level == 6 and not missile_evolved:
		available_upgrades = [
			{"kind": "evolve_missile", "title": "УР. 7: ОСАДНЫЙ ЗАРЯД — ВЗРЫВ ПО ОБЛАСТИ"},
			_get_other_weapon_upgrade(),
			_get_character_upgrade()
		]
	elif not missile_unlocked and level >= 3:
		available_upgrades = [
			{"kind": "weapon_damage", "title": "АВТОПУШКА: +5 урона"},
			{"kind": "unlock_missile", "title": "НОВОЕ ОРУЖИЕ: ОХОТНИЧЬИ РАКЕТЫ"},
			_get_character_upgrade()
		]
	elif missile_unlocked and weapon_level < 6 and missile_level < 6:
		available_upgrades = [
			{"kind": "weapon_damage", "title": "АВТОПУШКА: +5 урона"},
			{"kind": "missile_damage", "title": "РАКЕТЫ: +10 урона"},
			_get_character_upgrade()
		]
	elif missile_unlocked and missile_level < 6:
		available_upgrades = [
			{"kind": "missile_damage", "title": "РАКЕТЫ: +10 урона"},
			{"kind": "missile_rate", "title": "РАКЕТЫ: +20% к темпу"},
			_get_character_upgrade()
		]
	elif weapon_level < 6:
		available_upgrades = [
			{"kind": "weapon_damage", "title": "АВТОПУШКА: +5 урона"},
			{"kind": "weapon_rate", "title": "АВТОПУШКА: +20% к темпу"},
			_get_character_upgrade()
		]
	else:
		available_upgrades = [_get_character_upgrade(), _get_character_upgrade(), _get_character_upgrade()]
	$Hud/UpgradePanel.visible = true
	$Hud/UpgradePanel/OptionA.text = available_upgrades[0].title
	$Hud/UpgradePanel/OptionB.text = available_upgrades[1].title
	$Hud/UpgradePanel/OptionC.text = available_upgrades[2].title


func _get_character_upgrade() -> Dictionary:
	var choices: Array[Dictionary] = [
		{"kind": "max_health", "title": "БРОНЯ: +20 максимального HP"},
		{"kind": "repair", "title": "РЕМОНТ: +1 HP в секунду"},
		{"kind": "speed", "title": "ДВИГАТЕЛИ: +10% скорости"}
	]
	return choices.pick_random()


func _get_other_weapon_upgrade() -> Dictionary:
	if not missile_unlocked and level >= 3:
		return {"kind": "unlock_missile", "title": "НОВОЕ ОРУЖИЕ: ОХОТНИЧЬИ РАКЕТЫ"}
	if missile_unlocked and missile_level < 6:
		return {"kind": "missile_damage", "title": "РАКЕТЫ: +10 урона"}
	if weapon_level < 6:
		return {"kind": "weapon_damage", "title": "АВТОПУШКА: +5 урона"}
	return _get_character_upgrade()


func _choose_upgrade(index: int) -> void:
	var choice := available_upgrades[index]
	match choice.kind:
		"weapon_damage":
			weapon_level += 1
			weapon_damage += 5
			$Hud/EnemyStatus.text = "АВТОПУШКА УР. %d: %d УРОНА" % [weapon_level, weapon_damage]
		"weapon_rate":
			weapon_level += 1
			weapon_cooldown *= 0.8
			$Hud/EnemyStatus.text = "АВТОПУШКА УР. %d: ТЕМП +20%%" % weapon_level
		"evolve_autocannon":
			weapon_level = 7
			autocannon_evolved = true
			autocannon_salvo = 3
			$Hud/EnemyStatus.text = "ЭВОЛЮЦИЯ: ШКВАЛ — ТРОЙНОЙ ЗАЛП"
		"unlock_missile":
			missile_unlocked = true
			missile_level = 1
			missile_time_left = 0.2
			$Hud/EnemyStatus.text = "ОРУЖИЕ ПОЛУЧЕНО: ОХОТНИЧЬИ РАКЕТЫ"
		"missile_damage":
			missile_level += 1
			missile_damage += 10
			$Hud/EnemyStatus.text = "РАКЕТЫ УР. %d: %d УРОНА" % [missile_level, missile_damage]
		"missile_rate":
			missile_level += 1
			missile_cooldown *= 0.8
			$Hud/EnemyStatus.text = "РАКЕТЫ УР. %d: ТЕМП +20%%" % missile_level
		"evolve_missile":
			missile_level = 7
			missile_evolved = true
			missile_damage = 70
			$Hud/EnemyStatus.text = "ЭВОЛЮЦИЯ: ОСАДНЫЙ ЗАРЯД"
		"max_health":
			mech_max_health += 20
			mech_health += 20
		"repair":
			repair_per_second += 1.0
		"speed":
			move_speed *= 1.1
	$Hud/UpgradePanel.visible = false
	upgrade_open = false
	_update_health_label()


func _take_damage(amount: float) -> void:
	mech_health = maxf(mech_health - amount, 0.0)
	_update_health_label()
	if mech_health <= 0.0:
		mech_destroyed = true
		$Hud/EnemyStatus.text = "МЕХ УНИЧТОЖЕН — ПЕРЕЗАПУСТИТЕ ИГРУ"


func _update_health_label() -> void:
	$Hud/HealthBar.max_value = mech_max_health
	$Hud/HealthBar.value = mech_health
	$Hud/HealthValue.text = "%d/%d" % [ceili(mech_health), ceili(mech_max_health)]


func _draw() -> void:
	# Alien planet ground: deliberately simple so gameplay remains the focus for now.
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), Color("101d29"))

	for x in range(0, 321, 16):
		draw_line(Vector2(x, 25), Vector2(x, 180), Color("172a36"), 1.0)
	for y in range(25, 181, 16):
		draw_line(Vector2(0, y), Vector2(320, y), Color("172a36"), 1.0)

	# Craters and alien vegetation are placeholders for later planet tiles.
	draw_circle(Vector2(47, 55), 12.0, Color("183b40"))
	draw_circle(Vector2(264, 73), 16.0, Color("183b40"))
	draw_circle(Vector2(93, 145), 10.0, Color("183b40"))
	draw_circle(Vector2(210, 135), 7.0, Color("24584b"))
	draw_circle(Vector2(215, 130), 3.0, Color("57b88b"))

	_draw_mech(mech_position)


func _draw_mech(center: Vector2) -> void:
	# A clear placeholder silhouette: blue armor, cyan cockpit, orange cannon.
	draw_circle(center + Vector2(1, 3), 12.0, Color("09121c"))
	draw_rect(Rect2(center + Vector2(-10, -8), Vector2(20, 18)), Color("376b86"))
	draw_rect(Rect2(center + Vector2(-7, -11), Vector2(14, 7)), Color("5797ad"))
	draw_rect(Rect2(center + Vector2(-4, -9), Vector2(8, 5)), Color("8de7e7"))
	draw_rect(Rect2(center + Vector2(8, -3), Vector2(10, 4)), Color("e8a942"))
	draw_rect(Rect2(center + Vector2(-13, 5), Vector2(5, 8)), Color("284b62"))
	draw_rect(Rect2(center + Vector2(8, 5), Vector2(5, 8)), Color("284b62"))
	draw_rect(Rect2(center + Vector2(-7, 10), Vector2(5, 4)), Color("1b3041"))
	draw_rect(Rect2(center + Vector2(2, 10), Vector2(5, 4)), Color("1b3041"))
