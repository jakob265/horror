extends Control
# Translucent screen-FX layer for a jumpscare: a red flash, dark vignette,
# chromatic edge fringes, scanlines and a fade. It is mostly transparent in the
# centre so the 3D monster that ScareDirector lunges at the camera shows
# through it. No drawn face, no photos — the scare is the rendered entity.

const DURATION := 0.7
var _life := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(dt: float) -> void:
	_life += dt
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var s := size
	var u: float = minf(s.x, s.y)
	var t := _life / DURATION
	var fade := 1.0 if t < 0.7 else (1.0 - (t - 0.7) / 0.3)
	# One-frame white pop, then a fading red wash (kept low alpha so the monster
	# stays visible underneath).
	if _life < 0.04:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.35, 0.0, 0.0, (1.0 - t) * 0.35 * fade))
	# Heavy dark vignette frame (center stays clear)
	var vt := u * 0.16
	draw_rect(Rect2(0, 0, s.x, vt), Color(0, 0, 0, 0.7 * fade))
	draw_rect(Rect2(0, s.y - vt, s.x, vt), Color(0, 0, 0, 0.7 * fade))
	draw_rect(Rect2(0, 0, vt, s.y), Color(0, 0, 0, 0.7 * fade))
	draw_rect(Rect2(s.x - vt, 0, vt, s.y), Color(0, 0, 0, 0.7 * fade))
	# Chromatic fringes at the side edges
	draw_rect(Rect2(0, 0, u * 0.03, s.y), Color(1, 0, 0, 0.25 * fade))
	draw_rect(Rect2(s.x - u * 0.03, 0, u * 0.03, s.y), Color(0, 1, 1, 0.25 * fade))
	# Flickering scanlines / glitch bars
	if randf() < 0.7:
		for i in 4:
			draw_rect(Rect2(0, randf() * s.y, s.x, u * 0.012), Color(0.0, 0.0, 0.0, 0.35 * fade))
	if randf() < 0.4:
		var gy := randf() * s.y
		draw_rect(Rect2(0, gy, s.x, u * 0.02), Color(randf() * 0.4, 0.0, 0.0, 0.4 * fade))
