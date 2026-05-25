shader_type canvas_item;
// Self-contained cinematic overlay: vignette + animated film grain, alpha-
// composited directly over the 3D view. It outputs its own colour + alpha
// rather than sampling the screen (hint_screen_texture), so it renders
// reliably — the earlier screen-reading version never captured the 3D here.
// Colour grading / desaturation / cold tint is handled by the Environment.

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.80;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.28;
uniform float grain_amount : hint_range(0.0, 0.4) = 0.10;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float d = distance(UV, vec2(0.5));
	float vig = vignette_strength * smoothstep(vignette_start, 0.88, d);
	float n = hash(UV * vec2(TIME * 97.0 + 1.0, TIME * 61.0 + 7.0));
	float grain_a = abs(n - 0.5) * 2.0 * grain_amount * (1.0 - vig);
	float a = clamp(vig + grain_a, 0.0, 1.0);
	vec3 col = (vig * vec3(0.0) + grain_a * vec3(0.55)) / max(a, 0.0001);
	COLOR = vec4(col, a);
}
