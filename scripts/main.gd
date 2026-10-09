extends Node2D

const MAP_SIZE := Vector2(1600, 900)
const PLASMA_ROUND := preload("res://scenes/plasma_round.tscn")
const XP_ORB := preload("res://scenes/xp_orb.tscn")
const HEALTH_PACK_SCENE := preload("res://scenes/health_pack.tscn")
const POWERUP_SCENE := preload("res://scenes/powerup.tscn")
const SCOUT_SCENE := preload("res://scenes/alien_scout.tscn")
const BRUTE_SCENE := preload("res://scenes/alien_brute.tscn")
const ELITE_SCENE := preload("res://scenes/alien_elite.tscn")
const BOMBER_SCENE := preload("res://scenes/alien_bomber.tscn")
const TURRET_SCENE := preload("res://scenes/alien_turret.tscn")
const MORTAR_SCENE := preload("res://scenes/alien_mortar.tscn")
const BOSS_SCENE := preload("res://scenes/alien_boss.tscn")
const HUNTER_MISSILE := preload("res://scenes/hunter_missile.tscn")
const COMBAT_EFFECT := preload("res://scenes/combat_effect.tscn")
const COMBAT_POPUP := preload("res://scenes/combat_popup.tscn")
const HERO_WEAPON_EFFECTS := preload("res://assets/hero_weapon_effects_v1.png")
const THERMAL_AURA_TEXTURE := preload("res://assets/thermal_aura_yellow_orange_v1.png")
const LASER_BURN_FRAMES := [
	preload("res://assets/laser_burn_frame_1.png"),
	preload("res://assets/laser_burn_frame_2.png"),
	preload("res://assets/laser_burn_frame_3.png"),
]
const LASER_PULSE_FRAMES := [
	preload("res://assets/laser_pulse_frame_1.png"),
	preload("res://assets/laser_pulse_frame_2.png"),
	preload("res://assets/laser_pulse_frame_3.png"),
]
const PLANET_COUNT := 5
const WAVES_PER_PLANET := 6
const WAVE_DURATION := 60.0
const BASE_EXPERIENCE_TO_LEVEL := 25
const EXPERIENCE_PER_LEVEL := 12
const MAX_PLASMA_ROUNDS := 100
const MAX_HUNTER_MISSILES := 24
const MAX_ENEMY_ROCKETS := 150
const MAX_XP_ORBS := 180
const MAX_COMBAT_EFFECTS := 64
const MAX_COMBAT_POPUPS := 10
const TARGET_REFRESH_INTERVAL := 0.15
const ZONE_MUSIC_VOLUME_DB := -3.0
const ZONE_MUSIC_UPGRADE_VOLUME_DB := -9.0206

var mech_position := MAP_SIZE / 2.0
var tread_travel := 0.0
var small_spawn_time_left := 0.2
var medium_spawn_time_left := 0.6
var bomber_spawn_time_left := 1.0
var turret_spawn_time_left := 1.0
var mortar_spawn_time_left := 1.0
var large_spawn_time_left := 10.0
var boss: AlienBoss
var health_pack_spawn_time_left := 15.0
var health_packs_spawned_this_wave := 0
var health_pack_limit_this_wave := 1
var powerup_wave_key := -1
var powerup_due_this_wave := true
var waves_without_powerup := 0
var powerup_sequence := 0
var speed_boost_time_left := 0.0
var fire_rate_boost_time_left := 0.0
var mech_hit_flash_time := 0.0
var camera_shake_time_left := 0.0
var camera_shake_strength := 0.0
var planet_number := 1
var wave_number := 1
var wave_elapsed := 0.0
var last_wave_stage := 0
var move_speed := 72.0
var mech_max_health := 100.0
var mech_health := 100.0
var repair_per_second := 0.0
var armor_reduction := 0.0
var shield_max := 0.0
var shield_health := 0.0
var experience := 0
var level := 1
var experience_to_next_level := BASE_EXPERIENCE_TO_LEVEL
var shuriken_unlocked := false
var shuriken_level := 1
var shuriken_damage := 24
var shuriken_angle := 0.0
var shuriken_radius := 40.0
var shuriken_hit_time_left := 0.0
var shuriken_evolved := false
var weapon_visual_time := 0.0
var upgrade_open := false
var mech_destroyed := false
var manual_paused := false
var victory_open := false
var completed_planet := 0
var weapon_damage_totals := {
	"АВТОПУШКА": 0,
	"ОХОТНИЧЬИ РАКЕТЫ": 0,
	"ЛАЗЕР": 0,
	"СЮРИКЕНЫ": 0,
	"ТЕРМОБАРИЧЕСКИЙ НАГРЕВ": 0,
}
var available_upgrades: Array[Dictionary] = []
var plasma_round_pool: Array[PlasmaRound] = []
var hunter_missile_pool: Array[HunterMissile] = []
var enemy_rocket_pool: Array[EnemyRocket] = []
var xp_orb_pool: Array[XpOrb] = []
var combat_effect_pool: Array[CombatEffect] = []
var combat_popup_pool: Array[Node2D] = []
var nearest_target: AlienScout
var target_cache_time_left := 0.0
var xp_sound_time_left := 0.0

@onready var initial_scout: AlienScout = $Scout
@onready var camera: Camera2D = $Camera2D
@onready var mech_shadow: Node2D = $MechShadow
@onready var mech_sprite: Sprite2D = $MechSprite
@onready var autocannon: Autocannon = $Autocannon
@onready var hunter_launcher: HunterLauncher = $HunterLauncher
@onready var laser: LaserWeapon = $LaserWeapon
@onready var orbit_weapon: OrbitWeapon = $OrbitWeapon
@onready var zone_music: AudioStreamPlayer = $ZoneMusic
@onready var virtual_joystick: Control = $Hud/HudScale/VirtualJoystick


func _ready() -> void:
	get_viewport().size_changed.connect(_refresh_camera_layout)
	$Hud/HudScale/Minimap.configure($DesertBackground/Ground, MAP_SIZE)
	$Hud/HudScale/Minimap.set_player_position(mech_position)
	mech_shadow.global_position = mech_position + Vector2(0.0, 13.0)
	_warm_projectile_pools()
	planet_number = GameState.selected_planet
	if planet_number == 1:
		zone_music.process_mode = Node.PROCESS_MODE_ALWAYS
		zone_music.volume_db = ZONE_MUSIC_VOLUME_DB
		var desert_theme := zone_music.stream as AudioStreamWAV
		if desert_theme != null:
			desert_theme = desert_theme.duplicate() as AudioStreamWAV
			# Enabling looping alone can leave the imported loop range at 0..0.
			desert_theme.loop_begin = 0
			desert_theme.loop_end = roundi(desert_theme.get_length() * desert_theme.mix_rate)
			desert_theme.loop_mode = AudioStreamWAV.LOOP_FORWARD
			zone_music.stream = desert_theme
			zone_music.play()
	_update_wave_selector()
	initial_scout.global_position = _get_wave_spawn_position()
	_connect_scout(initial_scout)
	_update_experience_label()
	_update_health_label()
	_update_upgrade_list()
	_update_wave_hud()
	queue_redraw()


func _warm_projectile_pools() -> void:
	for index in range(24):
		_create_plasma_round()
	for index in range(8):
		_create_hunter_missile()
	for index in range(32):
		_create_enemy_rocket()
	for index in range(36):
		_create_xp_orb()
	for index in range(24):
		_create_combat_effect()
	for index in range(4):
		_create_combat_popup()


func _create_plasma_round() -> PlasmaRound:
	var round := PLASMA_ROUND.instantiate() as PlasmaRound
	$Projectiles.add_child(round)
	plasma_round_pool.append(round)
	return round


func acquire_plasma_round() -> PlasmaRound:
	for round in plasma_round_pool:
		if not round.active:
			return round
	if plasma_round_pool.size() >= MAX_PLASMA_ROUNDS:
		return null
	return _create_plasma_round()


func _create_hunter_missile() -> HunterMissile:
	var missile := HUNTER_MISSILE.instantiate() as HunterMissile
	$Projectiles.add_child(missile)
	hunter_missile_pool.append(missile)
	return missile


func acquire_hunter_missile() -> HunterMissile:
	for missile in hunter_missile_pool:
		if not missile.active:
			return missile
	if hunter_missile_pool.size() >= MAX_HUNTER_MISSILES:
		return null
	return _create_hunter_missile()


func _create_combat_effect() -> CombatEffect:
	var effect := COMBAT_EFFECT.instantiate() as CombatEffect
	add_child(effect)
	combat_effect_pool.append(effect)
	return effect


func _create_combat_popup() -> Node2D:
	var popup := COMBAT_POPUP.instantiate() as Node2D
	add_child(popup)
	combat_popup_pool.append(popup)
	return popup


func spawn_combat_popup(world_position: Vector2, message: String, text_color: Color) -> void:
	for popup in combat_popup_pool:
		if not bool(popup.get("active")):
			popup.call("activate", world_position, message, text_color)
			return
	if combat_popup_pool.size() < MAX_COMBAT_POPUPS:
		_create_combat_popup().call("activate", world_position, message, text_color)


func spawn_combat_effect(world_position: Vector2, effect_type: int, effect_scale: float = 1.0) -> void:
	var effect_activated := false
	for effect in combat_effect_pool:
		if not effect.active:
			effect.activate(world_position, effect_type, effect_scale)
			effect_activated = true
			break
	if not effect_activated and combat_effect_pool.size() < MAX_COMBAT_EFFECTS:
		_create_combat_effect().activate(world_position, effect_type, effect_scale)
	if effect_type == CombatEffect.Type.ROCKET_EXPLOSION:
		_start_camera_shake(1.2 * effect_scale)
	elif effect_type == CombatEffect.Type.PLAYER_IMPACT:
		_start_camera_shake(1.0)
	elif effect_type == CombatEffect.Type.PLASMA_IMPACT:
		_start_camera_shake(0.22)


func _create_enemy_rocket() -> EnemyRocket:
	var rocket := preload("res://scenes/enemy_rocket.tscn").instantiate() as EnemyRocket
	add_child(rocket)
	rocket.hit_player.connect(_take_damage)
	enemy_rocket_pool.append(rocket)
	return rocket


func acquire_enemy_rocket() -> EnemyRocket:
	if not _allow_enemy_projectile():
		return null
	for rocket in enemy_rocket_pool:
		if not rocket.active:
			rocket.player_position = mech_position
			return rocket
	if enemy_rocket_pool.size() >= MAX_ENEMY_ROCKETS:
		return null
	var rocket := _create_enemy_rocket()
	rocket.player_position = mech_position
	return rocket


func _allow_enemy_projectile() -> bool:
	var active_count := get_tree().get_nodes_in_group("enemy_hazards").size()
	for rocket in enemy_rocket_pool:
		if rocket.active:
			active_count += 1
	if active_count < 80:
		return true
	if active_count < 110:
		return randf() < 0.75
	return randf() < 0.45


func allow_enemy_hazard() -> bool:
	return _allow_enemy_projectile()


func _create_xp_orb() -> XpOrb:
	var orb := XP_ORB.instantiate() as XpOrb
	$Pickups.add_child(orb)
	orb.collected.connect(_collect_experience)
	xp_orb_pool.append(orb)
	return orb


func acquire_xp_orb() -> XpOrb:
	for orb in xp_orb_pool:
		if not orb.active:
			orb.player_position = mech_position
			return orb
	if xp_orb_pool.size() >= MAX_XP_ORBS:
		return null
	var orb := _create_xp_orb()
	orb.player_position = mech_position
	return orb


func _process(delta: float) -> void:
	$Hud/HudScale/Fps.text = "FPS %d" % Engine.get_frames_per_second()
	_update_camera_shake(delta)
	if manual_paused or upgrade_open or mech_destroyed or victory_open:
		_position_camera()
		return

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if bool(virtual_joystick.call("is_active")):
		movement = virtual_joystick.get("direction") as Vector2

	if movement.length() > 1.0:
		movement = movement.normalized()

	var active_move_speed := move_speed * (1.5 if speed_boost_time_left > 0.0 else 1.0)
	weapon_visual_time += delta
	xp_sound_time_left = maxf(xp_sound_time_left - delta, 0.0)
	var previous_mech_position := mech_position
	mech_position += movement * active_move_speed * delta
	mech_position.x = clampf(mech_position.x, 15.0, MAP_SIZE.x - 15.0)
	mech_position.y = clampf(mech_position.y, 15.0, MAP_SIZE.y - 15.0)
	tread_travel = fmod(tread_travel + mech_position.distance_to(previous_mech_position) / 8.0, 1000.0)
	(mech_sprite.material as ShaderMaterial).set_shader_parameter("travel", tread_travel)
	mech_sprite.global_position = mech_position
	mech_shadow.global_position = mech_position + Vector2(0.0, 13.0)
	# A tank chassis stays rigid: one frame is held while it travels smoothly.
	mech_sprite.scale = Vector2.ONE * 0.112
	mech_sprite.modulate = Color(1.0, 0.5, 0.5) if mech_hit_flash_time > 0.0 else Color.WHITE
	if movement.length() > 0.01:
		mech_sprite.frame = _get_mech_direction_frame(movement)
	mech_sprite.rotation = 0.0
	_position_camera()
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as AlienScout
		if enemy != null:
			enemy.target_position = mech_position
			_update_enemy_heat_visual(enemy)
			if enemy.global_position.distance_to(mech_position) < 24.0:
				_take_damage(enemy.contact_damage_per_second * delta)

	target_cache_time_left -= delta
	if target_cache_time_left <= 0.0 or not is_instance_valid(nearest_target):
		_refresh_nearest_target()

	_update_wave_progress(delta)
	_update_wave_spawns(delta)
	for rocket_node in get_tree().get_nodes_in_group("enemy_rockets"):
		var enemy_rocket := rocket_node as EnemyRocket
		if enemy_rocket != null and enemy_rocket.active:
			enemy_rocket.player_position = mech_position

	for orb_node in get_tree().get_nodes_in_group("xp_orbs"):
		var orb := orb_node as XpOrb
		if orb != null and orb.active:
			orb.player_position = mech_position

	for pack_node in get_tree().get_nodes_in_group("health_packs"):
		var health_pack := pack_node as HealthPack
		if health_pack != null:
			health_pack.player_position = mech_position

	if health_packs_spawned_this_wave < health_pack_limit_this_wave:
		health_pack_spawn_time_left -= delta
		if health_pack_spawn_time_left <= 0.0:
			_spawn_health_pack()
			health_packs_spawned_this_wave += 1
			health_pack_spawn_time_left = 25.0

	for powerup_node in get_tree().get_nodes_in_group("powerups"):
		var powerup := powerup_node as Powerup
		if powerup != null:
			powerup.player_position = mech_position
	_spawn_wave_powerup_if_needed()
	speed_boost_time_left = maxf(speed_boost_time_left - delta, 0.0)
	fire_rate_boost_time_left = maxf(fire_rate_boost_time_left - delta, 0.0)
	mech_hit_flash_time = maxf(mech_hit_flash_time - delta, 0.0)

	if repair_per_second > 0.0:
		mech_health = minf(mech_max_health, mech_health + repair_per_second * delta)
		_update_health_label()

	autocannon.tick(delta, mech_position, _get_nearest_enemy(), _get_fire_rate_multiplier())

	hunter_launcher.tick(delta, mech_position, _get_nearest_enemy(), _get_fire_rate_multiplier())

	laser.tick(delta, mech_position, _get_nearest_enemy(), _get_fire_rate_multiplier())

	orbit_weapon.tick(delta, mech_position, _get_fire_rate_multiplier())
	_sync_orbit_weapon()
	queue_redraw()


func _get_mech_direction_frame(direction: Vector2) -> int:
	# Sprite-sheet order: down, down-right, right, up-right / up, up-left, left, down-left.
	if absf(direction.x) < 0.38:
		return 0 if direction.y > 0.0 else 4
	if absf(direction.y) < 0.38:
		return 2 if direction.x > 0.0 else 6
	if direction.x > 0.0:
		return 1 if direction.y > 0.0 else 3
	return 7 if direction.y > 0.0 else 5


func _get_nearest_enemy() -> AlienScout:
	if is_instance_valid(nearest_target):
		return nearest_target
	_refresh_nearest_target()
	return nearest_target


func _refresh_nearest_target() -> void:
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
	nearest_target = nearest
	target_cache_time_left = TARGET_REFRESH_INTERVAL


func _on_autocannon_fired() -> void:
	$AudioFeedback.play_sound("cannon")


func _on_autocannon_projectile_requested(start_position: Vector2, target: AlienScout, damage: int, direction: Vector2, speed_multiplier: float, prime: bool, heavy: bool, pierce_limit: int) -> void:
	var round := acquire_plasma_round()
	if round != null:
		round.activate(start_position, target, damage, direction, speed_multiplier, prime, heavy, pierce_limit)


func _on_hunter_missile_requested(start_position: Vector2, target: AlienScout, damage: int, speed: float, explosion_radius: float, blast_count: int, blast_pause: float, arc_offset: float, style: String) -> void:
	var missile := acquire_hunter_missile()
	if missile == null:
		return
	missile.activate(start_position, target, damage, speed, explosion_radius, blast_count, blast_pause, arc_offset, style)


func _on_hunter_launcher_fired() -> void:
	$AudioFeedback.play_sound("missile")


func _on_laser_fired() -> void:
	$AudioFeedback.play_sound("laser")


func _on_laser_damage_requested(enemy: AlienScout, amount: int) -> void:
	_deal_weapon_damage(enemy, amount, "ЛАЗЕР")


func _deal_weapon_damage(enemy: AlienScout, amount: int, weapon_name: String, evolved_shot: bool = false) -> void:
	if not is_instance_valid(enemy) or enemy.health <= 0:
		return
	var actual_damage := mini(amount, enemy.health)
	weapon_damage_totals[weapon_name] = int(weapon_damage_totals.get(weapon_name, 0)) + actual_damage
	enemy.take_damage(amount, _death_effect_for_weapon(weapon_name, evolved_shot))


func _death_effect_for_weapon(weapon_name: String, evolved_shot: bool = false) -> int:
	# All rockets and final weapon evolutions get the large four-frame explosion.
	# Regular shots retain the lightweight blue energy fade.
	var final_orbit_weapon := (weapon_name == "СЮРИКЕНЫ" or weapon_name == "ТЕРМОБАРИЧЕСКИЙ НАГРЕВ") and orbit_weapon.level == 7
	var final_laser := weapon_name == "ЛАЗЕР" and laser.level == 7
	return CombatEffect.Type.ENEMY_DEATH if weapon_name == "ОХОТНИЧЬИ РАКЕТЫ" or evolved_shot or final_orbit_weapon or final_laser else CombatEffect.Type.ENEMY_DISSOLVE


func _get_shuriken_angles() -> Array[float]:
	return orbit_weapon.angles()


func _sync_orbit_weapon() -> void:
	shuriken_unlocked = orbit_weapon.unlocked
	shuriken_level = maxi(orbit_weapon.level, 1)
	shuriken_damage = orbit_weapon.damage()
	shuriken_radius = orbit_weapon.radius()
	shuriken_angle = orbit_weapon.angle
	shuriken_evolved = orbit_weapon.branch == "shuriken" and orbit_weapon.level == 7


func _update_enemy_heat_visual(enemy: AlienScout) -> void:
	var burning := orbit_weapon.unlocked and orbit_weapon.branch == "heat" and enemy.health > 0 and not enemy.is_queued_for_deletion()
	if burning:
		burning = mech_position.distance_squared_to(enemy.global_position) <= pow(orbit_weapon.radius(), 2)
	enemy.set_thermal_visual(burning, weapon_visual_time)


func _on_scout_health_changed(current_health: int, maximum_health: int) -> void:
	$Hud/HudScale/EnemyStatus.text = "РАЗВЕДЧИК: %d / %d HP" % [current_health, maximum_health]


func _on_scout_died(dead_scout: AlienScout) -> void:
	var orb := acquire_xp_orb()
	if orb != null:
		orb.activate(dead_scout.global_position, dead_scout.xp_tier, dead_scout.experience_amount)
	if dead_scout is AlienBoss:
		boss = null
		if wave_number == 6:
			_show_victory(planet_number)
			return
	$Hud/HudScale/EnemyStatus.text = "ОРБ ОПЫТА СБРОШЕН"


func _connect_scout(new_scout: AlienScout) -> void:
	new_scout.health_changed.connect(_on_scout_health_changed)
	new_scout.died.connect(_on_scout_died.bind(new_scout))


func _spawn_scout() -> void:
	var new_scout := SCOUT_SCENE.instantiate() as AlienScout
	add_child(new_scout)
	new_scout.global_position = _get_wave_spawn_position()
	_connect_scout(new_scout)
	$Hud/HudScale/EnemyStatus.text = "СИГНАЛ: РАЗВЕДЧИК ОБНАРУЖЕН"


func _spawn_brute() -> void:
	var new_brute := BRUTE_SCENE.instantiate() as AlienBrute
	add_child(new_brute)
	new_brute.global_position = _get_wave_spawn_position()
	_connect_scout(new_brute)
	$Hud/HudScale/EnemyStatus.text = "СИГНАЛ: БРОНИРОВАННЫЙ ПРИШЕЛЕЦ"


func _spawn_bomber() -> void:
	var bomber := BOMBER_SCENE.instantiate() as AlienBomber
	add_child(bomber)
	bomber.global_position = _get_wave_spawn_position()
	_connect_scout(bomber)
	$Hud/HudScale/EnemyStatus.text = "СИГНАЛ: КАМИКАДЗЕ"

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


func _count_mortars() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienMortar:
			count += 1
	return count


func _spawn_elite() -> void:
	var new_elite := ELITE_SCENE.instantiate() as AlienElite
	add_child(new_elite)
	new_elite.global_position = _get_wave_spawn_position()
	_connect_scout(new_elite)
	$Hud/HudScale/EnemyStatus.text = "СИГНАЛ: ЭЛИТНЫЙ РАКЕТНИК"


func _spawn_boss() -> void:
	if is_instance_valid(boss):
		return
	boss = BOSS_SCENE.instantiate() as AlienBoss
	add_child(boss)
	boss.global_position = _get_wave_spawn_position()
	_connect_scout(boss)
	$Hud/HudScale/EnemyStatus.text = "БОСС: ОСАДНЫЙ ХОДОК — ФАЗА 1"


func _debug_spawn_scout() -> void:
	_spawn_scout()


func _debug_spawn_brute() -> void:
	_spawn_brute()


func _debug_spawn_elite() -> void:
	_spawn_elite()


func _debug_spawn_boss() -> void:
	_spawn_boss()


func _debug_set_wave(target_wave: int) -> void:
	if planet_number != 1:
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		enemy_node.queue_free()
	for rocket_node in get_tree().get_nodes_in_group("enemy_rockets"):
		var rocket := rocket_node as EnemyRocket
		if rocket != null:
			rocket.deactivate()
	for hazard_node in get_tree().get_nodes_in_group("enemy_hazards"):
		hazard_node.queue_free()
	boss = null
	wave_number = clampi(target_wave, 1, WAVES_PER_PLANET)
	wave_elapsed = 0.0
	last_wave_stage = 0
	small_spawn_time_left = 0.0
	medium_spawn_time_left = 0.0
	large_spawn_time_left = 0.0
	bomber_spawn_time_left = 0.0
	turret_spawn_time_left = 0.0
	mortar_spawn_time_left = 0.0
	_prepare_wave_pickups()
	_update_wave_hud()


func _update_wave_selector() -> void:
	# The compact wave shortcuts are a level-one test aid, not part of later zones.
	var show_selector := planet_number == 1
	for target_wave in range(1, WAVES_PER_PLANET + 1):
		$Hud/HudScale.get_node("Wave%d" % target_wave).visible = show_selector
	$Hud/HudScale/DebugLevel.visible = show_selector


func _debug_level_up() -> void:
	if upgrade_open or mech_destroyed:
		return
	level += 1
	experience = 0
	experience_to_next_level = BASE_EXPERIENCE_TO_LEVEL + (level - 1) * EXPERIENCE_PER_LEVEL
	_update_experience_label()
	_open_upgrade_choice()


func _spawn_health_pack() -> void:
	var health_pack := HEALTH_PACK_SCENE.instantiate() as HealthPack
	$Pickups.add_child(health_pack)
	health_pack.global_position = _get_random_world_position(120.0)
	health_pack.collected.connect(_collect_health_pack)


func _collect_health_pack(heal_fraction: float) -> void:
	mech_health = minf(mech_max_health, mech_health + mech_max_health * heal_fraction)
	$Hud/HudScale/EnemyStatus.text = "АПТЕЧКА: +25% HP"
	spawn_combat_effect(mech_position, CombatEffect.Type.REPAIR)
	spawn_combat_popup(mech_position, "+25% HP", Color("78f7ad"))
	$AudioFeedback.play_sound("heal")
	_update_health_label()


func _collect_all_xp_orbs() -> void:
	for orb_node in get_tree().get_nodes_in_group("xp_orbs"):
		var orb := orb_node as XpOrb
		if orb != null and orb.active:
			orb.force_pull()


func _spawn_wave_powerup_if_needed() -> void:
	var current_wave_key := planet_number * 10 + wave_number
	if not powerup_due_this_wave or wave_elapsed < 12.0 or powerup_wave_key == current_wave_key:
		return
	var powerup := POWERUP_SCENE.instantiate() as Powerup
	$Pickups.add_child(powerup)
	powerup.global_position = _get_random_world_position(150.0)
	powerup.type = Powerup.Type.SPEED if powerup_sequence % 2 == 0 else Powerup.Type.FIRE_RATE
	powerup.collected.connect(_collect_powerup)
	powerup.queue_redraw()
	powerup_wave_key = current_wave_key
	powerup_sequence += 1


func _collect_powerup(powerup_type: int) -> void:
	if powerup_type == Powerup.Type.SPEED:
		speed_boost_time_left = 12.0
		$Hud/HudScale/EnemyStatus.text = "УСКОРЕНИЕ: +50% СКОРОСТИ"
		spawn_combat_effect(mech_position, CombatEffect.Type.SPEED_BOOST)
		spawn_combat_popup(mech_position, "СКОРОСТЬ +50%", Color("61d7ff"))
	else:
		fire_rate_boost_time_left = 12.0
		$Hud/HudScale/EnemyStatus.text = "ПЕРЕГРУЗКА: +45% СКОРОСТРЕЛЬНОСТИ"
		spawn_combat_effect(mech_position, CombatEffect.Type.FIRE_RATE_BOOST)
		spawn_combat_popup(mech_position, "ТЕМП +45%", Color("ffb45a"))
	$AudioFeedback.play_sound("boost")


func _get_fire_rate_multiplier() -> float:
	return 1.45 if fire_rate_boost_time_left > 0.0 else 1.0


func _prepare_wave_pickups() -> void:
	health_packs_spawned_this_wave = 0
	health_pack_limit_this_wave = 1 + (1 if randf() < 0.5 else 0)
	health_pack_spawn_time_left = 15.0
	if waves_without_powerup >= 1 or randf() < 0.5:
		powerup_due_this_wave = true
		waves_without_powerup = 0
	else:
		powerup_due_this_wave = false
		waves_without_powerup += 1


func _count_scouts() -> int:
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienScout and not (enemy_node is AlienBrute) and not (enemy_node is AlienElite) and not (enemy_node is AlienBoss) and not (enemy_node is AlienBomber) and not (enemy_node is AlienTurret) and not (enemy_node is AlienMortar):
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
			_update_wave_selector()
		last_wave_stage = 0
		_prepare_wave_pickups()
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
			small_spawn_time_left = _get_small_spawn_delay()

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
	if _count_mortars() < limits.get("mortar", 0):
		mortar_spawn_time_left -= delta
		if mortar_spawn_time_left <= 0.0:
			_spawn_mortar()
			mortar_spawn_time_left = 4.0

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
	var turret_enemies: Array[AlienTurret] = []
	var mortar_enemies: Array[AlienMortar] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is AlienMortar:
			mortar_enemies.append(enemy_node)
		elif enemy_node is AlienTurret:
			turret_enemies.append(enemy_node)
		elif enemy_node is AlienElite:
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
	for index in range(limits.get("turret", 0), turret_enemies.size()):
		turret_enemies[index].queue_free()
	for index in range(limits.get("mortar", 0), mortar_enemies.size()):
		mortar_enemies[index].queue_free()


func _get_small_spawn_delay() -> float:
	if wave_number == 5:
		return 1.0
	if wave_number == 4:
		return 0.85
	return 0.65


func _get_wave_limits() -> Dictionary:
	var second_stage_starts_at := 25.0 if wave_number == 1 else 30.0
	var stage := 2 if wave_elapsed >= second_stage_starts_at else 1
	if stage != last_wave_stage:
		last_wave_stage = stage
		small_spawn_time_left = minf(small_spawn_time_left, 0.2)
		medium_spawn_time_left = minf(medium_spawn_time_left, 0.4)
		large_spawn_time_left = minf(large_spawn_time_left, 0.5)
		$Hud/HudScale/EnemyStatus.text = "ВОЛНА %d — СТАДИЯ %d" % [wave_number, stage]

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
			return {"small": 5, "medium": 3, "large": 2, "bomber": 4, "turret": 1, "mortar": 1}
		return {"small": 6, "medium": 3, "large": 3, "bomber": 5, "turret": 2, "mortar": 2}
	if wave_number == 6:
		return {"small": 0, "medium": 0, "large": 0, "bomber": 0, "turret": 0, "mortar": 0}

	return {"small": 12, "medium": 7, "large": 3, "bomber": 5}


func _update_wave_hud() -> void:
	$Hud/HudScale/Zone.text = "ЗОНА %d" % planet_number
	$Hud/HudScale/Wave.text = "WAVE %d" % wave_number
	$Hud/HudScale/WaveTimer.text = "TIME %dс" % ceili(WAVE_DURATION - wave_elapsed)


func _collect_experience(amount: int) -> void:
	experience += amount
	if xp_sound_time_left <= 0.0:
		$AudioFeedback.play_sound("xp")
		xp_sound_time_left = 0.11
	if experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = BASE_EXPERIENCE_TO_LEVEL + (level - 1) * EXPERIENCE_PER_LEVEL
		_open_upgrade_choice()
	_update_experience_label()


func _update_experience_label() -> void:
	$Hud/HudScale/Level.text = "LV %d" % level
	$Hud/HudScale/ExperienceBar.max_value = experience_to_next_level
	$Hud/HudScale/ExperienceBar.value = experience
	$Hud/HudScale/ExperienceValue.text = "XP %d/%d" % [experience, experience_to_next_level]


func _open_upgrade_choice() -> void:
	$AudioFeedback.play_sound("level")
	upgrade_open = true
	_set_zone_music_upgrade_mix(true)
	get_tree().paused = true
	if autocannon.level == 1 and autocannon.branch.is_empty():
		available_upgrades = [_get_autocannon_upgrade(), _get_heavy_autocannon_upgrade(), _get_character_upgrade(), _get_character_upgrade()]
	elif hunter_launcher.unlocked and hunter_launcher.level == 1 and hunter_launcher.branch.is_empty():
		available_upgrades = [
			{"kind": "missile_branch_swarm", "title": hunter_launcher.next_upgrade_title("swarm")},
			{"kind": "missile_branch_siege", "title": hunter_launcher.next_upgrade_title("siege")},
			_get_character_upgrade(), _get_character_upgrade()
		]
	elif laser.unlocked and laser.level == 1 and laser.branch.is_empty():
		available_upgrades = [
			{"kind": "laser_branch_burn", "title": laser.next_upgrade_title("burn")},
			{"kind": "laser_branch_pulse", "title": laser.next_upgrade_title("pulse")},
			_get_character_upgrade(), _get_character_upgrade()
		]
	elif orbit_weapon.unlocked and orbit_weapon.level == 1:
		available_upgrades = [
			{"kind": "orbit_branch_shuriken", "title": orbit_weapon.next_upgrade_title("shuriken")},
			{"kind": "orbit_branch_heat", "title": orbit_weapon.next_upgrade_title("heat")},
			_get_character_upgrade(), _get_character_upgrade()
		]
	else:
		var first_weapon := _get_autocannon_upgrade() if autocannon.level < 7 else _get_weapon_upgrade()
		available_upgrades = [first_weapon, _get_weapon_upgrade(false), _get_character_upgrade(), _get_character_upgrade()]
	$Hud/HudScale/UpgradePanel.visible = true
	$Hud/HudScale/UpgradePanel/OptionA.text = available_upgrades[0].title
	$Hud/HudScale/UpgradePanel/OptionB.text = available_upgrades[1].title
	$Hud/HudScale/UpgradePanel/OptionC.text = available_upgrades[2].title
	$Hud/HudScale/UpgradePanel/OptionD.text = available_upgrades[3].title
	_update_upgrade_icons()


func _update_upgrade_icons() -> void:
	var icons := [
		$Hud/HudScale/UpgradePanel/IconA,
		$Hud/HudScale/UpgradePanel/IconB,
		$Hud/HudScale/UpgradePanel/IconC,
		$Hud/HudScale/UpgradePanel/IconD
	]
	for index in mini(icons.size(), available_upgrades.size()):
		icons[index].icon_index = _get_upgrade_icon_index(available_upgrades[index].kind)


func _get_upgrade_icon_index(kind: String) -> int:
	if kind == "autocannon_step" or kind == "heavy_autocannon_step":
		return UpgradeIcon.PLASMA_CANNON_ICON
	if kind == "unlock_missile" or kind == "missile_branch_swarm" or kind == "missile_branch_siege" or kind == "missile_step":
		return UpgradeIcon.MISSILE_ICON
	if kind == "unlock_laser" or kind == "laser_branch_burn" or kind == "laser_branch_pulse" or kind == "laser_step":
		return UpgradeIcon.LASER_ICON
	if kind == "unlock_shuriken" or kind == "orbit_branch_shuriken" or kind == "orbit_branch_heat" or kind == "orbit_step":
		return UpgradeIcon.SHURIKEN_ICON
	if kind == "max_health":
		return UpgradeIcon.HEALTH_ICON
	if kind == "repair":
		return UpgradeIcon.REPAIR_ICON
	if kind == "speed":
		return UpgradeIcon.SPEED_ICON
	if kind == "armor":
		return UpgradeIcon.ARMOR_ICON
	if kind == "shield":
		return UpgradeIcon.SHIELD_ICON
	if kind == "magnet":
		return UpgradeIcon.MAGNET_ICON
	return UpgradeIcon.HEALTH_ICON


func _get_weapon_upgrade(include_autocannon: bool = true) -> Dictionary:
	var choices: Array[Dictionary] = []
	if include_autocannon and autocannon.level < 7:
		choices.append(_get_autocannon_upgrade())
	if not hunter_launcher.unlocked and level >= 3:
		choices.append({"kind": "unlock_missile", "title": "НОВОЕ ОРУЖИЕ: ОХОТНИЧЬИ РАКЕТЫ"})
	elif hunter_launcher.unlocked and hunter_launcher.level >= 2 and hunter_launcher.level < 7:
		choices.append({"kind": "missile_step", "title": hunter_launcher.next_upgrade_title()})
	if not laser.unlocked and level >= 4:
		choices.append({"kind": "unlock_laser", "title": "НОВОЕ ОРУЖИЕ: ЛАЗЕР"})
	elif laser.unlocked and laser.level >= 2 and laser.level < 7:
		choices.append({"kind": "laser_step", "title": laser.next_upgrade_title()})
	if not shuriken_unlocked and level >= 5:
		choices.append({"kind": "unlock_shuriken", "title": "НОВОЕ ОРУЖИЕ: СЮРИКЕНЫ"})
	elif orbit_weapon.unlocked and orbit_weapon.level >= 2 and orbit_weapon.level < 7:
		choices.append({"kind": "orbit_step", "title": orbit_weapon.next_upgrade_title()})
	if choices.is_empty():
		return _get_autocannon_upgrade() if autocannon.level < 7 else _get_character_upgrade()
	return choices.pick_random()


func _get_autocannon_upgrade() -> Dictionary:
	if autocannon.branch == "heavy":
		return _get_heavy_autocannon_upgrade()
	return {"kind": "autocannon_step", "title": autocannon.next_upgrade_title("fan")}


func _get_heavy_autocannon_upgrade() -> Dictionary:
	return {"kind": "heavy_autocannon_step", "title": autocannon.next_upgrade_title("heavy")}


func _get_character_upgrade() -> Dictionary:
	var choices: Array[Dictionary] = [
		{"kind": "max_health", "title": "КОРПУС: +20 максимального HP"},
		{"kind": "repair", "title": "РЕМОНТ: +1 HP в секунду"},
		{"kind": "speed", "title": "ДВИГАТЕЛИ: +10% скорости"},
		{"kind": "armor", "title": "БРОНЯ: -10% входящего урона"},
		{"kind": "shield", "title": "ЩИТ: +25 поглощения урона"},
		{"kind": "magnet", "title": "МАГНИТ: притянуть весь опыт"}
	]
	return choices.pick_random()


func _choose_upgrade(index: int) -> void:
	var choice := available_upgrades[index]
	match choice.kind:
		"autocannon_step":
			if autocannon.apply_upgrade("fan"):
				$Hud/HudScale/EnemyStatus.text = "ПЛАЗМОТРОН ПРАЙМ" if autocannon.prime else "АВТОПУШКА УР. %d" % autocannon.level
		"heavy_autocannon_step":
			if autocannon.apply_upgrade("heavy"):
				$Hud/HudScale/EnemyStatus.text = "DESERT EAGLE" if autocannon.level == 7 else "ТЯЖЁЛАЯ ПУШКА УР. %d" % autocannon.level
		"unlock_missile":
			hunter_launcher.unlock()
			$Hud/HudScale/EnemyStatus.text = "ОРУЖИЕ ПОЛУЧЕНО: ОХОТНИЧЬИ РАКЕТЫ"
		"missile_branch_swarm":
			if hunter_launcher.choose_branch("swarm"):
				$Hud/HudScale/EnemyStatus.text = "РАКЕТНЫЙ РОЙ УР. 2"
		"missile_branch_siege":
			if hunter_launcher.choose_branch("siege"):
				$Hud/HudScale/EnemyStatus.text = "ОСАДНАЯ РАКЕТА УР. 2"
		"missile_step":
			if hunter_launcher.upgrade():
				if hunter_launcher.level == 7:
					$Hud/HudScale/EnemyStatus.text = "ЖЁЛТАЯ БУРЯ" if hunter_launcher.branch == "swarm" else "ТРОЙНОЙ УДАР"
				else:
					$Hud/HudScale/EnemyStatus.text = "РАКЕТЫ УР. %d" % hunter_launcher.level
		"unlock_laser":
			laser.unlock()
			$Hud/HudScale/EnemyStatus.text = "ОРУЖИЕ ПОЛУЧЕНО: ЛАЗЕР"
		"laser_branch_burn":
			if laser.choose_branch("burn"):
				$Hud/HudScale/EnemyStatus.text = "ПРОЖИГАЮЩИЙ ЛУЧ УР. 2"
		"laser_branch_pulse":
			if laser.choose_branch("pulse"):
				$Hud/HudScale/EnemyStatus.text = "ИМПУЛЬСНЫЙ ЛУЧ УР. 2"
		"laser_step":
			if laser.upgrade():
				if laser.level == 7:
					$Hud/HudScale/EnemyStatus.text = "СОЛНЕЧНОЕ ЖАЛО" if laser.branch == "burn" else "СОЛНЕЧНЫЙ ИМПУЛЬС"
				else:
					$Hud/HudScale/EnemyStatus.text = "ЛАЗЕР УР. %d" % laser.level
		"unlock_shuriken":
			orbit_weapon.unlock()
		"orbit_branch_shuriken":
			orbit_weapon.choose_branch("shuriken")
		"orbit_branch_heat":
			orbit_weapon.choose_branch("heat")
		"orbit_step":
			orbit_weapon.upgrade()
		"max_health":
			mech_max_health += 20
			mech_health += 20
		"repair":
			repair_per_second += 1.0
		"speed":
			move_speed *= 1.1
		"armor":
			armor_reduction = minf(armor_reduction + 0.1, 0.5)
		"shield":
			shield_max += 25.0
			shield_health += 25.0
		"magnet":
			_collect_all_xp_orbs()
	_sync_orbit_weapon()
	$Hud/HudScale/UpgradePanel.visible = false
	upgrade_open = false
	_set_zone_music_upgrade_mix(false)
	get_tree().paused = false
	_update_health_label()
	_update_upgrade_list()


func _set_zone_music_upgrade_mix(upgrade_menu_visible: bool) -> void:
	if planet_number == 1:
		zone_music.volume_db = ZONE_MUSIC_UPGRADE_VOLUME_DB if upgrade_menu_visible else ZONE_MUSIC_VOLUME_DB


func _take_damage(amount: float) -> void:
	mech_hit_flash_time = 0.12
	if amount >= 2.0:
		_start_camera_shake(0.75)
		$AudioFeedback.play_sound("hurt")
	var remaining_damage := amount * (1.0 - armor_reduction)
	if shield_health > 0.0:
		var absorbed := minf(shield_health, remaining_damage)
		shield_health -= absorbed
		remaining_damage -= absorbed
	mech_health = maxf(mech_health - remaining_damage, 0.0)
	_update_health_label()
	if mech_health <= 0.0:
		mech_destroyed = true
		get_tree().paused = true
		$Hud/HudScale/GameOver.visible = true


func _start_camera_shake(strength: float) -> void:
	camera_shake_time_left = maxf(camera_shake_time_left, 0.11)
	camera_shake_strength = minf(maxf(camera_shake_strength, strength), 2.2)


func _update_camera_shake(delta: float) -> void:
	camera_shake_time_left = maxf(camera_shake_time_left - delta, 0.0)
	if camera_shake_time_left <= 0.0:
		camera_shake_strength = 0.0


func _position_camera() -> void:
	$Hud/HudScale/Minimap.set_player_position(mech_position)
	var offset := Vector2.ZERO
	if camera_shake_time_left > 0.0:
		var fade := camera_shake_time_left / 0.11
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * camera_shake_strength * fade
	camera.global_position = mech_position + offset


func _refresh_camera_layout() -> void:
	# Camera2D normally updates during processing, which stops on the upgrade screen.
	# Force a fresh viewport transform even when the game is paused/resized.
	camera.force_update_scroll.call_deferred()


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	_hide_pause_options()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_victory(finished_planet: int) -> void:
	victory_open = true
	completed_planet = finished_planet
	var next_planet := mini(finished_planet + 1, PLANET_COUNT)
	if next_planet > finished_planet:
		GameState.unlock_planet(next_planet)
	var best_weapon := "АВТОПУШКА"
	var best_damage := -1
	for weapon_name in weapon_damage_totals:
		var total := int(weapon_damage_totals[weapon_name])
		if total > best_damage:
			best_weapon = weapon_name
			best_damage = total
	$Hud/HudScale/BattleSummary/BestWeapon.text = "ЛИДЕР: %s — %d УРОНА" % [best_weapon, best_damage]
	$Hud/HudScale/BattleSummary/Autocannon.text = "АВТОПУШКА        %d" % int(weapon_damage_totals["АВТОПУШКА"])
	$Hud/HudScale/BattleSummary/Missiles.text = "ОХОТНИЧЬИ РАКЕТЫ  %d" % int(weapon_damage_totals["ОХОТНИЧЬИ РАКЕТЫ"])
	$Hud/HudScale/BattleSummary/Laser.text = "ЛАЗЕР             %d" % int(weapon_damage_totals["ЛАЗЕР"])
	$Hud/HudScale/BattleSummary/Shurikens.text = "НАГРЕВ            %d" % int(weapon_damage_totals["ТЕРМОБАРИЧЕСКИЙ НАГРЕВ"]) if orbit_weapon.branch == "heat" else "СЮРИКЕНЫ          %d" % int(weapon_damage_totals["СЮРИКЕНЫ"])
	$Hud/HudScale/BattleSummary/NextZone.text = "ПЕРЕЙТИ В ЗОНУ %d" % next_planet if finished_planet < PLANET_COUNT else "В ГЛАВНОЕ МЕНЮ"
	$Hud/HudScale/Victory.visible = true
	$Hud/HudScale/EnemyStatus.text = "ЗОНА %d ПРОЙДЕНА" % finished_planet
	get_tree().paused = true


func _continue_after_victory() -> void:
	get_tree().paused = false
	if completed_planet < PLANET_COUNT:
		GameState.select_planet(completed_planet + 1)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_battle_summary() -> void:
	$Hud/HudScale/Victory.visible = false
	$Hud/HudScale/BattleSummary.visible = true


func _hide_battle_summary() -> void:
	$Hud/HudScale/BattleSummary.visible = false
	$Hud/HudScale/Victory.visible = true


func _toggle_pause() -> void:
	manual_paused = not manual_paused
	if manual_paused:
		_hide_pause_options()
	$Hud/HudScale/PausePanel.visible = manual_paused
	get_tree().paused = manual_paused


func _resume_game() -> void:
	if manual_paused:
		_hide_pause_options()
		_toggle_pause()


func _show_pause_options() -> void:
	var pause_panel := $Hud/HudScale/PausePanel
	pause_panel.get_node("Title").visible = false
	pause_panel.get_node("Hint").visible = false
	pause_panel.get_node("Resume").visible = false
	pause_panel.get_node("Options").visible = false
	pause_panel.get_node("Menu").visible = false
	var options := pause_panel.get_node("OptionsPanel")
	options.visible = true
	var settings := _get_settings()
	if settings != null:
		var volume := float(settings.get("master_volume"))
		options.get_node("Volume").value = volume * 100.0
		options.get_node("VolumeValue").text = "%d%%" % roundi(volume * 100.0)
		options.get_node("Fullscreen").set_pressed_no_signal(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])


func _hide_pause_options() -> void:
	if not has_node("Hud/HudScale/PausePanel/OptionsPanel"):
		return
	var pause_panel := $Hud/HudScale/PausePanel
	pause_panel.get_node("OptionsPanel").visible = false
	for node_name in ["Title", "Hint", "Resume", "Options", "Menu"]:
		pause_panel.get_node(node_name).visible = true


func _set_pause_volume(value: float) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_master_volume", value / 100.0)
	$Hud/HudScale/PausePanel/OptionsPanel/VolumeValue.text = "%d%%" % roundi(value)


func _set_pause_fullscreen(enabled: bool) -> void:
	var settings := _get_settings()
	if settings != null:
		settings.call("set_fullscreen", enabled)


func _get_settings() -> Node:
	# Looking up the optional autoload at runtime keeps the game compilable even
	# while Godot is refreshing project settings after a Git update.
	return get_node_or_null("/root/Settings")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not upgrade_open and not mech_destroyed:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _update_health_label() -> void:
	$Hud/HudScale/HealthBar.max_value = mech_max_health
	$Hud/HudScale/HealthBar.value = mech_health
	$Hud/HudScale/HealthValue.text = "HP %d" % ceili(mech_health)
	$Hud/HudScale/ShieldValue.text = "ЩИТ %d/%d" % [ceili(shield_health), ceili(shield_max)]


func _update_upgrade_list() -> void:
	var weapon_line := "ТЯЖ. ПУШКА %d" % autocannon.level if autocannon.branch == "heavy" else "ПУШКА %d" % autocannon.level
	if hunter_launcher.unlocked:
		var launcher_name := "РОЙ" if hunter_launcher.branch == "swarm" else "ОСАДА" if hunter_launcher.branch == "siege" else "РАКЕТЫ"
		weapon_line += " | %s %d" % [launcher_name, hunter_launcher.level]
	if laser.unlocked:
		var laser_name := "ПРОЖИГ" if laser.branch == "burn" else "ИМПУЛЬС" if laser.branch == "pulse" else "ЛАЗЕР"
		weapon_line += " | %s %d" % [laser_name, laser.level]
	if shuriken_unlocked:
		weapon_line += " | %s %d" % ["НАГРЕВ" if orbit_weapon.branch == "heat" else "СЮРИКЕНЫ", shuriken_level]
	var mech_line := "БР%d%% • Щ%d" % [roundi(armor_reduction * 100.0), ceili(shield_max)]
	if repair_per_second > 0.0:
		mech_line += " • РЕМ%d" % roundi(repair_per_second)
	$Hud/HudScale/UpgradeList.text = weapon_line + " • " + mech_line


func _draw() -> void:
	if laser.branch == "pulse" and laser.beam_time_left > 0.0:
		var pulse_width := laser.current_stats().beam_width
		var pulse_direction := laser.beam_end - laser.beam_start
		var pulse_frame := laser.pulse_visual_frame()
		var frame_texture: Texture2D = LASER_PULSE_FRAMES[pulse_frame]
		var frame_alpha := 1.0
		if pulse_frame == 2:
			frame_alpha = clampf(laser.beam_time_left / (LaserWeapon.PULSE_VISUAL_TIME / 3.0), 0.0, 1.0)
		var frame_spark_size: float = [14.0, 25.0, 11.0][pulse_frame]
		if laser.level == 7:
			draw_line(laser.beam_start, laser.beam_end, Color(1.0, 0.38, 0.08, 0.2 * frame_alpha), pulse_width * 1.6)
		draw_set_transform(laser.beam_start, pulse_direction.angle())
		draw_texture_rect(frame_texture, Rect2(0.0, -pulse_width * 4.0, pulse_direction.length(), pulse_width * 8.0), false, Color(1.0, 1.0, 1.0, frame_alpha))
		draw_set_transform(Vector2.ZERO, 0.0)
		_draw_hero_weapon_effect(0, laser.beam_start, Vector2(20, 14), pulse_direction.angle())
		_draw_hero_weapon_effect(1, laser.beam_end, Vector2.ONE * frame_spark_size, 0.0)
	elif laser.beam_active and is_instance_valid(laser.current_target):
		var beam_direction := laser.current_target.global_position - mech_position
		var burn_width := laser.current_stats().beam_width * (1.0 + sin(weapon_visual_time * 22.0) * 0.06)
		if laser.branch == "burn":
			burn_width *= 1.2
			var burn_alpha := 0.92 + sin(weapon_visual_time * 18.0) * 0.08
			var burn_texture: Texture2D = LASER_BURN_FRAMES[laser.burn_visual_frame()]
			draw_set_transform(mech_position, beam_direction.angle())
			draw_texture_rect(burn_texture, Rect2(0.0, -burn_width * 4.0, beam_direction.length(), burn_width * 8.0), false, Color(1.0, 1.0, 1.0, burn_alpha))
			draw_set_transform(Vector2.ZERO, 0.0)
		else:
			draw_line(mech_position, laser.current_target.global_position, Color(0.08, 0.75, 1.0, 0.17), burn_width * 2.1)
			draw_line(mech_position, laser.current_target.global_position, Color("41cfff"), burn_width)
			draw_line(mech_position, laser.current_target.global_position, Color("e7fbff"), 1.0)
		var impact_pulse := 3.0 + sin(weapon_visual_time * 20.0) * 1.2
		draw_arc(laser.current_target.global_position, laser.current_target.hit_radius + impact_pulse, 0.0, TAU, 20, Color(0.37, 0.9, 1.0, 0.7), 1.5)
		_draw_hero_weapon_effect(0, mech_position, Vector2(20, 14), beam_direction.angle())
		_draw_hero_weapon_effect(1, laser.current_target.global_position, Vector2(17, 17), 0.0)
	if orbit_weapon.unlocked and orbit_weapon.branch == "heat":
		_draw_thermal_aura()
	elif shuriken_unlocked:
		for angle_offset in _get_shuriken_angles():
			var shuriken_position := mech_position + Vector2(cos(shuriken_angle + angle_offset), sin(shuriken_angle + angle_offset)) * shuriken_radius
			var shuriken_column := 3 if shuriken_evolved else 2
			var shuriken_size := Vector2(25, 25) if shuriken_evolved else Vector2(19, 19)
			_draw_hero_weapon_effect(shuriken_column, shuriken_position, shuriken_size, shuriken_angle + angle_offset)


func _draw_thermal_aura() -> void:
	var radius := orbit_weapon.radius()
	var pulse := 0.5 + 0.5 * sin(weapon_visual_time * 3.5)
	# A shared transparent texture stays readable against the desert and rotates
	# slowly, without adding particles or extra scene nodes.
	var texture_size := Vector2.ONE * radius * 2.25
	draw_set_transform(mech_position, weapon_visual_time * 0.18)
	draw_texture_rect(
		THERMAL_AURA_TEXTURE,
		Rect2(-texture_size * 0.5, texture_size),
		false,
		Color(1.0, 1.0, 1.0, 0.30 + pulse * 0.06)
	)
	draw_set_transform(Vector2.ZERO, 0.0)
	if orbit_weapon.wave_visual_time > 0.0:
		var progress := 1.0 - orbit_weapon.wave_visual_time / OrbitWeapon.WAVE_VISUAL_DURATION
		var wave_size := lerpf(8.0, orbit_weapon.wave_radius, progress)
		var opacity := (1.0 - progress) * 0.55
		draw_arc(orbit_weapon.wave_origin, wave_size, 0.0, TAU, 64, Color(1.0, 0.65, 0.24, opacity), 2.0, true)
		draw_arc(orbit_weapon.wave_origin, maxf(wave_size - 3.0, 1.0), 0.0, TAU, 64, Color(1.0, 0.28, 0.06, opacity * 0.3), 3.0, true)


func _draw_hero_weapon_effect(column: int, position: Vector2, size: Vector2, effect_rotation: float) -> void:
	var frame := int(weapon_visual_time * 12.0) % 2
	var cell := Vector2(HERO_WEAPON_EFFECTS.get_width() / 4.0, HERO_WEAPON_EFFECTS.get_height() / 2.0)
	var source := Rect2(Vector2(column * cell.x, frame * cell.y), cell)
	draw_set_transform(position, effect_rotation)
	draw_texture_rect_region(HERO_WEAPON_EFFECTS, Rect2(-size * 0.5, size), source)
	draw_set_transform(Vector2.ZERO, 0.0)


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
