extends Node2D

const MAP_SIZE := Vector2(1600, 900)
const PLASMA_ROUND := preload("res://scenes/plasma_round.tscn")
const XP_ORB := preload("res://scenes/xp_orb.tscn")
const HEALTH_PACK_SCENE := preload("res://scenes/health_pack.tscn")
const SCOUT_SCENE := preload("res://scenes/alien_scout.tscn")
const BRUTE_SCENE := preload("res://scenes/alien_brute.tscn")
const ELITE_SCENE := preload("res://scenes/alien_elite.tscn")
const BOMBER_SCENE := preload("res://scenes/alien_bomber.tscn")
const TURRET_SCENE := preload("res://scenes/alien_turret.tscn")
const MORTAR_SCENE := preload("res://scenes/alien_mortar.tscn")
const BOSS_SCENE := preload("res://scenes/alien_boss.tscn")
const HUNTER_MISSILE := preload("res://scenes/hunter_missile.tscn")
const AUTOCANNON_COOLDOWN := 1.0
const PLANET_COUNT := 5
const WAVES_PER_PLANET := 6
const WAVE_DURATION := 60.0
const BASE_EXPERIENCE_TO_LEVEL := 25
const EXPERIENCE_PER_LEVEL := 12

var mech_position := MAP_SIZE / 2.0
var touch_direction := {"up": false, "down": false, "left": false, "right": false}
var cannon_time_left := 0.0
var small_spawn_time_left := 0.2
var medium_spawn_time_left := 0.6
var bomber_spawn_time_left := 1.0
var turret_spawn_time_left := 1.0
var mortar_spawn_time_left := 1.0
var large_spawn_time_left := 10.0
var boss: AlienBoss
var health_pack_spawn_time_left := 4.0
var planet_number := 1
var wave_number := 1
var wave_elapsed := 0.0
var last_wave_stage := 0
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
var laser_unlocked := false
var laser_tick := 0.0
var laser_target: AlienScout
var laser_level := 1
var laser_damage := 3
var laser_cooldown := 0.25
var shuriken_unlocked := false
var shuriken_level := 1
var shuriken_damage := 24
var shuriken_angle := 0.0
var shuriken_radius := 40.0
var shuriken_hit_time_left := 0.0
var upgrade_open := false
var mech_destroyed := false
var manual_paused := false
var available_upgrades: Array[Dictionary] = []

@onready var initial_scout: AlienScout = $Scout
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	initial_scout.global_position = _get_wave_spawn_position()
	_connect_scout(initial_scout)
	_update_experience_label()
	_update_health_label()
	_update_wave_hud()
	queue_redraw()


func _process(delta: float) -> void:
	$Hud/Fps.text = "FPS %d" % Engine.get_frames_per_second()
	if manual_paused or upgrade_open or mech_destroyed:
		return

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement += Vector2(
		float(touch_direction["right"]) - float(touch_direction["left"]),
		float(touch_direction["down"]) - float(touch_direction["up"])
	)

	if movement.length() > 1.0:
		movement = movement.normalized()

	mech_position += movement * move_speed * delta
	mech_position.x = clampf(mech_position.x, 15.0, MAP_SIZE.x - 15.0)
	mech_position.y = clampf(mech_position.y, 15.0, MAP_SIZE.y - 15.0)
	camera.global_position = mech_position
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null:
			enemy.target_position = mech_position
			if enemy.global_position.distance_to(mech_position) < 24.0:
				_take_damage(enemy.contact_damage_per_second * delta)

	_update_wave_progress(delta)
	_update_wave_spawns(delta)

	for rocket_node in get_tree().get_nodes_in_group("enemy_rockets"):
		var enemy_rocket := rocket_node as EnemyRocket
		if enemy_rocket != null:
			enemy_rocket.player_position = mech_position

	for orb_node in get_tree().get_nodes_in_group("xp_orbs"):
		var orb := orb_node as XpOrb
		if orb != null:
			orb.player_position = mech_position

	for pack_node in get_tree().get_nodes_in_group("health_packs"):
		var health_pack := pack_node as HealthPack
		if health_pack != null:
			health_pack.player_position = mech_position

	if get_tree().get_nodes_in_group("health_packs").size() < 6:
		health_pack_spawn_time_left -= delta
		if health_pack_spawn_time_left <= 0.0:
			_spawn_health_pack()
			health_pack_spawn_time_left = 5.0

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

	if laser_unlocked:
		laser_tick -= delta
		laser_target = _get_nearest_enemy()
		if laser_tick <= 0.0 and is_instance_valid(laser_target):
			laser_target.take_damage(laser_damage)
			laser_tick = laser_cooldown

	if shuriken_unlocked:
		shuriken_angle += delta * 5.36
		shuriken_hit_time_left -= delta
		if shuriken_hit_time_left <= 0.0:
			for angle_offset in [0.0, PI]:
				var shuriken_position := mech_position + Vector2(cos(shuriken_angle + angle_offset), sin(shuriken_angle + angle_offset)) * shuriken_radius
				for enemy_node in get_tree().get_nodes_in_group("enemies"):
					var enemy := enemy_node as AlienScout
					if enemy != null and enemy.global_position.distance_to(shuriken_position) <= 18.0:
						enemy.take_damage(shuriken_damage)
			shuriken_hit_time_left = 0.25
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
	orb.tier = dead_scout.xp_tier
	orb.experience_amount = dead_scout.experience_amount
	orb.collected.connect(_collect_experience)
	if dead_scout is AlienBoss:
		boss = null
		if wave_number == 6:
			planet_number = mini(planet_number + 1, PLANET_COUNT)
			wave_number = 1
			wave_elapsed = 0.0
			last_wave_stage = 0
			_update_wave_hud()
			$Hud/EnemyStatus.text = "ЗОНА %d ПРОЙДЕНА" % (planet_number - 1)
			return
	$Hud/EnemyStatus.text = "ОРБ ОПЫТА СБРОШЕН"


func _connect_scout(new_scout: AlienScout) -> void:
	new_scout.health_changed.connect(_on_scout_health_changed)
	new_scout.died.connect(_on_scout_died.bind(new_scout))


func _spawn_scout() -> void:
	var new_scout := SCOUT_SCENE.instantiate() as AlienScout
	add_child(new_scout)
	new_scout.global_position = _get_wave_spawn_position()
	_connect_scout(new_scout)
	$Hud/EnemyStatus.text = "СИГНАЛ: РАЗВЕДЧИК ОБНАРУЖЕН"


func _spawn_brute() -> void:
	var new_brute := BRUTE_SCENE.instantiate() as AlienBrute
	add_child(new_brute)
	new_brute.global_position = _get_wave_spawn_position()
	_connect_scout(new_brute)
	$Hud/EnemyStatus.text = "СИГНАЛ: БРОНИРОВАННЫЙ ПРИШЕЛЕЦ"


func _spawn_bomber() -> void:
	var bomber := BOMBER_SCENE.instantiate() as AlienBomber
	add_child(bomber)
	bomber.global_position = _get_wave_spawn_position()
	_connect_scout(bomber)
	$Hud/EnemyStatus.text = "СИГНАЛ: КАМИКАДЗЕ"

func _spawn_turret() -> void:
	var turret := TURRET_SCENE.instantiate() as AlienTurret
	add_child(turret)
	turret.global_position = _get_wave_spawn_position()
	_connect_scout(turret)

func _spawn_mortar() -> void:
	var mortar := MORTAR_SCENE.instantiate() as AlienMortar
	add_child(mortar)
	mortar.global_position = _get_wave_spawn_position()
	_connect_scout(mortar)

func _count_turrets() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienTurret:
			count += 1
	return count


func _spawn_elite() -> void:
	var new_elite := ELITE_SCENE.instantiate() as AlienElite
	add_child(new_elite)
	new_elite.global_position = _get_wave_spawn_position()
	_connect_scout(new_elite)
	$Hud/EnemyStatus.text = "СИГНАЛ: ЭЛИТНЫЙ РАКЕТНИК"


func _spawn_boss() -> void:
	if is_instance_valid(boss):
		return
	boss = BOSS_SCENE.instantiate() as AlienBoss
	add_child(boss)
	boss.global_position = _get_wave_spawn_position()
	_connect_scout(boss)
	$Hud/EnemyStatus.text = "БОСС: ОСАДНЫЙ ХОДОК — ФАЗА 1"


func _debug_spawn_scout() -> void:
	_spawn_scout()


func _debug_spawn_brute() -> void:
	_spawn_brute()


func _debug_spawn_elite() -> void:
	_spawn_elite()


func _debug_spawn_boss() -> void:
	_spawn_boss()


func _spawn_health_pack() -> void:
	var health_pack := HEALTH_PACK_SCENE.instantiate() as HealthPack
	$Pickups.add_child(health_pack)
	health_pack.global_position = _get_random_world_position(120.0)
	health_pack.collected.connect(_collect_health_pack)


func _collect_health_pack(heal_fraction: float) -> void:
	mech_health = minf(mech_max_health, mech_health + mech_max_health * heal_fraction)
	$Hud/EnemyStatus.text = "АПТЕЧКА: +25% HP"
	_update_health_label()


func _count_scouts() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienScout and not (enemy_node is AlienBrute) and not (enemy_node is AlienElite) and not (enemy_node is AlienBoss) and not (enemy_node is AlienBomber):
			count += 1
	return count


func _count_brutes() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienBrute:
			count += 1
	return count


func _count_bombers() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienBomber:
			count += 1
	return count


func _count_elites() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienElite:
			count += 1
	return count


func _get_wave_spawn_position() -> Vector2:
	var offset := Vector2(randf_range(-300.0, 300.0), randf_range(-160.0, 160.0))
	if absf(offset.x) < 170.0 and absf(offset.y) < 100.0:
		offset.x = 260.0 if offset.x >= 0.0 else -260.0
	var position := mech_position + offset
	position.x = clampf(position.x, 35.0, MAP_SIZE.x - 35.0)
	position.y = clampf(position.y, 35.0, MAP_SIZE.y - 35.0)
	return position


func _get_random_world_position(minimum_distance: float) -> Vector2:
	var position := Vector2.ZERO
	for attempt in range(12):
		position = Vector2(
			randf_range(35.0, MAP_SIZE.x - 35.0),
			randf_range(35.0, MAP_SIZE.y - 35.0)
		)
		if position.distance_to(mech_position) >= minimum_distance:
			return position
	return position


func _update_wave_progress(delta: float) -> void:
	if wave_number == 6 and is_instance_valid(boss):
		_update_wave_hud()
		return
	wave_elapsed += delta
	if wave_elapsed >= WAVE_DURATION:
		wave_elapsed -= WAVE_DURATION
		wave_number += 1
		if wave_number > WAVES_PER_PLANET:
			wave_number = 1
			planet_number = mini(planet_number + 1, PLANET_COUNT)
		last_wave_stage = 0
	_update_wave_hud()


func _update_wave_spawns(delta: float) -> void:
	var limits := _get_wave_limits()
	_enforce_wave_caps(limits)
	if wave_number == 6 and not is_instance_valid(boss):
		_spawn_boss()
	if _count_scouts() < limits.small:
		small_spawn_time_left -= delta
		if small_spawn_time_left <= 0.0:
			_spawn_scout()
			small_spawn_time_left = 0.65

	if _count_brutes() < limits.medium:
		medium_spawn_time_left -= delta
		if medium_spawn_time_left <= 0.0:
			_spawn_brute()
			medium_spawn_time_left = 2.2

	if _count_bombers() < limits.bomber:
		bomber_spawn_time_left -= delta
		if bomber_spawn_time_left <= 0.0:
			_spawn_bomber()
			bomber_spawn_time_left = 2.5
	if _count_turrets() < limits.get("turret", 0):
		turret_spawn_time_left -= delta
		if turret_spawn_time_left <= 0.0:
			_spawn_turret()
			turret_spawn_time_left = 2.0

	if _count_elites() < limits.large:
		large_spawn_time_left -= delta
		if large_spawn_time_left <= 0.0:
			_spawn_elite()
			large_spawn_time_left = 10.0


func _enforce_wave_caps(limits: Dictionary) -> void:
	var small_enemies: Array[AlienScout] = []
	var medium_enemies: Array[AlienBrute] = []
	var bomber_enemies: Array[AlienBomber] = []
	var large_enemies: Array[AlienElite] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienElite:
			large_enemies.append(enemy_node)
		elif enemy_node is AlienBomber:
			bomber_enemies.append(enemy_node)
		elif enemy_node is AlienBrute:
			medium_enemies.append(enemy_node)
		elif enemy_node is AlienScout and not (enemy_node is AlienBoss):
			small_enemies.append(enemy_node)
	for index in range(limits.small, small_enemies.size()):
		small_enemies[index].queue_free()
	for index in range(limits.medium, medium_enemies.size()):
		medium_enemies[index].queue_free()
	for index in range(limits.bomber, bomber_enemies.size()):
		bomber_enemies[index].queue_free()
	for index in range(limits.large, large_enemies.size()):
		large_enemies[index].queue_free()


func _get_wave_limits() -> Dictionary:
	var second_stage_starts_at := 25.0 if wave_number == 1 else 30.0
	var stage := 2 if wave_elapsed >= second_stage_starts_at else 1
	if stage != last_wave_stage:
		last_wave_stage = stage
		small_spawn_time_left = minf(small_spawn_time_left, 0.2)
		medium_spawn_time_left = minf(medium_spawn_time_left, 0.4)
		large_spawn_time_left = minf(large_spawn_time_left, 0.5)
		$Hud/EnemyStatus.text = "ВОЛНА %d — СТАДИЯ %d" % [wave_number, stage]

	if wave_number == 1:
		if stage == 1:
			return {"small": 5, "medium": 1, "large": 0, "bomber": 0}
		return {"small": 7, "medium": 3, "large": 0, "bomber": 0}
	if wave_number == 2:
		if stage == 1:
			return {"small": 7, "medium": 3, "large": 1, "bomber": 0}
		return {"small": 5, "medium": 5, "large": 2, "bomber": 0}
	if wave_number == 3:
		if stage == 1:
			return {"small": 7, "medium": 4, "large": 1, "bomber": 1}
		return {"small": 8, "medium": 5, "large": 1, "bomber": 3}
	if wave_number == 4:
		if stage == 1:
			return {"small": 8, "medium": 5, "large": 2, "bomber": 3, "turret": 1}
		return {"small": 10, "medium": 6, "large": 2, "bomber": 4, "turret": 3}
	if wave_number == 5:
		if stage == 1:
			return {"small": 10, "medium": 6, "large": 2, "bomber": 4}
		return {"small": 12, "medium": 7, "large": 3, "bomber": 5}
	if wave_number == 6:
		return {"small": 0, "medium": 0, "large": 0, "bomber": 0}

	return {"small": 12, "medium": 7, "large": 3, "bomber": 5}


func _update_wave_hud() -> void:
	var second_stage_starts_at := 25.0 if wave_number == 1 else 30.0
	var stage := 2 if wave_elapsed >= second_stage_starts_at else 1
	$Hud/Wave.text = "ЗОНА %d  •  ВОЛНА %d/%d" % [planet_number, wave_number, WAVES_PER_PLANET]
	$Hud/WaveTimer.text = "СТАДИЯ %d  •  %d СЕК" % [stage, ceili(WAVE_DURATION - wave_elapsed)]


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
	get_tree().paused = true
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
	elif not laser_unlocked and level >= 4:
		available_upgrades = [
			{"kind": "unlock_laser", "title": "НОВОЕ ОРУЖИЕ: ПРОЖИГАЮЩИЙ ЛАЗЕР"},
			{"kind": "weapon_damage", "title": "АВТОПУШКА: +5 урона"},
			_get_character_upgrade()
		]
	elif not shuriken_unlocked and level >= 5:
		available_upgrades = [
			{"kind": "unlock_shuriken", "title": "НОВОЕ ОРУЖИЕ: ВРАЩАЮЩИЙСЯ ШИП"},
			{"kind": "missile_damage", "title": "РАКЕТЫ: +10 урона"},
			_get_character_upgrade()
		]
	elif laser_unlocked and laser_level < 6:
		available_upgrades = [
			{"kind": "laser_damage", "title": "ЛАЗЕР: +4 урона в секунду"},
			{"kind": "laser_rate", "title": "ЛАЗЕР: +20% к темпу"},
			_get_character_upgrade()
		]
	elif shuriken_unlocked and shuriken_level < 6:
		available_upgrades = [
			{"kind": "shuriken_damage", "title": "ШИП: +12 урона"},
			{"kind": "shuriken_radius", "title": "ШИП: +15 к радиусу"},
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
		"unlock_laser":
			laser_unlocked = true
			$Hud/EnemyStatus.text = "ОРУЖИЕ ПОЛУЧЕНО: ПРОЖИГАЮЩИЙ ЛАЗЕР"
		"unlock_shuriken":
			shuriken_unlocked = true
			$Hud/EnemyStatus.text = "ОРУЖИЕ ПОЛУЧЕНО: ВРАЩАЮЩИЙСЯ ШИП"
		"laser_damage":
			laser_level += 1
			laser_damage += 1
		"laser_rate":
			laser_level += 1
			laser_cooldown *= 0.8
		"shuriken_damage":
			shuriken_level += 1
			shuriken_damage += 12
		"shuriken_radius":
			shuriken_level += 1
			shuriken_radius += 15.0
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
	get_tree().paused = false
	_update_health_label()


func _take_damage(amount: float) -> void:
	mech_health = maxf(mech_health - amount, 0.0)
	_update_health_label()
	if mech_health <= 0.0:
		mech_destroyed = true
		get_tree().paused = true
		$Hud/GameOver.visible = true


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _toggle_pause() -> void:
	manual_paused = not manual_paused
	$Hud/PausePanel.visible = manual_paused
	get_tree().paused = manual_paused


func _resume_game() -> void:
	if manual_paused:
		_toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not upgrade_open and not mech_destroyed:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _update_health_label() -> void:
	$Hud/HealthBar.max_value = mech_max_health
	$Hud/HealthBar.value = mech_health
	$Hud/HealthValue.text = "%d/%d" % [ceili(mech_health), ceili(mech_max_health)]


func _draw() -> void:
	# A five-times-larger alien planet. Camera movement makes the terrain scroll beneath the mech.
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("101d29"))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("36556b"), false, 3.0)

	for x in range(0, int(MAP_SIZE.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), Color("142733"), 1.0)
	for y in range(0, int(MAP_SIZE.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), Color("142733"), 1.0)

	for landmark in [Vector2(210, 180), Vector2(420, 650), Vector2(620, 240), Vector2(840, 720), Vector2(1040, 160), Vector2(1250, 510), Vector2(1480, 760)]:
		draw_circle(landmark, 18.0, Color("183b40"))
		draw_circle(landmark + Vector2(5, -4), 5.0, Color("24584b"))

	_draw_mech(mech_position)
	if laser_unlocked and is_instance_valid(laser_target):
		draw_line(mech_position, laser_target.global_position, Color("ff5864"), 2.0)
	if shuriken_unlocked:
		for angle_offset in [0.0, PI]:
			var shuriken_position := mech_position + Vector2(cos(shuriken_angle + angle_offset), sin(shuriken_angle + angle_offset)) * shuriken_radius
			draw_circle(shuriken_position, 8.0, Color("1b2634"))
			draw_line(shuriken_position + Vector2(-8, -8), shuriken_position + Vector2(8, 8), Color("e7f3ff"), 3.0)
			draw_line(shuriken_position + Vector2(8, -8), shuriken_position + Vector2(-8, 8), Color("e7f3ff"), 3.0)


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
