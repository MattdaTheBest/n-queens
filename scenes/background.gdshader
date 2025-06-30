shader_type canvas_item;

uniform sampler2D palette;
uniform float checker_size = 32.0;
uniform float wave_strength = 8.0;
uniform float cell_distortion = 4.0;
uniform float time_scale = 1.0;
uniform float transition_speed = 1.5;
uniform float outline_thickness = 1.5;
uniform float darken = 0.8;

void fragment() {
	vec2 uv = FRAGCOORD.xy;

	// Diagonal scrolling
	uv += vec2(TIME, TIME) * 20.0;

	// Global wave distortion
	uv.x += sin(uv.y / 20.0 + TIME * time_scale) * wave_strength;
	uv.y += sin(uv.x / 25.0 + TIME * time_scale * 0.6) * wave_strength;

	// Cell-local distortion
	vec2 cell_id = floor(uv / checker_size);
	vec2 cell_uv = fract(uv / checker_size);

	cell_uv.x += sin((cell_uv.y + cell_id.x * 0.1 + TIME) * 10.0) * (cell_distortion / checker_size);
	cell_uv.y += cos((cell_uv.x + cell_id.y * 0.1 + TIME) * 10.0) * (cell_distortion / checker_size);

	// Recombine distorted UV
	uv = (cell_id + cell_uv) * checker_size;

	// Checker pattern
	float checker = mod(cell_id.x + cell_id.y, 2.0);

	// Outline detection
	float edge_x = min(cell_uv.x, 1.0 - cell_uv.x);
	float edge_y = min(cell_uv.y, 1.0 - cell_uv.y);
	float edge_dist = min(edge_x, edge_y);

	// Palette blending
	float count = 8.0;
	float step = 1.0 / count;
	float time_index = TIME * transition_speed;
	float base_index = floor(mod(time_index, count));
	float next_index = mod(base_index + 1.0, count);
	float mix_factor = fract(time_index);

	float offset1 = (base_index + checker) * step + step * 0.5;
	float offset2 = (next_index + checker) * step + step * 0.5;

	vec4 col1 = texture(palette, vec2(offset1, 0.5));
	vec4 col2 = texture(palette, vec2(offset2, 0.5));
	vec4 final_color = mix(col1, col2, mix_factor);
	final_color.rgb *= darken;

	// Output with outline
	if (edge_dist < outline_thickness / checker_size) {
		COLOR = vec4(0.05, 0.05, 0.05, 1.0);
	} else {
		COLOR = final_color;
	}
}
