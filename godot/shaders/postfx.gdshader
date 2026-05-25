shader_type canvas_item;
// Full-screen cinematic post pass for the 3D view: chromatic aberration,
// contrast + cold desaturated grade, vignette, subtle scanlines, animated film
// grain. Applied via a ColorRect over a BackBufferCopy on a CanvasLayer below
// the UI, so HUD/menus stay crisp.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float ca_amount : hint_range(0.0, 0.02) = 0.006;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.85;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.20;
uniform float grain_amount : hint_range(0.0, 0.4) = 0.09;
uniform float saturation : hint_range(0.0, 2.0) = 0.90;
uniform float contrast : hint_range(0.5, 2.0) = 1.07;
uniform vec3 cold_tint = vec3(0.90, 0.99, 1.09);
uniform float scanline_amount : hint_range(0.0, 0.2) = 0.03;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - vec2(0.5);
	float d = length(dir);

	// Chromatic aberration, stronger toward the edges.
	vec2 off = dir * ca_amount * (0.35 + d);
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	// Contrast around mid-grey.
	col = (col - 0.5) * contrast + 0.5;

	// Desaturate + cold grade.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col *= cold_tint;

	// Vignette.
	col *= 1.0 - vignette_strength * smoothstep(vignette_start, 0.85, d);

	// Subtle scanlines.
	col *= 1.0 - scanline_amount * (0.5 + 0.5 * sin(SCREEN_UV.y * 1300.0));

	// Animated film grain.
	float g = (hash(uv * vec2(TIME * 91.3 + 1.0, TIME * 53.7 + 1.0)) - 0.5) * grain_amount;
	col += g;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
