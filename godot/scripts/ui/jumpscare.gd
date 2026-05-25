extends Control
# A procedural "screamer" flashed full-screen on contact / key scares. Drawn
# entirely in code — no external image assets. Picks one of several gory face
# variants and layers heavy distortion (shake, strobe, glitch bands, chromatic
# ghosting, blood, cracks) over a double stinger.

const DURATION := 1.0
var _life := 0.0
var _variant := 0
var _blood: Array = []     # [Vector2 normalized offset, float radius]
var _drips: Array = []     # [Vector2 normalized start, float length]
var _cracks: Array = []    # [PackedVector2Array normalized polyline]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_variant = randi() % 4
	# Pre-roll gore so it stays put across frames (only the glitch jitters).
	for i in randi_range(10, 18):
		_blood.append([Vector2(randf_range(-0.46, 0.46), randf_range(-0.5, 0.58)), randf_range(0.012, 0.05)])
	for i in randi_range(4, 8):
		_drips.append([Vector2(randf_range(-0.34, 0.34), randf_range(-0.38, 0.25)), randf_range(0.10, 0.42)])
	if _variant == 2 or _variant == 3:
		for i in randi_range(4, 7):
			var pts := PackedVector2Array()
			var p := Vector2(randf_range(-0.32, 0.32), randf_range(-0.42, -0.05))
			pts.append(p)
			for k in 4:
				p += Vector2(randf_range(-0.13, 0.13), randf_range(0.06, 0.16))
				pts.append(p)
			_cracks.append(pts)
	AudioManager.shape_sting()
	AudioManager.boom()
	# Second stinger partway through the longer flash.
	get_tree().create_timer(0.42).timeout.connect(func():
		if is_instance_valid(self):
			AudioManager.shape_sting())


func _process(dt: float) -> void:
	_life += dt
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _cfg() -> Dictionary:
	match _variant:
		1:
			return {"skin": Color(0.66, 0.62, 0.60), "socket": Color(0.88, 0.85, 0.82),
				"iris": Color(0.55, 0.02, 0.02), "mouth": Color(0.20, 0.0, 0.0),
				"mouth_ry": 0.21, "teeth": false, "jagged": false, "veins": true}
		2:
			return {"skin": Color(0.52, 0.55, 0.48), "socket": Color(0.0, 0.0, 0.0),
				"iris": Color(0.95, 0.12, 0.05), "mouth": Color(0.03, 0.0, 0.0),
				"mouth_ry": 0.17, "teeth": true, "jagged": true, "veins": false}
		3:
			return {"skin": Color(0.34, 0.09, 0.09), "socket": Color(0.02, 0.0, 0.0),
				"iris": Color(1.0, 0.55, 0.05), "mouth": Color(0.05, 0.0, 0.0),
				"mouth_ry": 0.17, "teeth": true, "jagged": true, "veins": false}
		_:
			return {"skin": Color(0.74, 0.70, 0.65), "socket": Color(0.03, 0.015, 0.015),
				"iris": Color(0.96, 0.12, 0.08), "mouth": Color(0.06, 0.008, 0.008),
				"mouth_ry": 0.16, "teeth": true, "jagged": false, "veins": false}


func _draw() -> void:
	var s := size
	var u: float = minf(s.x, s.y)
	var t := _life / DURATION
	var grow := lerpf(1.35, 1.0, clampf(t * 2.5, 0.0, 1.0))
	var sh := (1.0 - t * 0.6) * u * 0.03
	var cx := s.x * 0.5 + randf_range(-sh, sh)
	var cy := s.y * 0.5 + randf_range(-sh, sh)
	var fade := 1.0 if t < 0.84 else (1.0 - (t - 0.84) / 0.16)
	var cfg := _cfg()
	# Strobing black/red background.
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.0, 0.0, fade))
	if int(_life * 22) % 2 == 0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.13, 0.0, 0.0, fade * 0.5))
	# Chromatic ghosts of the face, then the real one on top.
	var ca := (1.0 - t) * u * 0.013
	_face(Vector2(cx - ca, cy), u, grow, fade * 0.45, cfg, Color(1.0, 0.2, 0.2))
	_face(Vector2(cx + ca, cy), u, grow, fade * 0.45, cfg, Color(0.2, 1.0, 1.0))
	_face(Vector2(cx, cy), u, grow, fade, cfg, Color(1, 1, 1))
	# Blood, drips, cracks (in normalized face space).
	var c := Vector2(cx, cy)
	for b in _blood:
		var bp: Vector2 = c + (b[0] as Vector2) * u * grow
		_ellipse(bp, b[1] * u * grow, b[1] * u * grow * 1.3, Color(0.42, 0.01, 0.01, fade * 0.9), 14)
	for d in _drips:
		var dp: Vector2 = c + (d[0] as Vector2) * u * grow
		draw_line(dp, dp + Vector2(0, d[1] * u * grow), Color(0.45, 0.02, 0.02, fade * 0.8), u * 0.01 * grow)
	for cr in _cracks:
		var pp := PackedVector2Array()
		for q in cr:
			pp.append(c + (q as Vector2) * u * grow)
		if pp.size() >= 2:
			draw_polyline(pp, Color(0.02, 0.0, 0.0, fade), maxf(1.0, u * 0.006 * grow))
	# Glitch slices.
	if randf() < 0.55:
		for i in 3:
			draw_rect(Rect2(0, randf() * s.y, s.x, u * 0.018), Color(randf() * 0.35, 0.0, 0.0, fade * 0.4))
	# Dark vignette frame.
	var vt := u * 0.10
	draw_rect(Rect2(0, 0, s.x, vt), Color(0, 0, 0, fade * 0.6))
	draw_rect(Rect2(0, s.y - vt, s.x, vt), Color(0, 0, 0, fade * 0.6))


func _face(center: Vector2, u: float, grow: float, fade: float, cfg: Dictionary, tint: Color) -> void:
	var skin: Color = (cfg["skin"] as Color) * tint
	skin.a = fade
	# Gaunt face + cheek hollows
	_ellipse(center + Vector2(0, u * 0.02 * grow), u * 0.27 * grow, u * 0.39 * grow, skin, 40)
	for hx in [-1.0, 1.0]:
		var hollow := skin.darkened(0.45)
		hollow.a = fade * 0.7
		_ellipse(center + Vector2(hx * u * 0.20 * grow, u * 0.06 * grow), u * 0.10 * grow, u * 0.21 * grow, hollow, 22)
	var eye_y := center.y - u * 0.10 * grow
	var edx := u * 0.12 * grow
	for ex in [center.x - edx, center.x + edx]:
		var socket: Color = cfg["socket"]
		socket.a = fade
		_ellipse(Vector2(ex, eye_y), u * 0.085 * grow, u * 0.10 * grow, socket, 22)
		if cfg.get("veins", false):
			for vi in 6:
				var a := randf() * TAU
				draw_line(Vector2(ex, eye_y), Vector2(ex + cos(a) * u * 0.07 * grow, eye_y + sin(a) * u * 0.08 * grow), Color(0.6, 0.05, 0.05, fade * 0.7), maxf(1.0, u * 0.004 * grow))
		var iris: Color = cfg["iris"]
		iris.a = fade
		draw_circle(Vector2(ex, eye_y + u * 0.012 * grow), u * 0.034 * grow, iris)
		draw_circle(Vector2(ex, eye_y + u * 0.012 * grow), u * 0.014 * grow, Color(0, 0, 0, fade))
		# Blood streak under each eye
		draw_line(Vector2(ex, eye_y + u * 0.05 * grow), Vector2(ex - u * 0.01 * grow, eye_y + u * 0.30 * grow), Color(0.45, 0.02, 0.02, fade * 0.8), u * 0.011 * grow)
	# Angry brows
	draw_line(Vector2(center.x - edx - u * 0.08 * grow, eye_y - u * 0.11 * grow), Vector2(center.x - edx + u * 0.05 * grow, eye_y - u * 0.05 * grow), Color(0.04, 0.02, 0.02, fade), u * 0.022 * grow)
	draw_line(Vector2(center.x + edx + u * 0.08 * grow, eye_y - u * 0.11 * grow), Vector2(center.x + edx - u * 0.05 * grow, eye_y - u * 0.05 * grow), Color(0.04, 0.02, 0.02, fade), u * 0.022 * grow)
	# Screaming mouth
	var mouth_y := center.y + u * 0.19 * grow
	var mr_y: float = cfg["mouth_ry"]
	var mcol: Color = cfg["mouth"]
	mcol.a = fade
	_ellipse(Vector2(center.x, mouth_y), u * 0.115 * grow, u * mr_y * grow, mcol, 26)
	if cfg.get("teeth", false):
		var n := 6
		var jag: bool = cfg.get("jagged", false)
		for i in n:
			var tx := center.x - u * 0.085 * grow + i * (u * 0.17 * grow / float(n - 1))
			var th := (u * 0.06 if (jag and i % 2 == 0) else u * 0.045) * grow
			draw_rect(Rect2(tx - u * 0.013 * grow, mouth_y - u * (mr_y - 0.01) * grow, u * 0.026 * grow, th), Color(0.82, 0.79, 0.72, fade))
			draw_rect(Rect2(tx - u * 0.013 * grow, mouth_y + u * (mr_y - 0.06) * grow, u * 0.026 * grow, th), Color(0.82, 0.79, 0.72, fade))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color, segs: int = 32) -> void:
	var pts := PackedVector2Array()
	for i in segs:
		var a := float(i) * TAU / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)
