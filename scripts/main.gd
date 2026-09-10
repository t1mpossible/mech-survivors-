extends Node2D

const ARENA_SIZE := Vector2(320, 180)
const MECH_SPEED := 72.0

var mech_position := ARENA_SIZE / 2.0
var touch_direction := {"up": false, "down": false, "left": false, "right": false}


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement += Vector2(
		float(touch_direction["right"]) - float(touch_direction["left"]),
		float(touch_direction["down"]) - float(touch_direction["up"])
	)

	if movement.length() > 1.0:
		movement = movement.normalized()

	mech_position += movement * MECH_SPEED * delta
	mech_position.x = clampf(mech_position.x, 15.0, ARENA_SIZE.x - 15.0)
	mech_position.y = clampf(mech_position.y, 30.0, ARENA_SIZE.y - 15.0)
	queue_redraw()


func _set_touch_direction(direction: String, pressed: bool) -> void:
	touch_direction[direction] = pressed


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
