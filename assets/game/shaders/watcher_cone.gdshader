shader_type canvas_item;
render_mode unshaded, blend_add;

void fragment() {
	float edge_mask = smoothstep(0.0, 0.075, UV.y) * smoothstep(0.0, 0.075, 1.0 - UV.y);
	float range_fade = 1.0 - smoothstep(0.86, 1.0, UV.x);
	float scan = 0.70 + 0.30 * sin((UV.x * 31.0) - (TIME * 5.5));
	float sweep_line = 1.0 - smoothstep(0.0, 0.035, abs(fract(UV.x * 4.0 - TIME * 0.7) - 0.5));
	float lattice = 0.88 + 0.12 * sin(UV.y * 68.0 + UV.x * 9.0);
	vec4 tint = COLOR;
	float alpha = tint.a * edge_mask * range_fade * scan * lattice + sweep_line * 0.045;
	COLOR = vec4(tint.rgb, alpha);
}
