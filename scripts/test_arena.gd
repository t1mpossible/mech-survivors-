extends "res://scripts/main.gd"

const WEAPON_PICKUP := preload("res://scripts/weapon_test_pickup.gd")
const WEAPON_NAMES := {
	"fan": "Автопушка: веер", "heavy": "Тяжёлая пушка",
	"swarm": "Ракетный рой", "siege": "Осадная ракета",
	"burn": "Прожигающий луч", "pulse": "Импульсный луч", "shuriken": "Сюрикены", "heat": "Термобарический нагрев",
}
const RESPAWN_DELAY := 2.0
const DPS_WINDOW := 5.0

var training_slots: Array[Dictionary] = []
var weapon_stands: Array[Node2D] = []
var selected_weapon := ""
var test_weapon_level := 1
var training_damage := 0
var level_down: Button
var level_up: Button
var training_stats: Label
var dps_bar: ProgressBar
var dps_label: Label
var dps_clock := 0.0
var current_dps := 0.0
var dps_window_damage := 0
var dps_hits: Array[Vector2] = []


func _ready() -> void:
	super._ready()
	planet_number = 1
	move_speed *= 2.0
	health_pack_limit_this_wave = 0
	initial_scout.remove_from_group("enemies")
	initial_scout.queue_free()
	mech_position = Vector2(800, 680)
	mech_sprite.global_position = mech_position
	for node_name in ["Wave1", "Wave2", "Wave3", "Wave4", "Wave5", "Wave6", "DebugLevel", "Level", "ExperienceBar", "ExperienceValue", "EnemyStatus"]:
		get_node("Hud/" + node_name).hide()
	_create_training_controls()
	var scenes: Array[PackedScene] = [SCOUT_SCENE, BRUTE_SCENE, ELITE_SCENE, BOMBER_SCENE, TURRET_SCENE, MORTAR_SCENE, MORTAR_SCENE, BOSS_SCENE]
	var names := ["Разведчик", "Бронированный", "Элитный", "Ходячая мина", "Турель", "Миномётчик", "Малый миномётчик", "Босс"]
	for index in range(scenes.size()):
		var location := Vector2(240 + index * 160, 350)
		training_slots.append({"scene": scenes[index], "position": location, "split_child": index == 6, "enemy": null, "respawn_left": 0.0})
		_spawn_training_enemy(index)
		var label := Label.new()
		label.text = names[index]
		label.position = location + Vector2(-75, 70)
		label.size.x = 150
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		add_child(label)
	var index := 0
	for key in WEAPON_NAMES:
		var stand := Node2D.new()
		stand.set_script(WEAPON_PICKUP)
		stand.weapon_key = key
		stand.display_name = "Термобарический\nнагрев" if key == "heat" else WEAPON_NAMES[key]
		stand.position = Vector2(310 + index * 140, 600)
		stand.player_position = mech_position
		stand.tint = Color("ff9b4a") if key == "heat" else Color("ffc762") if key in ["fan", "swarm"] else Color("88dfff") if key in ["burn", "pulse"] else Color("eaaaef")
		stand.selected.connect(_equip_test_weapon)
		add_child(stand)
		weapon_stands.append(stand)
		index += 1
	_equip_test_weapon("")
	_update_wave_hud()
	_position_camera()


func _process(delta: float) -> void:
	if not manual_paused and not upgrade_open and not mech_destroyed and not victory_open:
		dps_clock += delta
	super._process(delta)
	if manual_paused or upgrade_open or mech_destroyed or victory_open:
		return
	_update_training_dps()
	_update_training_respawns(delta)
	for stand in weapon_stands:
		stand.player_position = mech_position
	for slot in training_slots:
		var enemy := slot.enemy as AlienScout
		if is_instance_valid(enemy):
			enemy.damage_flash_time = maxf(enemy.damage_flash_time - delta, 0.0)
			enemy.modulate = Color(1.0, 0.55, 0.55) if enemy.damage_flash_time > 0.0 else Color.WHITE
			enemy.queue_redraw()


func _spawn_training_enemy(index: int) -> void:
	var slot := training_slots[index]
	var enemy := (slot.scene as PackedScene).instantiate() as AlienScout
	enemy.training_dummy = true
	if enemy is AlienMortar:
		enemy.split_child = slot.split_child
	enemy.position = slot.position
	add_child(enemy)
	enemy.set_process(false)
	enemy.movement_speed = 0.0
	enemy.contact_damage_per_second = 0.0
	enemy.target_position = mech_position
	enemy.died.connect(_training_enemy_died.bind(index))
	slot.enemy = enemy
	slot.respawn_left = 0.0


func _training_enemy_died(index: int) -> void:
	# Remove immediately from target searches; the death animation can finish normally.
	var enemy := training_slots[index].enemy as AlienScout
	if is_instance_valid(enemy):
		enemy.remove_from_group("enemies")
	training_slots[index].enemy = null
	training_slots[index].respawn_left = RESPAWN_DELAY
	nearest_target = null


func _update_training_respawns(delta: float) -> void:
	for index in range(training_slots.size()):
		var slot := training_slots[index]
		if slot.enemy == null:
			slot.respawn_left = maxf(float(slot.respawn_left) - delta, 0.0)
			if slot.respawn_left <= 0.0:
				_spawn_training_enemy(index)


func _create_training_controls() -> void:
	level_down = _training_button("−", Vector2(6, 60), Vector2(16, 8))
	level_down.pressed.connect(_change_test_level.bind(-1))
	level_up = _training_button("+", Vector2(25, 60), Vector2(16, 8))
	level_up.pressed.connect(_change_test_level.bind(1))
	var clear_button := _training_button("Без оружия", Vector2(44, 60), Vector2(37, 8))
	clear_button.pressed.connect(_equip_test_weapon.bind(""))
	training_stats = Label.new()
	training_stats.position = Vector2(6, 71)
	training_stats.add_theme_font_size_override("font_size", 7)
	$Hud.add_child(training_stats)
	dps_label = Label.new()
	dps_label.name = "TrainingDpsLabel"
	dps_label.position = Vector2(6, 84)
	dps_label.add_theme_font_size_override("font_size", 6)
	dps_label.add_theme_color_override("font_color", Color("88dfff"))
	dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(dps_label)
	dps_bar = ProgressBar.new()
	dps_bar.name = "TrainingDpsBar"
	dps_bar.position = Vector2(6, 94)
	dps_bar.size = Vector2(100, 4)
	dps_bar.show_percentage = false
	dps_bar.max_value = 100.0
	dps_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.07, 0.1, 0.85)
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("63d5f0")
	fill.set_corner_radius_all(2)
	dps_bar.add_theme_stylebox_override("background", background)
	dps_bar.add_theme_stylebox_override("fill", fill)
	$Hud.add_child(dps_bar)
	dps_bar.set_deferred("size", Vector2(100, 4))


func _training_button(caption: String, location: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = location
	button.add_theme_font_size_override("font_size", 5)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.07, 0.1, 0.8)
	style.set_corner_radius_all(2)
	style.content_margin_left = 1.0
	style.content_margin_right = 1.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.07, 0.22, 0.28, 0.95)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", style)
	button.size = dimensions
	$Hud.add_child(button)
	# The inherited theme recomputes its minimum size after entering the tree.
	button.set_deferred("size", dimensions)
	return button


func _change_test_level(amount: int) -> void:
	test_weapon_level = clampi(test_weapon_level + amount, 1, 7)
	_equip_test_weapon(selected_weapon)


func _equip_test_weapon(key: String) -> void:
	selected_weapon = key
	for round in plasma_round_pool:
		round.deactivate()
	for missile in hunter_missile_pool:
		missile.deactivate()
	autocannon.enabled = false
	autocannon.level = 1
	autocannon.branch = ""
	autocannon.damage = autocannon.base_damage
	autocannon.shot_interval = autocannon.base_shot_interval
	autocannon.projectile_count = 1
	autocannon.projectile_speed_multiplier = 1.0
	autocannon.pierce_limit = 1
	autocannon.prime = false
	autocannon.time_to_shot = 0.0
	autocannon.burst_shots_left = 0
	autocannon.burst_time_to_shot = 0.0
	hunter_launcher.unlocked = false
	hunter_launcher.level = 0
	hunter_launcher.branch = ""
	laser.unlocked = false
	laser.level = 0
	laser.branch = ""
	laser.beam_active = false
	laser.current_target = null
	laser.beam_time_left = 0.0
	laser.cooldown_time_left = 0.0
	laser.active_time_left = 0.0
	shuriken_unlocked = false
	shuriken_angle = 0.0
	shuriken_hit_time_left = 0.0
	orbit_weapon.reset()
	match key:
		"fan", "heavy":
			autocannon.enabled = true
			for upgrade_index in range(test_weapon_level - 1):
				autocannon.apply_upgrade(key)
		"swarm", "siege":
			hunter_launcher.unlock()
			if test_weapon_level >= 2:
				hunter_launcher.choose_branch(key)
			for upgrade_index in range(2, test_weapon_level):
				hunter_launcher.upgrade()
		"burn", "pulse":
			laser.unlock()
			if test_weapon_level >= 2:
				laser.choose_branch(key)
			for upgrade_index in range(2, test_weapon_level):
				laser.upgrade()
		"shuriken", "heat":
			orbit_weapon.unlock()
			if test_weapon_level >= 2:
				orbit_weapon.choose_branch(key)
			for upgrade_index in range(2, test_weapon_level):
				orbit_weapon.upgrade()
	_sync_orbit_weapon()
	for node in get_tree().get_nodes_in_group("enemies"):
		_update_enemy_heat_visual(node as AlienScout)
	for stand in weapon_stands:
		stand.equipped = stand.weapon_key == key
	training_damage = 0
	dps_clock = 0.0
	dps_window_damage = 0
	dps_hits.clear()
	current_dps = 0.0
	dps_bar.max_value = 100.0
	_update_training_dps()
	for weapon_name in weapon_damage_totals:
		weapon_damage_totals[weapon_name] = 0
	_update_upgrade_list()
	queue_redraw()


func _deal_weapon_damage(enemy: AlienScout, amount: int, weapon_name: String) -> void:
	if is_instance_valid(enemy) and enemy.health > 0:
		var actual_damage := mini(amount, enemy.health)
		training_damage += actual_damage
		dps_window_damage += actual_damage
		dps_hits.append(Vector2(dps_clock, actual_damage))
	super._deal_weapon_damage(enemy, amount, weapon_name)
	_update_training_dps()
	_update_upgrade_list()


func _update_training_dps() -> void:
	# Fixed five-second window smooths bursts and includes reloads and idle time.
	# The clock advances only during gameplay; pausing cannot dilute the result.
	while not dps_hits.is_empty() and dps_hits[0].x <= dps_clock - DPS_WINDOW:
		dps_window_damage -= int(dps_hits.pop_front().y)
	current_dps = float(dps_window_damage) / DPS_WINDOW
	if not is_instance_valid(dps_bar):
		return
	dps_bar.max_value = maxf(dps_bar.max_value, ceilf(current_dps / 100.0) * 100.0)
	dps_bar.value = current_dps
	dps_label.text = "DPS %.1f • 5 С • ШКАЛА %d" % [current_dps, int(dps_bar.max_value)]


func _update_upgrade_list() -> void:
	$Hud/UpgradeList.text = "%s • УР. %d/7" % [WEAPON_NAMES[selected_weapon], test_weapon_level] if WEAPON_NAMES.has(selected_weapon) else "БЕЗ ОРУЖИЯ • ПОДБЕРИ ПРЕДМЕТ"
	if is_instance_valid(training_stats):
		training_stats.text = "НАНЕСЕНО УРОНА: %d" % training_damage
		level_down.disabled = selected_weapon.is_empty() or test_weapon_level <= 1
		level_up.disabled = selected_weapon.is_empty() or test_weapon_level >= 7


func _update_wave_hud() -> void:
	$Hud/Wave.text = "ТЕСТОВАЯ АРЕНА"
	$Hud/WaveTimer.text = "МИШЕНИ АФК • ВОЗРОЖДЕНИЕ 2 С"
	$Hud/Hint.text = "Подбери оружие • ESC — пауза"


# Training does not run waves, grant XP, hurt the mech or alter campaign progress.
func _connect_scout(_new_scout: AlienScout) -> void:
	pass

func _update_wave_progress(_delta: float) -> void:
	pass

func _update_wave_spawns(_delta: float) -> void:
	pass

func _spawn_wave_powerup_if_needed() -> void:
	pass

func _take_damage(_amount: float) -> void:
	pass

func _open_upgrade_choice() -> void:
	pass
