extends Node3D
# ACT - MAINTENANCE CRAWL.
# Tight low-ceiling service shaft between bridge and approach.
# Sparking junction boxes, exposed conduit, Note 18.

const W := 4.5
const D := 20.0
const H := 2.2

var sparkers: Array = []
var warn_light: MeshInstance3D = null
var phase := 0.0


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.39, 0.43, 0.55), Color(0.06, 0.08, 0.12), 0.030, 0.45)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.20, 0.22, 0.27), Color(0.10, 0.12, 0.16))
	var wall := Color(0.18, 0.22, 0.27)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "BRIDGE", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "APPROACH", Color(0.28, 0.27, 0.23),
		func(): GameState.maint_door_open = true, "Open APPROACH")

	# Conduit / pipe bundles along walls
	for fx in [-W/2 + 0.30, W/2 - 0.30]:
		for cfg in [[0.40, Color(0.55, 0.43, 0.23)],
					[1.10, Color(0.23, 0.31, 0.43)],
					[1.70, Color(0.43, 0.23, 0.23)]]:
			Chamber.make_prop_box(self, Vector3(0.16, 0.16, D - 1.0), Vector3(fx, cfg[0], 0), cfg[1], false)
			for cz in range(-9, 10, 3):
				Chamber.make_prop_box(self, Vector3(0.22, 0.22, 0.10), Vector3(fx, cfg[0], cz), Color(0.23, 0.23, 0.27), false)

	# Cable runs across ceiling
	for cz in range(-9, 10, 2):
		Chamber.make_prop_box(self, Vector3(W - 0.2, 0.06, 0.18), Vector3(0, H - 0.05, cz), Color(0.12, 0.14, 0.18), false)
		if cz % 4 == 0:
			Chamber.make_prop_box(self, Vector3(0.05, 0.35, 0.05), Vector3(0.7, H - 0.20, cz), Color(0.16, 0.16, 0.20), false)

	# Floor grates revealing array glow below
	for fz in [-7, -3, 3, 7]:
		var grate := MeshInstance3D.new()
		var gq := QuadMesh.new()
		gq.size = Vector2(1.4, 1.0)
		grate.mesh = gq
		grate.rotation_degrees = Vector3(-90, 0, 0)
		grate.position = Vector3(0, 0.02, fz)
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.55, 0.70, 0.86)
		gmat.emission_enabled = true
		gmat.emission = Color(0.55, 0.70, 0.86)
		gmat.emission_energy_multiplier = 0.5
		grate.material_override = gmat
		add_child(grate)
		# Warm undertone
		var warm := MeshInstance3D.new()
		var wq := CylinderMesh.new()
		wq.top_radius = 0.8
		wq.bottom_radius = 0.8
		wq.height = 0.01
		warm.mesh = wq
		warm.position = Vector3(0, 0.04, fz)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.86, 0.66, 0.47, 0.40)
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wmat.emission_enabled = true
		wmat.emission = Color(0.86, 0.66, 0.47)
		wmat.emission_energy_multiplier = 0.3
		warm.material_override = wmat
		add_child(warm)

	# Sparking junction boxes
	for cfg in [[-W/2 + 0.20, -6], [W/2 - 0.20, -1], [-W/2 + 0.20, 4], [W/2 - 0.20, 9]]:
		_build_sparker(cfg[0], cfg[1])

	# Note 18 - scratched warning on a service panel
	var panel := Chamber.make_prop_box(self, Vector3(0.06, 0.50, 0.50), Vector3(-W/2 + 0.10, 1.20, 1.0), Color(0.16, 0.20, 0.25))
	Interactable.attach(panel, "Read scratched panel", "collect_note", {"note_id": "note_18"})

	# Toolbox in the middle
	var toolbox := Chamber.make_prop_box(self, Vector3(0.55, 0.30, 0.30), Vector3(0.6, 0.15, -2.5), Color(0.70, 0.51, 0.23))
	Chamber.make_prop_box(self, Vector3(0.06, 0.02, 0.40), Vector3(0.6, 0.31, -2.5), Color(0.70, 0.73, 0.76), false)
	Interactable.attach(toolbox, "Open the toolbox", "examine_only", {
		"text": "A station-issue maintenance kit.  The lid is open.  Most of the tools are gone.  The label on the inside lid says: K. SATO, in neat block letters that match the duty roster.",
		"duration": 6.0,
	})

	# Service ladder going down (visual)
	var ladder_x := -1.4
	var ladder_z := -5.5
	for dx in [-0.20, 0.20]:
		Chamber.make_prop_box(self, Vector3(0.05, 1.8, 0.05), Vector3(ladder_x + dx, 0.90, ladder_z), Color(0.55, 0.55, 0.59), false)
	for ry in [0.20, 0.55, 0.90, 1.25, 1.60]:
		Chamber.make_prop_box(self, Vector3(0.50, 0.04, 0.05), Vector3(ladder_x, ry, ladder_z), Color(0.55, 0.55, 0.59), false)
	# Floor hole
	var hole := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(0.7, 0.7)
	hole.mesh = hq
	hole.rotation_degrees = Vector3(-90, 0, 0)
	hole.position = Vector3(ladder_x, 0.02, ladder_z + 0.7)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.08, 0.12, 0.16)
	hole.material_override = hmat
	add_child(hole)

	# Red blinking warning light
	Chamber.make_prop_box(self, Vector3(0.30, 0.20, 0.30), Vector3(0, H - 0.20, D/2 - 1.5), Color(0.16, 0.16, 0.20))
	warn_light = MeshInstance3D.new()
	var wsm := SphereMesh.new()
	wsm.radius = 0.20
	wsm.height = 0.40
	warn_light.mesh = wsm
	warn_light.position = Vector3(0, H - 0.50, D/2 - 1.5)
	var wlmat := StandardMaterial3D.new()
	wlmat.albedo_color = Color(0.86, 0.20, 0.20)
	wlmat.emission_enabled = true
	wlmat.emission = Color(0.86, 0.20, 0.20)
	wlmat.emission_energy_multiplier = 0.6
	warn_light.material_override = wlmat
	add_child(warn_light)

	# Faint floor lights along corridor
	for tz in range(-8, 9, 2):
		var stripe := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(1.2, 0.16)
		stripe.mesh = sq
		stripe.rotation_degrees = Vector3(-90, 0, 0)
		stripe.position = Vector3(0, 0.02, tz)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.55, 0.62, 0.78, 0.4)
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.emission_enabled = true
		smat.emission = Color(0.55, 0.62, 0.78)
		smat.emission_energy_multiplier = 0.3
		stripe.material_override = smat
		add_child(stripe)

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _build_sparker(x: float, z: float) -> void:
	Chamber.make_prop_box(self, Vector3(0.30, 0.30, 0.20), Vector3(x, 1.5, z), Color(0.20, 0.22, 0.25))
	var glow := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.15, 0.10, 0.05)
	glow.mesh = gb
	glow.position = Vector3(x, 1.5, z - 0.13)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.86, 0.31, 0.4)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.86, 0.31)
	gmat.emission_energy_multiplier = 0.4
	glow.material_override = gmat
	add_child(glow)
	sparkers.append({
		"glow": glow,
		"timer": randf_range(0.0, 5.0),
		"next": randf_range(2.5, 6.0),
		"sparking": false,
		"spark_t": 0.0,
	})


func _process(dt: float) -> void:
	phase += dt
	# Sparkers
	for s in sparkers:
		s["timer"] += dt
		if not s["sparking"]:
			if s["timer"] >= s["next"]:
				s["sparking"] = true
				s["spark_t"] = 0.0
				var mat: StandardMaterial3D = s["glow"].material_override
				mat.emission_energy_multiplier = 2.0
		else:
			s["spark_t"] += dt
			if s["spark_t"] >= 0.18:
				s["sparking"] = false
				s["timer"] = 0.0
				s["next"] = randf_range(2.5, 6.0)
				var mat: StandardMaterial3D = s["glow"].material_override
				mat.emission_energy_multiplier = 0.4
	# Warning light pulse
	if warn_light:
		var v := 0.4 + 0.6 * (0.5 + 0.5 * sin(phase * 3.5))
		var mat: StandardMaterial3D = warn_light.material_override
		mat.emission_energy_multiplier = 0.3 + v

	if GameState.maint_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act9")
