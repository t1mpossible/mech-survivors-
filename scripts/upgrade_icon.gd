class_name UpgradeIcon
extends Control

## Маленькая иконка для карточки улучшения.
## Оружие использует голубые эмблемы, корпус меха — те же эмблемы с зелёными плитами.
const WEAPON_ICON_SHEET := preload("res://assets/upgrade_weapon_icons_4cells_v2.png")
const WEAPON_ICON_COUNT := 4
const MECH_ICON_SHEET := preload("res://assets/upgrade_mech_icons_6cells_v2.png")
const MECH_ICON_COUNT := 6

const PLASMA_CANNON_ICON := 0
const MISSILE_ICON := 1
const LASER_ICON := 2
const SHURIKEN_ICON := 3
const HEALTH_ICON := 4
const REPAIR_ICON := 5
const SPEED_ICON := 6
const ARMOR_ICON := 7
const SHIELD_ICON := 8
const MAGNET_ICON := 9

@export_range(0, MAGNET_ICON) var icon_index := 0:
	set(value):
		icon_index = clampi(value, 0, MAGNET_ICON)
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if icon_index >= HEALTH_ICON:
		_draw_sheet_cell(MECH_ICON_SHEET, MECH_ICON_COUNT, icon_index - HEALTH_ICON)
		return
	_draw_sheet_cell(WEAPON_ICON_SHEET, WEAPON_ICON_COUNT, icon_index)


func _draw_sheet_cell(sheet: Texture2D, cell_count: int, cell_index: int) -> void:
	# The generated sheets include transparent top/bottom padding. Crop it before
	# fitting the art into the card, so icons stay large and retain their proportions.
	var cell_width := float(sheet.get_width()) / float(cell_count)
	var crop_y := float(sheet.get_height()) * 0.16
	var crop_height := float(sheet.get_height()) * 0.68
	var source := Rect2(float(cell_index) * cell_width, crop_y, cell_width, crop_height)
	var scale_factor := minf(size.x / source.size.x, size.y / source.size.y)
	var draw_size := source.size * scale_factor
	var draw_position := (size - draw_size) * 0.5
	draw_texture_rect_region(sheet, Rect2(draw_position, draw_size), source)
