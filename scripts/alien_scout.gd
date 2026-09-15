class_name AlienScout
extends Node2D

@export var movement_speed := 24.0
@export var max_health := 30
@export var contact_damage_per_second := 8.0
var target_position := Vector2.ZERO
var travel_direction := Vector2.DOWN
var health := max_health

signal health_changed(current_health: int, maximum_health: int)
signal died


func _ready() -> void:
	add_to_group("enemies")
	queue_redraw()


func _process(delta: float) -> void:
	var offset := target_position - global_position
	if offset.length() > 18.0:
		travel_direction = offset.normalized()
		global_position += travel_direction * movement_speed * delta
		queue_redraw()


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()
		queue_free()


func _draw() -> void:
	# First alien: a quick, low-profile scout. It will later receive health and attacks.
	draw_circle(Vector2(1, 3), 10.0, Color("080d17"))
	draw_circle(Vector2.ZERO, 8.0, Color("9a477d"))
	draw_circle(Vector2(-3, -2), 3.0, Color("d66cab"))
	draw_circle(Vector2(3, -2), 3.0, Color("d66cab"))
	draw_circle(Vector2(-3, -2), 1.0, Color("f7df79"))
	draw_circle(Vector2(3, -2), 1.0, Color("f7df79"))
	draw_line(Vector2(-8, 3), Vector2(-13, 9), Color("6a315a"), 2.0)
	draw_line(Vector2(8, 3), Vector2(13, 9), Color("6a315a"), 2.0)
	draw_line(Vector2(-5, 7), Vector2(-8, 12), Color("6a315a"), 2.0)
	draw_line(Vector2(5, 7), Vector2(8, 12), Color("6a315a"), 2.0)

	# Visible during balance tuning; later this can become an optional UI setting.
	draw_rect(Rect2(-10, -15, 20, 3), Color("160d18"))
	draw_rect(Rect2(-9, -14, 18.0 * float(health) / float(max_health), 1), Color("f06a9d"))
