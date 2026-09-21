shader_type canvas_item;

// Driven by distance travelled, not TIME: stopping and pausing freeze the belt.
uniform float travel = 0.0;

float panel_mask(vec2 p, vec2 center, vec2 half_size) {
	vec2 edge = abs((p - center) / half_size);
	return 1.0 - smoothstep(0.78, 1.0, max(edge.x, edge.y));
}

void fragment() {
	vec4 base = COLOR;
	vec2 cell = UV * vec2(4.0, 2.0);
	vec2 p = fract(cell);
	int direction = int(floor(cell.x)) + int(floor(cell.y)) * 4;
	float mask = 0.0;
	float belt_position = p.y * 19.0;
	float sign_of_travel = direction == 4 || direction == 5 || direction == 3 ? -1.0 : 1.0;
	if (direction == 0 || direction == 4) {
		mask = max(panel_mask(p, vec2(0.265, 0.765), vec2(0.078, 0.105)),
			panel_mask(p, vec2(0.705, 0.765), vec2(0.078, 0.105)));
	} else if (direction == 2 || direction == 6) {
		// Follow the perimeter of the visible belt; leave wheels and hub untouched.
		vec2 q = (p - vec2(0.5, 0.762)) / vec2(0.29, 0.116);
		float radius = length(q);
		mask = smoothstep(0.72, 0.87, radius) * (1.0 - smoothstep(0.99, 1.12, radius));
		belt_position = atan(q.y, q.x) * 4.8;
		sign_of_travel = direction == 2 ? 1.0 : -1.0;
	} else {
		bool rightward = direction == 1 || direction == 3;
		vec2 near_center = rightward ? vec2(0.43, 0.773) : vec2(0.62, 0.773);
		vec2 far_center = rightward ? vec2(0.745, 0.734) : vec2(0.265, 0.734);
		mask = max(panel_mask(p, near_center, vec2(0.077, 0.09)),
			panel_mask(p, far_center, vec2(0.064, 0.073)));
		belt_position = (p.y + (rightward ? -p.x : p.x) * 0.35) * 20.0;
	}
	float groove = smoothstep(0.55, 0.85, cos((belt_position - travel * sign_of_travel) * 6.283185));
	// Preserve the silhouette, armor color and original alpha. Only belt detail moves.
	base.rgb *= 1.0 - mask * groove * 0.38;
	COLOR = base;
}
