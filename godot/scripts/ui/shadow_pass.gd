extends Control
# A dark humanoid silhouette that sweeps quickly across the screen — the
# "something just crossed in front of me" scare. Pure 2D overlay (same proven
# path as the jumpscare layer), so it always renders. Frees itself when done.

const DURATION := 0.55
var _life := 0.0
var _dir := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dir = 1.0 if randf() < 0.5 else -1.0


func _process(dt: float) -> void:
	_life += dt
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var s := size
	var t := _life / DURATION
	var alpha := 0.85 * sin(t * PI)          # fade in then out as it crosses
	var w := s.x * 0.15
	var h := s.y * 0.92
	var cy := s.y * 0.54
	var x := lerpf(-w, s.x + w, t) if _dir > 0.0 else lerpf(s.x + w, -w, t)
	# Faint full-frame dimming as it passes — like a body blocking the light.
	draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.12 * sin(t * PI)))
	# Torso + tapered legs (a tall, thin body).
	draw_rect(Rect2(x - w * 0.5, cy - h * 0.5, w, h), Color(0, 0, 0, alpha))
	draw_rect(Rect2(x - w * 0.18, cy - h * 0.5, w * 0.36, h * 1.02), Color(0, 0, 0, alpha))
	# Head.
	draw_circle(Vector2(x, cy - h * 0.5 - w * 0.12), w * 0.30, Color(0, 0, 0, alpha))
