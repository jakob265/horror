extends Control
# A procedural "screamer" face flashed full-screen on contact / key scares.
# Drawn entirely in code at runtime — no external image assets.

const DURATION := 0.65
var _life := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioManager.shape_sting()
	AudioManager.boom()


func _process(dt: float) -> void:
	_life += dt
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var s := size
	var u: float = minf(s.x, s.y)
	var t := _life / DURATION
	# Punch-in: features start large, settle quickly. Shake for the first half.
	var grow := lerpf(1.28, 1.0, clampf(t * 3.0, 0.0, 1.0))
	var shake := 0.0 if t > 0.5 else (1.0 - t * 2.0) * u * 0.025
	var cx := s.x * 0.5 + randf_range(-shake, shake)
	var cy := s.y * 0.5 + randf_range(-shake, shake)
	var fade := 1.0 if t < 0.72 else (1.0 - (t - 0.72) / 0.28)
	# Background: near-black, faint blood red, fading out at the end.
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.005, 0.005, fade))
	# Gaunt pale face
	_ellipse(Vector2(cx, cy + u * 0.02 * grow), u * 0.27 * grow, u * 0.38 * grow, Color(0.74, 0.70, 0.65, fade))
	# Cheek hollows
	for hx in [-1.0, 1.0]:
		_ellipse(Vector2(cx + hx * u * 0.20 * grow, cy + u * 0.06 * grow), u * 0.10 * grow, u * 0.20 * grow, Color(0.40, 0.36, 0.34, fade * 0.7))
	var eye_y := cy - u * 0.10 * grow
	var edx := u * 0.12 * grow
	for ex in [cx - edx, cx + edx]:
		# Sunken dark socket
		_ellipse(Vector2(ex, eye_y), u * 0.082 * grow, u * 0.095 * grow, Color(0.03, 0.015, 0.015, fade))
		# Glowing red iris + black pupil
		draw_circle(Vector2(ex, eye_y + u * 0.012 * grow), u * 0.034 * grow, Color(0.96, 0.12, 0.08, fade))
		draw_circle(Vector2(ex, eye_y + u * 0.012 * grow), u * 0.014 * grow, Color(0.0, 0.0, 0.0, fade))
		# Blood streak running down from the eye
		draw_line(Vector2(ex, eye_y + u * 0.05 * grow), Vector2(ex - u * 0.01 * grow, eye_y + u * 0.30 * grow), Color(0.45, 0.02, 0.02, fade * 0.85), u * 0.012 * grow)
	# Angry brows
	draw_line(Vector2(cx - edx - u * 0.08 * grow, eye_y - u * 0.11 * grow), Vector2(cx - edx + u * 0.05 * grow, eye_y - u * 0.05 * grow), Color(0.05, 0.03, 0.03, fade), u * 0.022 * grow)
	draw_line(Vector2(cx + edx + u * 0.08 * grow, eye_y - u * 0.11 * grow), Vector2(cx + edx - u * 0.05 * grow, eye_y - u * 0.05 * grow), Color(0.05, 0.03, 0.03, fade), u * 0.022 * grow)
	# Screaming mouth — large dark ellipse with teeth
	var mouth_y := cy + u * 0.18 * grow
	_ellipse(Vector2(cx, mouth_y), u * 0.115 * grow, u * 0.16 * grow, Color(0.06, 0.008, 0.008, fade))
	var n_teeth := 6
	for i in n_teeth:
		var tx := cx - u * 0.085 * grow + i * (u * 0.17 * grow / float(n_teeth - 1))
		draw_rect(Rect2(tx - u * 0.013 * grow, mouth_y - u * 0.15 * grow, u * 0.026 * grow, u * 0.052 * grow), Color(0.82, 0.79, 0.72, fade))
		draw_rect(Rect2(tx - u * 0.013 * grow, mouth_y + u * 0.10 * grow, u * 0.026 * grow, u * 0.052 * grow), Color(0.82, 0.79, 0.72, fade))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segs: int = 32) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a := float(i) * TAU / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)
