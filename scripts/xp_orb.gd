class_name XpOrb
extends Node2D

enum Tier { SMALL_YELLOW, LARGE_RED, ELITE_BLUE }

var tier := Tier.SMALL_YELLOW
var experience_amount := 10
var player_position := Vector2.ZERO
var active := false
var forced_pull := false

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
	var offset := player_position - global_position
	if forced_pull or offset.length() < 42.0:
		global_position += offset.normalized() * (480.0 if forced_pull else 240.0) * delta
	if offset.length() < 7.0:
		collected.emit(experience_amount)
		deactivate()


func _draw() -> void:
	var orb_color := Color("ffe25c")
	if tier == Tier.LARGE_RED:
		orb_color = Color("f05b61")
	elif tier == Tier.ELITE_BLUE:
		orb_color = Color("5cc8ff")
	draw_circle(Vector2.ZERO, 4.0, Color(orb_color.r, orb_color.g, orb_color.b, 0.25))
	draw_circle(Vector2.ZERO, 2.5, orb_color)
	draw_circle(Vector2(-0.7, -0.8), 0.8, Color.WHITE)
