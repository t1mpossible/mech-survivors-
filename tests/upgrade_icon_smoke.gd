extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("indices: %s %s %s %s %s %s" % [UpgradeIcon.HEALTH_ICON, UpgradeIcon.REPAIR_ICON, UpgradeIcon.SPEED_ICON, UpgradeIcon.ARMOR_ICON, UpgradeIcon.SHIELD_ICON, UpgradeIcon.MAGNET_ICON])
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var icon: UpgradeIcon = game.get_node("Hud/HudScale/UpgradePanel/IconA")
	for kind in ["max_health", "repair", "speed", "armor", "shield", "magnet"]:
		icon.icon_index = game._get_upgrade_icon_index(kind)
		assert(icon.icon_index >= UpgradeIcon.HEALTH_ICON, "%s has an invalid mech icon index" % kind)
		print("%s -> cell %s" % [kind, icon.icon_index - UpgradeIcon.HEALTH_ICON])
	quit()
