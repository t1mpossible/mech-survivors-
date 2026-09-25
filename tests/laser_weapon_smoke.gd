extends SceneTree

var hits: Array[Dictionary] = []
var shots := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var first := _make_enemy(stage, Vector2(100.0, 0.0))
	var second := _make_enemy(stage, Vector2(150.0, 0.0))
	_make_enemy(stage, Vector2(100.0, 70.0))
	var burn := load("res://scenes/laser_weapon.tscn").instantiate() as LaserWeapon
	stage.add_child(burn)
	burn.damage_requested.connect(_record_hit)
	burn.unlock()
	burn.tick(0.01, Vector2.ZERO, first)
	if hits.size() != 1 or hits[0].damage != 3:
		_fail("Shared level 1 laser must deal 3 damage per tick")
		return
	if not burn.choose_branch("burn") or burn.choose_branch("pulse"):
		_fail("Burn branch must lock at level 2")
		return
	for index in range(5):
		if not burn.upgrade():
			_fail("Burn upgrade failed")
			return
	if burn.level != 7 or burn.current_stats().damage != 12 or burn.upgrade():
		_fail("Burn level 7 must deal 12 damage per tick")
		return
	hits.clear()
	burn.tick(0.01, Vector2.ZERO, first)
	if hits.size() != 1 or hits[0].damage != 12 or not burn.beam_active:
		_fail("Burn laser must fire during active phase")
		return
	burn.tick(3.5, Vector2.ZERO, first)
	var hits_before_cooldown := hits.size()
	burn.tick(0.9, Vector2.ZERO, first)
	if hits.size() != hits_before_cooldown or burn.beam_active:
		_fail("Burn laser must stop during its 1 second cooldown")
		return
	burn.tick(0.1, Vector2.ZERO, first)
	burn.tick(0.01, Vector2.ZERO, first)
	if hits.size() != hits_before_cooldown + 1:
		_fail("Burn laser must restart after cooldown")
		return
	var pulse := load("res://scenes/laser_weapon.tscn").instantiate() as LaserWeapon
	stage.add_child(pulse)
	pulse.damage_requested.connect(_record_hit)
	pulse.fired.connect(_record_shot)
	pulse.unlock()
	if not pulse.choose_branch("pulse"):
		_fail("Pulse branch choice failed")
		return
	var expected_widths := [12.0, 13.0, 14.0, 15.0, 16.0, 18.0]
	for index in range(expected_widths.size()):
		if pulse.pulse_levels[index + 1].beam_width != expected_widths[index]:
			_fail("Pulse width must increase gently with each level")
			return
	for index in range(5):
		pulse.upgrade()
	if pulse.level != 7 or pulse.current_stats().damage != 110:
		_fail("Pulse level 7 must deal 110 damage per enemy")
		return
	hits.clear()
	pulse.tick(0.01, Vector2.ZERO, first)
	if shots != 1 or hits.size() != 2 or hits[0].damage != 110 or hits[0].enemy != first or hits[1].enemy != second:
		_fail("Pulse must hit multiple enemies on the line once")
		return
	if pulse.pulse_visual_frame() != 0:
		_fail("Pulse animation must begin with frame 0")
		return
	pulse.tick(0.34, Vector2.ZERO, first)
	if pulse.pulse_visual_frame() != 1:
		_fail("Pulse animation must switch to frame 1")
		return
	pulse.tick(0.33, Vector2.ZERO, first)
	if pulse.pulse_visual_frame() != 2:
		_fail("Pulse animation must switch to frame 2")
		return
	pulse.tick(0.33, Vector2.ZERO, first)
	if pulse.pulse_visual_frame() != -1 or shots != 1 or hits.size() != 2:
		_fail("Pulse glow must end after one second without dealing extra damage")
		return
	pulse.tick(1.9, Vector2.ZERO, first)
	if shots != 1 or hits.size() != 2:
		_fail("Pulse must wait for its 3 second cooldown")
		return
	pulse.tick(0.11, Vector2.ZERO, first)
	if shots != 2 or hits.size() != 4:
		_fail("Pulse must fire again after 3 seconds")
		return
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.autocannon.level = 2
	game.autocannon.branch = "fan"
	game.laser.unlock()
	game._open_upgrade_choice()
	if game.available_upgrades[0].kind != "laser_branch_burn" or game.available_upgrades[1].kind != "laser_branch_pulse":
		_fail("Laser level 2 must offer both branches in upgrade choices")
		return
	game._choose_upgrade(1)
	if game.laser.level != 2 or game.laser.branch != "pulse" or game.get_tree().paused:
		_fail("Choosing pulse must apply the branch and resume the game")
		return
	quit()


func _make_enemy(stage: Node2D, position: Vector2) -> AlienScout:
	var enemy := AlienScout.new()
	stage.add_child(enemy)
	enemy.global_position = position
	enemy.add_to_group("enemies")
	enemy.set_process(false)
	return enemy


func _record_hit(enemy: AlienScout, damage: int) -> void:
	hits.append({"enemy": enemy, "damage": damage})


func _record_shot() -> void:
	shots += 1


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
