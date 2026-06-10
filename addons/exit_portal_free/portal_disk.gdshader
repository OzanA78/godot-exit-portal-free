shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.88, 1.0);
uniform float elapsed : hint_range(0.0, 9999.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.8;
uniform float ring_count : hint_range(1.0, 10.0) = 4.0;
uniform float swirl_strength : hint_range(0.0, 10.0) = 3.5;
uniform float base_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float core_fill : hint_range(0.0, 2.0) = 0.0;  // iç dolgu parlaklığı (0 = eski hal)
uniform float ring_width : hint_range(0.01, 0.25) = 0.12;  // kenar halkası kalınlığı

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	float swirl = angle + dist * swirl_strength - elapsed * pulse_speed;
	float rings = sin(dist * ring_count * TAU - elapsed * pulse_speed * 2.0) * 0.5 + 0.5;
	float spiral = sin(swirl * 3.0) * 0.5 + 0.5;

	// İçi tamamen dolu disk — kenar yumuşak geçiş
	float mask = smoothstep(0.5, 0.3, dist);

	float pulse = sin(elapsed * pulse_speed) * 0.3 + 0.7;
	float intensity = (rings * 0.5 + spiral * 0.5) * mask * pulse;

	// Parlak kenar halkası
	float edge = smoothstep(0.5, 0.5 - ring_width, dist) * smoothstep(0.5 - ring_width * 2.0, 0.5 - ring_width, dist);
	float rim = pow(edge, 1.5) * 2.0;

	// İç dolgu: merkezde parlak, kenara doğru söner (core_fill ile kontrol).
	float core = smoothstep(0.5, 0.0, dist) * core_fill;

	vec3 col = glow_color.rgb * (intensity + rim + core);
	ALBEDO = col;
	EMISSION = col * (2.0 + rim * 3.0);
	ALPHA = (intensity * 0.85 + rim + core) * mask * base_alpha;
}
