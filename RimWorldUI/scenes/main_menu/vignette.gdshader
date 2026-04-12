shader_type canvas_item;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c) * 2.0;
	float a = smoothstep(0.22, 0.98, d) * 0.42;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
