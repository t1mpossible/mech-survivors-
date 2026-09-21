class_name XpOrb
extends Node2D

enum Tier { SMALL_YELLOW, LARGE_RED, ELITE_BLUE }
const XP_ART := preload("res://assets/xp_pickups_v1.png")

var tier := Tier.SMALL_YELLOW
var experience_amount := 10
var player_position := Vector2.ZERO
var active := false
var forced_pull := false
var visual_time := 0.0

signal collected(amount: int)


func _ready() -> void:
	add_to_group("xp_orbs")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func activate(start_position: Vector2, new_tier: int, new_experience_amount: int) -> void:
	global_position = start_position
	tier = new_tier
	experience_amount = new_experience_amount
	visual_time = 0.0
	forced_pull = false
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	queue_redraw()


func deactivate() -> void:
	active = false
	visible = false
	forced_pull = false
	process_mode = Node.PROCESS_MODE_DISABLED


func force_pull() -> void:
	forced_pull = true


func _process(delta: float) -> void:
	visual_time += delta
	var offset := player_position - global_position
	if forced_pull or offset.length() < 42.0:
		global_position += offset.normalized() * (480.0 if forced_pull else 240.0) * delta
	if offset.length() < 7.0:
		collected.emit(experience_amount)
		deactivate()
	queue_redraw()


func _draw() -> void:
	var frame := int(visual_time * 6.0) % 2
	var cell := Vector2(XP_ART.get_width() / 3.0, XP_ART.get_height() / 2.0)
	var source := Rect2(Vector2(float(tier) * cell.x, frame * cell.y), cell)
	# Yellow XP is the most common pickup, so it is deliberately easy to spot
	# among projectiles and desert scenery.
	var size := 18.0
	if tier == Tier.LARGE_RED:
		size = 17.29
	elif tier == Tier.ELITE_BLUE:
		size = 22.61
	draw_texture_rect_region(XP_ART, Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size), source)
