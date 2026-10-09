extends Control
## Full-rect UI root. Child anchors are authored in the scenes, not repositioned
## every frame. Keep the 640x360 composition and fit it inside mobile safe insets.

@export var reference_size := Vector2(640.0, 360.0)
@export var mobile_ui_scale := 1.2
var touch_layout := false

const WEB_SAFE_AREA := """
(function () {
    var canvas = document.getElementById('canvas');
    if (!canvas) return null;
    var probe = document.createElement('div');
    probe.style.cssText = 'position:fixed;visibility:hidden;pointer-events:none;' +
        'padding:env(safe-area-inset-top,0px) env(safe-area-inset-right,0px) ' +
        'env(safe-area-inset-bottom,0px) env(safe-area-inset-left,0px)';
    document.body.appendChild(probe);
    var style = getComputedStyle(probe), rect = canvas.getBoundingClientRect();
    var result = [rect.width, rect.height,
        Math.max(0, (parseFloat(style.paddingLeft)||0) - rect.left),
        Math.max(0, (parseFloat(style.paddingTop)||0) - rect.top),
        Math.max(0, rect.right - innerWidth + (parseFloat(style.paddingRight)||0)),
        Math.max(0, rect.bottom - innerHeight + (parseFloat(style.paddingBottom)||0))];
    probe.remove();
    return JSON.stringify(result);
})()
"""


func _ready() -> void:
	touch_layout = preload("res://scripts/virtual_joystick.gd")._is_touch_device()
	# Resize must also work while the scene tree is paused for upgrades/options.
	get_viewport().size_changed.connect(_queue_layout)
	_queue_layout()


func _queue_layout() -> void:
	_apply_layout.call_deferred()


func _apply_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe_rect := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("web"):
		var raw: Variant = JavaScriptBridge.eval(WEB_SAFE_AREA)
		if raw is String:
			var insets: Variant = JSON.parse_string(raw)
			if insets is Array and insets.size() == 6 and insets[0] > 0 and insets[1] > 0:
				var ratio := viewport_size / Vector2(float(insets[0]), float(insets[1]))
				var start := Vector2(float(insets[2]), float(insets[3])) * ratio
				var finish := Vector2(float(insets[4]), float(insets[5])) * ratio
				safe_rect = Rect2(start, viewport_size - start - finish)
	elif OS.has_feature("android") or OS.has_feature("ios"):
		var safe_pixels := Rect2(DisplayServer.get_display_safe_area())
		if safe_pixels.has_area():
			var ratio := viewport_size / Vector2(DisplayServer.window_get_size())
			var window_origin := Vector2(DisplayServer.window_get_position())
			safe_rect = Rect2((safe_pixels.position - window_origin) * ratio, safe_pixels.size * ratio)
	apply_safe_rect(safe_rect.intersection(Rect2(Vector2.ZERO, viewport_size)))


func apply_safe_rect(safe_rect: Rect2) -> void:
	if not safe_rect.has_area():
		return
	var desired_scale := mobile_ui_scale if touch_layout else 1.0
	var minimum_size := Vector2(reference_size.x, 300.0) if touch_layout else reference_size
	# Use spare space on tall/wide phones, while keeping panels and HUD in bounds.
	var fit := minf(desired_scale, minf(safe_rect.size.x / minimum_size.x, safe_rect.size.y / minimum_size.y))
	# Desktop retains scale=1 unless safe insets require fitting; mobile may grow.
	scale = Vector2.ONE * fit
	var viewport_size := get_viewport_rect().size
	offset_left = safe_rect.position.x
	offset_top = safe_rect.position.y
	offset_right = safe_rect.position.x + safe_rect.size.x / fit - viewport_size.x
	offset_bottom = safe_rect.position.y + safe_rect.size.y / fit - viewport_size.y
