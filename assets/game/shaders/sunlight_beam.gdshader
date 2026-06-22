shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 sun_color : source_color = vec4(1.0, 0.82, 0.40, 1.0);
uniform vec4 heat_color : source_color = vec4(1.0, 0.55, 0.26, 1.0);

void fragment() {
	float left_edge = smoothstep(0.0, 0.055, UV.x);
	float right_edge = smoothstep(0.0, 0.055, 1.0 - UV.x);
	float edge_mask = left_edge * right_edge;
	float depth_fade = mix(1.0, 0.52, UV.y);
	float band = 0.5 + 0.5 * sin((UV.y * 18.0) - (TIME * 1.7));
	float filament = pow(0.5 + 0.5 * sin((UV.x * 53.0) + (UV.y * 9.0) + TIME), 8.0);
	float shimmer = mix(0.68, 1.0, band) + filament * 0.18;
	vec3 beam_color = mix(heat_color.rgb, sun_color.rgb, UV.y);
	float source_bloom = 1.0 - smoothstep(0.0, 0.22, UV.y);
	float alpha = (0.16 + 0.16 * shimmer + source_bloom * 0.22) * edge_mask * depth_fade;
	COLOR = vec4(beam_color, alpha);
}
