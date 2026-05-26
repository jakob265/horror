extends Node3D
# ACT 4 - OBSERVATION LOUNGE.
# Horseshoe couch, Note 9 on coffee table, porthole, library cart, tea bar
# (Yuna's mug), toy piano, memorial wall, framed photo of young Eli.

const W := 14.0
const D := 12.0
const H := 3.6

var exit_open := false


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.55, 0.45, 0.35), Color(0.31, 0.27, 0.27))
	var wall := Color(0.42, 0.40, 0.45)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "MAINT", Color(0.43, 0.35, 0.27), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "OBSERVATION", Color(0.50, 0.40, 0.30),
		func(): exit_open = true, "Open OBSERVATION")

	# Porthole on the EAST wall - off the door axis, flat circular window
	_make_porthole(Vector3(W/2 - 0.12, 1.95, 0), "east")

	# Horseshoe couch with seat cushions + back rests
	for cfg in [
		[Vector3(2.8, 0.20, -1.0), Vector3(2.0, 0.40, 1.6)],
		[Vector3(-2.8, 0.20, -1.0), Vector3(2.0, 0.40, 1.6)],
		[Vector3(0, 0.20, -2.6), Vector3(4.4, 0.40, 1.2)],
	]:
		Chamber.make_prop_box(self, cfg[1], cfg[0], Color(0.36, 0.28, 0.21))
	# Seat cushions on top of the couch bases
	for cfg in [
		[Vector3(2.8, 0.46, -1.0), Vector3(1.7, 0.12, 1.3)],
		[Vector3(-2.8, 0.46, -1.0), Vector3(1.7, 0.12, 1.3)],
		[Vector3(0, 0.46, -2.6), Vector3(4.1, 0.12, 0.95)],
	]:
		Chamber.make_prop_box(self, cfg[1], cfg[0], Color(0.50, 0.40, 0.30))
	# Throw pillows
	for cfg in [
		[Vector3(2.4, 0.60, -0.4), Color(0.62, 0.45, 0.31)],
		[Vector3(-2.4, 0.60, -1.6), Color(0.47, 0.35, 0.27)],
		[Vector3(1.6, 0.60, -2.6), Color(0.55, 0.31, 0.27)],
	]:
		Chamber.make_prop_box(self, Vector3(0.40, 0.20, 0.40), cfg[0], cfg[1])

	# Coffee table with Note 9
	Chamber.make_prop_box(self, Vector3(1.6, 0.40, 0.8), Vector3(0, 0.20, -0.5), Color(0.27, 0.23, 0.20))
	Interactable.make_note(self, Vector3(0, 0.42, -0.5), "note_9", "Read folded paper")
	# Mug + magazine on coffee table for clutter
	Chamber.make_prop_box(self, Vector3(0.10, 0.14, 0.10), Vector3(0.5, 0.48, -0.7), Color(0.62, 0.43, 0.31), false)
	Chamber.make_prop_box(self, Vector3(0.32, 0.02, 0.22), Vector3(-0.4, 0.41, -0.2), Color(0.78, 0.74, 0.66), false)

	# Tea bar (east side)
	var tea_bar := Chamber.make_prop_box(self, Vector3(0.6, 1.0, 3.0), Vector3(W/2 - 0.5, 0.5, 2), Color(0.45, 0.39, 0.31))
	# Counter top trim
	Chamber.make_prop_box(self, Vector3(0.65, 0.04, 3.0), Vector3(W/2 - 0.5, 1.02, 2), Color(0.55, 0.47, 0.39), false)
	# Yuna's mug — sat on the counter top
	Interactable.make_examine(self, Vector3(W/2 - 0.65, 1.10, 2.4), Vector3(0.12, 0.14, 0.12),
		"Yuna's mug",
		"Yuna's mug.  Tea inside.  It is room temperature - which on this station means it has not been here for very long.",
		5.0, Color(0.78, 0.74, 0.71))
	# Kettle + tea tin next to mug
	Chamber.make_prop_box(self, Vector3(0.22, 0.30, 0.20), Vector3(W/2 - 0.55, 1.18, 1.6), Color(0.20, 0.22, 0.27), false)
	Chamber.make_prop_box(self, Vector3(0.18, 0.18, 0.18), Vector3(W/2 - 0.55, 1.12, 3.0), Color(0.78, 0.62, 0.28), false)
	# Spoons hanging
	for sx in [1.7, 2.0, 2.3]:
		Chamber.make_prop_box(self, Vector3(0.02, 0.18, 0.04), Vector3(W/2 - 0.20, 1.45, sx), Color(0.74, 0.76, 0.80), false)

	# Library cart with stacked books
	Chamber.make_prop_box(self, Vector3(0.8, 1.2, 0.5), Vector3(-W/2 + 1.0, 0.6, 3), Color(0.39, 0.31, 0.23))
	for cfg in [
		[Vector3(0.7, 0.12, 0.40), Vector3(-W/2 + 1.0, 1.26, 3), Color(0.43, 0.27, 0.20)],
		[Vector3(0.6, 0.10, 0.38), Vector3(-W/2 + 1.0, 1.42, 2.85), Color(0.27, 0.39, 0.43)],
		[Vector3(0.65, 0.10, 0.40), Vector3(-W/2 + 0.95, 1.56, 3.10), Color(0.55, 0.43, 0.27)],
	]:
		Chamber.make_prop_box(self, cfg[0], cfg[1], cfg[2], false)
	# Reading lamp next to the cart
	var lamp_base := Chamber.make_prop_box(self, Vector3(0.18, 0.08, 0.18), Vector3(-W/2 + 1.0, 1.24, 2.2), Color(0.20, 0.20, 0.24), false)
	Chamber.make_prop_box(self, Vector3(0.04, 0.45, 0.04), Vector3(-W/2 + 1.0, 1.47, 2.2), Color(0.20, 0.20, 0.24), false)
	var lamp_shade := MeshInstance3D.new()
	var lsm := CylinderMesh.new()
	lsm.top_radius = 0.10
	lsm.bottom_radius = 0.18
	lsm.height = 0.20
	lamp_shade.mesh = lsm
	lamp_shade.position = Vector3(-W/2 + 1.0, 1.78, 2.2)
	var lsmat := StandardMaterial3D.new()
	lsmat.albedo_color = Color(0.94, 0.86, 0.62)
	lsmat.emission_enabled = true
	lsmat.emission = Color(1.0, 0.86, 0.58)
	lsmat.emission_energy_multiplier = 0.6
	lamp_shade.material_override = lsmat
	add_child(lamp_shade)
	ActUtil.add_omni(self, Vector3(-W/2 + 1.0, 1.85, 2.2), Color(1.0, 0.86, 0.58), 1.4, 5.0, false)

	# Potted plant (SW corner) — Yuna's
	Chamber.make_prop_box(self, Vector3(0.32, 0.30, 0.32), Vector3(-W/2 + 0.7, 0.15, -D/2 + 0.9), Color(0.62, 0.43, 0.28), false)
	for px in [-0.08, 0, 0.08]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.55 + randf() * 0.2, 0.04),
			Vector3(-W/2 + 0.7 + px, 0.55, -D/2 + 0.9), Color(0.27, 0.55, 0.31), false)

	# Toy piano (west)
	Interactable.make_examine(self, Vector3(-W/2 + 1.0, 0.4, -3), Vector3(1.2, 0.6, 0.4),
		"Press a key",
		"It plays a flat E.  Mara's mother gave her this when she was eight.  She doesn't remember bringing it.",
		5.0, Color(0.62, 0.39, 0.27))
	# White/black keys
	for i in range(8):
		Chamber.make_prop_box(self, Vector3(0.12, 0.02, 0.32),
			Vector3(-W/2 + 0.45 + i * 0.14, 0.71, -3.04), Color(0.94, 0.92, 0.86), false)
	for i in range(5):
		Chamber.make_prop_box(self, Vector3(0.06, 0.04, 0.18),
			Vector3(-W/2 + 0.55 + i * 0.27, 0.74, -3.10), Color(0.10, 0.10, 0.12), false)

	# Memorial wall (east) - now with framed strip backing
	Chamber.make_prop_box(self, Vector3(0.10, 1.5, 2.6), Vector3(W/2 - 0.05, 1.6, -2), Color(0.32, 0.26, 0.22))
	Interactable.make_examine(self, Vector3(W/2 - 0.15, 1.6, -2), Vector3(0.05, 1.4, 2.4),
		"Read the memorial wall",
		"Names of previous crews.  Below them, the current crew - VOSS, OKAFOR, PARK, HARGROVE, SATO - each name with a small inked dot beside it.  Three of the dots are in your handwriting.  You do not remember making them.",
		8.0, Color(0.55, 0.51, 0.47))

	# Framed photo of young Eli (north wall) — now flat against the wall
	Chamber.make_prop_box(self, Vector3(0.46, 0.56, 0.04), Vector3(-3, 2.0, D/2 - 0.13), Color(0.22, 0.18, 0.15), false, "frame")
	Interactable.make_examine(self, Vector3(-3, 2.0, D/2 - 0.10), Vector3(0.40, 0.50, 0.05),
		"Look at the framed photo",
		"A boy on a beach. Eli, maybe seven.  Squinting at the camera.  You don't remember hanging this.  You don't remember packing it.",
		7.0, Color(0.78, 0.78, 0.82))

	# Star chart on west wall — emissive blue
	var chart := Chamber.make_prop_box(self, Vector3(0.08, 1.0, 1.6), Vector3(-W/2 + 0.05, 1.8, 2), Color(0.04, 0.06, 0.12))
	var chart_glow := MeshInstance3D.new()
	var cgm := BoxMesh.new()
	cgm.size = Vector3(0.02, 0.94, 1.50)
	chart_glow.mesh = cgm
	chart_glow.position = Vector3(0.06, 0, 0)
	var cgmat := StandardMaterial3D.new()
	cgmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	cgmat.albedo_color = Color(0.18, 0.35, 0.62)
	cgmat.emission_enabled = true
	cgmat.emission = Color(0.20, 0.45, 0.78)
	cgmat.emission_energy_multiplier = 0.7
	chart_glow.material_override = cgmat
	chart.add_child(chart_glow)
	Interactable.attach(chart, "Read the star chart", "examine_only", {
		"text": "A printed star chart pinned under glass.  KEPLER-442 is circled in blue marker, the line from the chart to the margin reads 'home -- 1,206 light years'.  Hargrove drew it.  Below that, in Yuna's hand:  'home is whoever you eat with.'",
		"duration": 6.0,
	})

	ActUtil.add_dust_motes(self, Vector3(0, 1.6, 0), Vector3(7, 1.8, 6), 80,
		Color(0.85, 0.86, 0.92, 0.15))

	# The lounge where they used to gather — now a body hangs over it.
	ActUtil.hanging_corpse(self, Vector3(-4.5, 3.5, 2.0), 1.8)
	ActUtil.viscera(self, Vector3(5.2, 0, -3.0))
	ActUtil.signal_growth(self, Vector3(6.6, 1.0, 3.0), 1.0)
	ActUtil.blood_trail(self, Vector3(2.0, 0, 4.5), Vector3(5.0, 0, -2.6), 7)
	ActUtil.wall_scrawl(self, "SIT WITH\nUS", Vector3(6.9, 1.95, 0.0), -90, 40)
	ActUtil.add_peeker(self, Vector3(-6.0, 0, -4.5), HorrorShape.KIND_FELIX, 30)
	ActUtil.haunt(self, {
		"intensity": 0.34,
		"lurkers": [{"kind": "yuna", "points": [
			Vector3(0, 0, 4), Vector3(-5, 0, 2), Vector3(5, 0, -2), Vector3(-4, 0, -4)]}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _make_porthole(center: Vector3, wall: String = "north") -> void:
	# Pick rotation + inset axis based on which wall hosts the porthole.
	# The cylinder's local +Y is its axis; we rotate so the axis points toward
	# the room interior, then offset the glass slightly toward the player.
	var rot: Vector3
	var inset: Vector3
	match wall:
		"east":
			rot = Vector3(0, 0, 90)
			inset = Vector3(-0.05, 0, 0)
		"west":
			rot = Vector3(0, 0, -90)
			inset = Vector3(0.05, 0, 0)
		"south":
			rot = Vector3(-90, 0, 0)
			inset = Vector3(0, 0, 0.05)
		_:  # north
			rot = Vector3(90, 0, 0)
			inset = Vector3(0, 0, -0.05)
	# Outer ring (metal frame)
	var frame := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 1.20
	fm.bottom_radius = 1.20
	fm.height = 0.12
	frame.mesh = fm
	frame.position = center
	frame.rotation_degrees = rot
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	fmat.albedo_color = Color(0.18, 0.20, 0.24)
	fmat.metallic = 0.7
	fmat.roughness = 0.35
	frame.material_override = fmat
	add_child(frame)
	# Inner glass disc, slightly recessed toward player
	var glass := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 1.00
	gm.bottom_radius = 1.00
	gm.height = 0.05
	glass.mesh = gm
	glass.position = center + inset
	glass.rotation_degrees = rot
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	gmat.albedo_color = Color(0.02, 0.03, 0.06)
	gmat.emission_enabled = true
	gmat.emission = Color(0.05, 0.08, 0.14)
	gmat.emission_energy_multiplier = 0.4
	gmat.metallic = 0.0
	gmat.roughness = 0.05
	glass.material_override = gmat
	add_child(glass)
	# Scattered stars across the glass (BoxMesh so they read from any angle)
	var star_inset: Vector3 = inset * 1.8
	for i in range(36):
		var star := MeshInstance3D.new()
		var sb := BoxMesh.new()
		var ssize := randf_range(0.018, 0.040)
		sb.size = Vector3(ssize, ssize, ssize)
		star.mesh = sb
		var ang := randf() * TAU
		var r := sqrt(randf()) * 0.92
		var off: Vector3
		if wall == "east" or wall == "west":
			off = Vector3(0, sin(ang) * r, cos(ang) * r)
		else:
			off = Vector3(cos(ang) * r, sin(ang) * r, 0)
		star.position = center + star_inset + off
		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_color = Color(1, 1, 1, 1)
		smat.emission_enabled = true
		smat.emission = Color(1, 0.96, 0.88, 1)
		smat.emission_energy_multiplier = 2.5
		star.material_override = smat
		add_child(star)
	# Cross mullions over the glass
	var horiz: Vector3
	var vert: Vector3
	if wall == "east" or wall == "west":
		horiz = Vector3(0.05, 0.02, 2.2)
		vert = Vector3(0.05, 2.2, 0.02)
	else:
		horiz = Vector3(2.2, 0.02, 0.05)
		vert = Vector3(0.02, 2.2, 0.05)
	for sz in [horiz, vert]:
		var m := MeshInstance3D.new()
		var mb := BoxMesh.new()
		mb.size = sz
		m.mesh = mb
		m.position = center + inset * 1.3
		var mm := StandardMaterial3D.new()
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mm.albedo_color = Color(0.20, 0.22, 0.27)
		mm.metallic = 0.6
		mm.roughness = 0.35
		m.material_override = mm
		add_child(m)


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_obs")
