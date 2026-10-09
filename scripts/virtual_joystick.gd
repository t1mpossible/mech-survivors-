extends Control

## Simple analogue movement stick for touch screens.
## It is intentionally drawn in code to stay light on mobile GPUs.

@export var force_visible := false
@export_range(0.05, 0.4, 0.01) var deadzone := 0.16
@export var base_radius := 68.0
@export var travel_radius := 46.0

var direction := Vector2.ZERO
var touch_index := -1
var knob_position := Vector2.ZERO
var touch_origin := Vector2.ZERO
var touch_enabled := false


func _ready() -> void:
	touch_enabled = force_visible or _is_touch_device()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_release_touch()
	get_viewport().size_changed.connect(_release_touch)


static func _is_touch_device() -> bool:
	if DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web"):
		var browser_touch: Variant = JavaScriptBridge.eval("navigator.maxTouchPoints > 0 || 'ontouchstart' in window")
		return browser_touch is bool and browser_touch
	return false


func is_active() -> bool:
	return touch_index >= 0 and direction.length_squared() > 0.0


func _process(_delta: float) -> void:
	if get_tree().paused and touch_index >= 0:
		_release_touch()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_touch()


func _unhandled_input(event: InputEvent) -> void:
	# GUI buttons get the first chance to handle a new touch.
	if not touch_enabled or get_tree().paused:
		return
	if event is InputEventScreenTouch and event.pressed and touch_index < 0:
		touch_index = event.index
		touch_origin = _to_local_touch_position(event.position)
		knob_position = touch_origin
		direction = Vector2.ZERO
		visible = true
		queue_redraw()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if touch_index < 0:
		return
	if event is InputEventScreenTouch and event.index == touch_index and (not event.pressed or event.canceled):
		_release_touch()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		if get_tree().paused:
			_release_touch()
		else:
			_update_direction(_to_local_touch_position(event.position))
		get_viewport().set_input_as_handled()


func _to_local_touch_position(screen_position: Vector2) -> Vector2:
	# _input positions are viewport-local; include HUD scale and safe-area offset.
	return get_global_transform_with_canvas().affine_inverse() * screen_position


func _update_direction(local_position: Vector2) -> void:
	var center := touch_origin
	var max_distance := maxf(travel_radius, 1.0)
	var offset := local_position - center
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	knob_position = center + offset
	var strength := clampf(offset.length() / max_distance, 0.0, 1.0)
	direction = Vector2.ZERO if strength < deadzone else offset.normalized() * strength
	queue_redraw()


func _release_touch() -> void:
	touch_index = -1
	direction = Vector2.ZERO
	knob_position = touch_origin
	visible = false
	queue_redraw()


func _draw() -> void:
	if touch_index < 0:
		return
	var center := touch_origin
	var radius := base_radius
	var knob_radius := radius * 0.42
	draw_circle(center, radius, Color(0.015, 0.12, 0.18, 0.22))
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.38, 0.86, 1.0, 0.5), 1.5, true)
	draw_arc(center, radius * 0.62, 0.0, TAU, 32, Color(0.1, 0.58, 0.76, 0.22), 1.0, true)
	draw_line(Vector2(center.x - radius * 0.72, center.y), Vector2(center.x + radius * 0.72, center.y), Color(0.3, 0.82, 1.0, 0.16), 1.0)
	draw_line(Vector2(center.x, center.y - radius * 0.72), Vector2(center.x, center.y + radius * 0.72), Color(0.3, 0.82, 1.0, 0.16), 1.0)
	draw_circle(knob_position, knob_radius, Color(0.12, 0.62, 0.82, 0.42))
	draw_arc(knob_position, knob_radius, 0.0, TAU, 28, Color(0.66, 0.95, 1.0, 0.86), 1.5, true)
