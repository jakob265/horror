extends Node3D
# ACT - MAINTENANCE CRAWL.
# Tight low-ceiling service shaft between bridge and approach.
# Sparking junction boxes, exposed conduit, Note 18.

const W := 4.5
const D := 20.0
const H := 2.2

var sparkers: Array[Dictionary] = []
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

	# Extra maintenance clutter — tool cart, oil drum, dropped wrench
	# Toolbox cart against the west wall
	Chamber.make_prop_box(self, Vector3(0.45, 0.45, 0.65), Vector3(-W/2 + 0.5, 0.22, 5.0), Color(0.62, 0.51, 0.27))
	for hdy in [0.20, 0.46]:
		Chamber.make_prop_box(self, Vector3(0.42, 0.06, 0.06), Vector3(-W/2 + 0.5, hdy, 4.72), Color(0.30, 0.27, 0.23), false)
	# Oil drum
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.30
	dm.bottom_radius = 0.30
	dm.height = 0.90
	drum.mesh = dm
	drum.position = Vector3(W/2 - 0.6, 0.45, -7.0)
	var drmat := StandardMaterial3D.new()
	drmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	drmat.albedo_color = Color(0.62, 0.27, 0.20)
	drmat.metallic = 0.7
	drmat.roughness = 0.45
	drum.material_override = drmat
	add_child(drum)
	# Drum band
	for db in [0.30, 0.60]:
		var dband := MeshInstance3D.new()
		var dbcyl := CylinderMesh.new()
		dbcyl.top_radius = 0.32
		dbcyl.bottom_radius = 0.32
		dbcyl.height = 0.04
		dband.mesh = dbcyl
		dband.position = Vector3(W/2 - 0.6, db, -7.0)
		var dbmat := StandardMaterial3D.new()
		dbmat.albedo_color = Color(0.16, 0.16, 0.18)
		dbmat.metallic = 0.6
		dband.material_override = dbmat
		add_child(dband)
	# Yellow hazard band
	var hazb := MeshInstance3D.new()
	var hazc := CylinderMesh.new()
	hazc.top_radius = 0.32
	hazc.bottom_radius = 0.32
	hazc.height = 0.18
	hazb.mesh = hazc
	hazb.position = Vector3(W/2 - 0.6, 0.78, -7.0)
	var hazmat := StandardMaterial3D.new()
	hazmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	hazmat.albedo_color = Color(0.86, 0.70, 0.16)
	hazmat.emission_enabled = true
	hazmat.emission = Color(0.86, 0.70, 0.16)
	hazmat.emission_energy_multiplier = 0.25
	hazb.material_override = hazmat
	add_child(hazb)
	# Dropped wrench on the floor
	Chamber.make_prop_box(self, Vector3(0.06, 0.04, 0.32), Vector3(0.4, 0.04, 2.0), Color(0.66, 0.69, 0.75), false)
	# Coiled hose against east wall
	Chamber.make_prop_box(self, Vector3(0.40, 0.40, 0.40), Vector3(W/2 - 0.6, 0.20, -2.5), Color(0.16, 0.16, 0.18))
	# Wall-mounted gauge cluster
	for gi in 3:
		var gx: float = -W/2 + 0.12
		var gy: float = 1.7
		var gz: float = -3.5 + gi * 0.4
		var gauge := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.10
		gm.bottom_radius = 0.10
		gm.height = 0.04
		gauge.mesh = gm
		gauge.rotation_degrees = Vector3(0, 0, 90)
		gauge.position = Vector3(gx, gy, gz)
		var gmat2 := StandardMaterial3D.new()
		gmat2.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		gmat2.albedo_color = Color(0.92, 0.90, 0.86)
		gauge.material_override = gmat2
		add_child(gauge)
	# Dust motes for the cramped vent atmosphere
	ActUtil.add_dust_motes(self, Vector3(0, 1.4, 0), Vector3(2.0, 0.8, 8.0), 60,
		Color(0.82, 0.84, 0.88, 0.18))

	# Environmental dread in the crawl.
	ActUtil.blood_decal(self, Vector3(0.3, 0.02, 1.0), Vector2(0.7, 1.0))
	ActUtil.blood_decal(self, Vector3(-0.5, 0.02, 4.0), Vector2(0.6, 0.9))
	ActUtil.wall_scrawl(self, "IT IS\nME NOW", Vector3(-2.15, 1.5, 4.0), 90, 34)

	# Tight, dark service crawl — the stalker is right on top of you here.
	ActUtil.haunt(self, {
		"intensity": 0.78,
		"flicker_rate": 1.4,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(0, 0, 8), Vector3(0, 0, 2), Vector3(1.2, 0, -3), Vector3(-1.2, 0, 5)], "creep": 0.85}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)
	# Once you're a few steps into the crawl, something is suddenly there.
	get_tree().create_timer(5.0).timeout.connect(func(): ScareDirector.jump_scare())


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
