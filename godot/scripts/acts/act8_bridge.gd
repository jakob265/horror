extends Node3D
# ACT 8 - BRIDGE / COMMUNICATIONS.
# 18x16 command deck. Five crew stations, raised captain's platform,
# holographic system map, crew photo, whiteboard, Hargrove-Shape at back.

const W := 18.0
const D := 16.0
const H := 3.8


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.55, 0.66, 0.78), Color(0.10, 0.14, 0.20), 0.018, 0.55)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.29, 0.31, 0.35), Color(0.12, 0.14, 0.18))
	var wall := Color(0.25, 0.29, 0.35)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "STORAGE", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "MAINTENANCE", Color(0.28, 0.27, 0.23),
		func(): GameState.bridge_door_open = true, "Open MAINTENANCE")

	# Five crew stations along forward console
	var stations := [
		[-5.0, 2.5, "NAVIGATION\nCOURSE  LOCKED\nFUEL    72%", Color(0.16, 0.31, 0.20), Color(0.62, 0.90, 0.70)],
		[-2.5, 1.8, "UPLINK\nFAILED\n--.--.--", Color(0.31, 0.10, 0.10), Color(0.94, 0.66, 0.66)],
		[0.0, 1.5, "RELAY\nSILENT\n--.--.--", Color(0.16, 0.16, 0.20), Color(0.74, 0.78, 0.86)],
		[2.5, 1.8, "SIGNAL\n??.??.??\n*** INWARD ***", Color(0.31, 0.20, 0.10), Color(0.94, 0.70, 0.55)],
		[5.0, 2.5, "POWER\nCORE    NOMINAL\nLOAD    37%", Color(0.16, 0.20, 0.31), Color(0.66, 0.78, 0.94)],
	]
	for s in stations:
		_crew_station(s[0], s[1], s[2], s[3], s[4])

	# Curving rail / desk lip
	for dx_dz in [[-4.0, 1.5], [-2.0, 1.0], [0.0, 0.8], [2.0, 1.0], [4.0, 1.5]]:
		Chamber.make_prop_box(self, Vector3(2.0, 0.06, 0.2), Vector3(dx_dz[0], 0.90, dx_dz[1]), Color(0.31, 0.35, 0.43), false)

	# Crew chairs
	for cfg in [[-5.0, 3.4], [-2.5, 2.7], [0.0, 2.4], [2.5, 2.7], [5.0, 3.4]]:
		var cx: float = cfg[0]
		var cz: float = cfg[1]
		Chamber.make_prop_box(self, Vector3(0.55, 0.40, 0.55), Vector3(cx, 0.20, cz), Color(0.18, 0.20, 0.24))
		Chamber.make_prop_box(self, Vector3(0.55, 1.40, 0.10), Vector3(cx, 1.10, cz + 0.45), Color(0.16, 0.18, 0.22), false)

	# Note 12 - Mara's recorder on centre station
	Interactable.make_note(self, Vector3(0, 0.92, 0.6), "note_12", "Play personal recorder")

	# Raised captain's platform
	var plat_y := 0.30
	Chamber.make_prop_box(self, Vector3(5.5, plat_y, 3.5), Vector3(0, plat_y / 2, -4.0), Color(0.22, 0.24, 0.29))
	# Steps
	for sy_sd in [[0.10, 0.6], [0.20, 1.2]]:
		Chamber.make_prop_box(self, Vector3(3.5, sy_sd[0], sy_sd[1]), Vector3(0, sy_sd[0] / 2, -2.0 - sy_sd[1] / 2), Color(0.27, 0.29, 0.35))

	# Captain's chair
	var cap_chair := Chamber.make_prop_box(self, Vector3(0.80, 0.50, 0.80), Vector3(0, plat_y + 0.25, -4.0), Color(0.12, 0.14, 0.18))
	Chamber.make_prop_box(self, Vector3(0.80, 1.80, 0.12), Vector3(0, plat_y + 1.30, -4.45), Color(0.12, 0.14, 0.18), false)
	# Armrests
	for ax in [-0.5, 0.5]:
		Chamber.make_prop_box(self, Vector3(0.12, 0.30, 0.7), Vector3(ax, plat_y + 0.75, -4.0), Color(0.12, 0.14, 0.18), false)
	Interactable.attach(cap_chair, "Sit in the captain's chair", "examine_only", {
		"text": "You sit in the chair Hargrove used to sit in.  The view from here is excellent.  Five stations below you.  A window above with the dead moon behind it.  You used to mock him for sitting here.  You miss the version of yourself that got to mock anyone for anything.",
		"duration": 8.0,
	})

	# Holographic system map pedestal
	var ped := Chamber.make_prop_box(self, Vector3(1.0, 0.95, 1.0), Vector3(0, 0.47, -0.8), Color(0.16, 0.18, 0.22))
	Chamber.make_prop_box(self, Vector3(1.10, 0.10, 1.10), Vector3(0, 1.00, -0.8), Color(0.08, 0.10, 0.14), false)
	# Hologram sphere
	var holo := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.30
	hs.height = 0.60
	holo.mesh = hs
	holo.position = Vector3(0, 1.45, -0.8)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.55, 0.78, 0.90, 0.50)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.emission_enabled = true
	hmat.emission = Color(0.55, 0.78, 0.90)
	hmat.emission_energy_multiplier = 0.6
	holo.material_override = hmat
	add_child(holo)
	# Tiny moon
	var moon := MeshInstance3D.new()
	var msm := SphereMesh.new()
	msm.radius = 0.10
	msm.height = 0.20
	moon.mesh = msm
	moon.position = Vector3(0.50, 1.45, -0.8)
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.70, 0.66, 0.59, 0.78)
	mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moon.material_override = mmat
	add_child(moon)
	# Red dot (station)
	var dot := MeshInstance3D.new()
	var ds := SphereMesh.new()
	ds.radius = 0.04
	ds.height = 0.08
	dot.mesh = ds
	dot.position = Vector3(0.12, 1.40, -0.65)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.86, 0.31, 0.23)
	dmat.emission_enabled = true
	dmat.emission = Color(0.86, 0.31, 0.23)
	dot.material_override = dmat
	add_child(dot)
	Interactable.attach(ped, "Examine the system map", "examine_only", {
		"text": "A holographic projection of the Kepler-442 system.  Star, dead moon, station.  The red dot is the station.  The dotted line drawn in marker on the pedestal lip is the array's broadcast cone.  It is a circle.  It points back at the station.  We have been broadcasting to ourselves since we got here.",
		"duration": 10.0,
	})

	# Forward window frame
	Chamber.make_prop_box(self, Vector3(W - 2, 0.30, 0.20), Vector3(0, H - 0.5, D/2 - 0.15), Color(0.25, 0.29, 0.35), false)
	Chamber.make_prop_box(self, Vector3(W - 2, 0.30, 0.20), Vector3(0, H - 2.0, D/2 - 0.15), Color(0.25, 0.29, 0.35), false)
	for fx in [-(W - 2) / 2, (W - 2) / 2]:
		Chamber.make_prop_box(self, Vector3(0.30, 1.7, 0.20), Vector3(fx, H - 1.25, D/2 - 0.15), Color(0.25, 0.29, 0.35), false)
	# Dark window
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.08, 0.16, 0.27, 0.85)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.emission_enabled = true
	wmat.emission = Color(0.06, 0.10, 0.20)
	wmat.emission_energy_multiplier = 0.3
	var win := MeshInstance3D.new()
	var wb := BoxMesh.new()
	wb.size = Vector3(W - 2.6, 1.4, 0.05)
	win.mesh = wb
	win.position = Vector3(0, H - 1.25, D/2 - 0.15)
	win.material_override = wmat
	add_child(win)

	# Crew group photo (east wall)
	var photo_frame := Chamber.make_prop_box(self, Vector3(0.10, 1.4, 2.2), Vector3(W/2 - 0.13, 1.9, -2.5), Color(0.86, 0.84, 0.76))
	Interactable.attach(photo_frame, "Look at crew photo", "examine_only", {
		"text": "Five people in matching white jumpsuits.  Pre-flight, taken on the gantry.  Felix is behind you with his hand on your shoulder.  Yuna is leaning on the rail.  Hargrove is saying something that's making everyone laugh.  Sato is at the very edge of the frame, half-cropped, looking sideways at something off-camera.  You don't remember the joke.  You are sure there was one.",
		"duration": 10.0,
	})

	# Whiteboard (west wall)
	var board := Chamber.make_prop_box(self, Vector3(0.10, 1.6, 2.4), Vector3(-W/2 + 0.13, 2.0, 0), Color(0.90, 0.90, 0.92))
	Interactable.attach(board, "Read whiteboard", "examine_only", {
		"text": "Hargrove's handwriting in red marker:\n  array  442-K  -> 0.7 Pu\n  WE MADE IT\nand then crossed out:  THERE WAS NEVER ANYTHING OUT THERE\n(Crossed out so hard the marker tore through.)",
		"duration": 8.0,
	})

	# Side comms alcove (west wall)
	var alcove := Chamber.make_prop_box(self, Vector3(1.4, 1.6, 0.6), Vector3(-W/2 + 0.50, 0.80, 3.0), Color(0.20, 0.22, 0.27))
	# Emissive screen on the alcove face
	var alc_screen := MeshInstance3D.new()
	var asq := QuadMesh.new()
	asq.size = Vector2(1.10, 0.50)
	alc_screen.mesh = asq
	alc_screen.position = Vector3(-W/2 + 1.22, 1.00, 3.0)
	alc_screen.rotation_degrees = Vector3(0, 90, 0)
	var asmat := StandardMaterial3D.new()
	asmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	asmat.albedo_color = Color(0.04, 0.10, 0.18)
	asmat.emission_enabled = true
	asmat.emission = Color(0.10, 0.22, 0.45)
	asmat.emission_energy_multiplier = 0.4
	alc_screen.material_override = asmat
	add_child(alc_screen)
	ActUtil.wall_label(self, "LONG-RANGE\n  carrier:  OFFLINE\n  buffer:   FULL\n  msgs out: 0\n  msgs in:  0",
		Vector3(-W/2 + 1.25, 1.00, 3.0), 13, Color(0.62, 0.78, 0.94))

	# More fill — a star chart, a radio bench, a coffee station — to break up the empty north sides
	# Radio / comms bench against west wall just south of the alcove
	var radio_bench := Chamber.make_prop_box(self, Vector3(1.6, 0.90, 0.55), Vector3(-W/2 + 0.80, 0.45, 5.6), Color(0.20, 0.22, 0.27))
	# Radio chassis on top
	Chamber.make_prop_box(self, Vector3(1.0, 0.40, 0.40), Vector3(-W/2 + 0.75, 1.10, 5.6), Color(0.14, 0.16, 0.20), false)
	# Indicator LEDs
	var led_palette: Array[Color] = [Color(0.86, 0.22, 0.22), Color(0.86, 0.62, 0.22), Color(0.22, 0.86, 0.32), Color(0.22, 0.55, 0.86), Color(0.78, 0.42, 0.86)]
	for li in 5:
		var led_color: Color = led_palette[li]
		var led := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.06, 0.06, 0.02)
		led.mesh = lb
		led.position = Vector3(-W/2 + 0.55 + li * 0.10, 1.18, 5.4)
		var lm := StandardMaterial3D.new()
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		lm.albedo_color = led_color
		lm.emission_enabled = true
		lm.emission = led_color
		lm.emission_energy_multiplier = 1.2
		led.material_override = lm
		add_child(led)
	# Coiled headset cable bunched on the bench
	Chamber.make_prop_box(self, Vector3(0.20, 0.06, 0.20), Vector3(-W/2 + 1.40, 0.93, 5.6), Color(0.10, 0.10, 0.12), false)
	# Mug stained ring next to it
	Chamber.make_prop_box(self, Vector3(0.14, 0.16, 0.14), Vector3(-W/2 + 1.50, 0.98, 5.30), Color(0.55, 0.31, 0.24), false)

	# Star map case at the back of the room (north wall)
	var star_case := Chamber.make_prop_box(self, Vector3(2.6, 1.0, 0.08), Vector3(-4, 1.80, D/2 - 0.22), Color(0.04, 0.05, 0.10))
	var star_emi := MeshInstance3D.new()
	var seq := BoxMesh.new()
	seq.size = Vector3(2.55, 0.94, 0.04)
	star_emi.mesh = seq
	star_emi.position = Vector3(-4, 1.80, D/2 - 0.18)
	var semat := StandardMaterial3D.new()
	semat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	semat.albedo_color = Color(0.06, 0.10, 0.20)
	semat.emission_enabled = true
	semat.emission = Color(0.20, 0.34, 0.62)
	semat.emission_energy_multiplier = 0.45
	star_emi.material_override = semat
	add_child(star_emi)
	Interactable.attach(star_case, "Examine the star map", "examine_only", {
		"text": "A back-lit chart of the local stellar neighbourhood.  KEPLER-442 highlighted.  Distance to Sol: 1206 ly.  A green line traces the inbound signal vector.  It points back along the path you flew in on.",
		"duration": 6.0,
	})

	# Pendant lamps over each crew station for proper task lighting
	for sx in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		Chamber.make_prop_box(self, Vector3(0.06, 0.30, 0.06), Vector3(sx, H - 0.30, 1.8), Color(0.16, 0.16, 0.20), false)
		var bulb := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 0.10
		ss.height = 0.20
		bulb.mesh = ss
		bulb.position = Vector3(sx, H - 0.60, 1.8)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.88, 0.92, 1.0)
		bm.emission_enabled = true
		bm.emission = Color(0.78, 0.86, 1.0)
		bm.emission_energy_multiplier = 1.4
		bulb.material_override = bm
		add_child(bulb)

	# Hargrove-Shape at the back, facing away
	var hg := HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, plat_y, -D/2 + 1.5), 0)
	add_child(hg)
	ShapeTracker.register(hg)

	# Scattered mug on platform
	var mug := Chamber.make_prop_box(self, Vector3(0.15, 0.22, 0.15), Vector3(0.9, plat_y + 0.11, -3.5), Color(0.16, 0.23, 0.31))
	mug.rotation_degrees = Vector3(0, 0, 70)
	Interactable.attach(mug, "Look at the tipped mug", "examine_only", {
		"text": "A blue ceramic mug on its side, dark stain fanning out from it.  Hargrove's mug.  He must have set it down here and never picked it back up.",
		"duration": 5.0,
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _crew_station(x: float, z: float, label_text: String, screen_color: Color, text_color: Color) -> void:
	# Console
	var console := Chamber.make_prop_box(self, Vector3(1.2, 0.85, 0.6), Vector3(x, 0.42, z), Color(0.18, 0.20, 0.24))
	# Sloped panel
	Chamber.make_prop_box(self, Vector3(1.10, 0.30, 0.20), Vector3(x, 0.72, z - 0.30), Color(0.14, 0.16, 0.20), false)
	# Buttons
	var btn_colors := [Color(0.86, 0.23, 0.23), Color(0.86, 0.70, 0.23),
		Color(0.23, 0.86, 0.39), Color(0.23, 0.70, 0.86)]
	for bi in btn_colors.size():
		Chamber.make_prop_box(self, Vector3(0.10, 0.04, 0.10), Vector3(x - 0.40 + bi * 0.26, 0.88, z - 0.20), btn_colors[bi], false)
	# Back with screen
	var back := Chamber.make_prop_box(self, Vector3(1.0, 0.7, 0.06), Vector3(x, 1.20, z + 0.18), Color(0.12, 0.12, 0.14))
	# Screen
	var screen := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.92, 0.62)
	screen.mesh = q
	screen.position = Vector3(x, 1.20, z + 0.14)
	screen.rotation_degrees = Vector3(0, 180, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = screen_color
	smat.emission_enabled = true
	smat.emission = screen_color
	smat.emission_energy_multiplier = 0.3
	screen.material_override = smat
	add_child(screen)
	# Text — billboard so the label always reads correctly from the captain's chair
	ActUtil.wall_label(self, label_text, Vector3(x, 1.20, z + 0.12), 14, text_color)


func _process(_dt: float) -> void:
	if GameState.bridge_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_maint")
