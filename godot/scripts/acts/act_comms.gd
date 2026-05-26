extends Node3D
# ACT - COMMUNICATIONS / SERVER CORE (between the mess and the lab).
# Banks of servers humming in the dark. The transmitter dish is aimed inward,
# at the station, not out at the stars — whatever they were sending, they were
# sending it to themselves. The signal lives in these wires now.

const W := 14.0
const D := 14.0
const H := 3.8

var exit_open := false


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.40, 0.50, 0.58), Color(0.05, 0.09, 0.13), 0.015, 0.45,
		Color(0.55, 0.86, 0.96), 3.0, 12.0)
	ActUtil.add_dust_motes(self, Vector3(0, 1.7, 0), Vector3(6, 1.8, 6), 80,
		Color(0.70, 0.86, 0.94, 0.15))

	Chamber.add_floor_ceiling(self, W, D, H, Color(0.16, 0.19, 0.24), Color(0.08, 0.10, 0.14))
	var wall := Color(0.22, 0.25, 0.31)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "MESS", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "LAB", Color(0.28, 0.27, 0.23),
		func(): exit_open = true, "Open LAB")
	ActUtil.wall_label(self, "<-  MESS", Vector3(0, Chamber.DOOR_H + 0.12, -D/2 + 0.18), 14, Color(0.66, 0.80, 0.94))
	ActUtil.wall_label(self, "LAB  ->", Vector3(0, Chamber.DOOR_H + 0.12, D/2 - 0.18), 15, Color(0.66, 0.80, 0.94))
	ActUtil.wall_label(self, "COMMS / CORE", Vector3(-W/2 + 0.10, 2.7, -3.0), 16, Color(0.55, 0.85, 0.96))

	# Two rows of server racks down the sides.
	for sz in [-4.6, -2.0, 1.4, 4.0]:
		_server_rack(-4.7, sz, true)
		_server_rack(4.7, sz, false)
	ActUtil.add_ceiling_pipes(self, W, D, H)

	# The transmitter dish, slung from the ceiling and tilted to face inward.
	var dish := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 1.0
	dc.bottom_radius = 0.18
	dc.height = 0.5
	dish.mesh = dc
	dish.position = Vector3(0, 3.0, -1.0)
	dish.rotation_degrees = Vector3(148, 0, 0)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	dm.albedo_color = Color(0.20, 0.22, 0.27)
	dm.metallic = 0.6
	dm.roughness = 0.4
	dish.material_override = dm
	add_child(dish)
	var emitter := MeshInstance3D.new()
	var eq := SphereMesh.new()
	eq.radius = 0.10
	eq.height = 0.20
	emitter.mesh = eq
	emitter.position = Vector3(0, 2.75, -1.05)
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_color = Color(0.95, 0.12, 0.10)
	em.emission_enabled = true
	em.emission = Color(0.95, 0.12, 0.10)
	em.emission_energy_multiplier = 2.6
	emitter.material_override = em
	add_child(emitter)
	ActUtil.add_omni(self, Vector3(0, 2.6, -1.0), Color(0.95, 0.20, 0.16), 1.4, 6.0, false)

	# Comms console against the west wall, with the orientation log.
	var console := Chamber.make_prop_box(self, Vector3(1.8, 1.0, 0.7), Vector3(-5.6, 0.5, 5.0), Color(0.18, 0.21, 0.27))
	Chamber.make_prop_box(self, Vector3(1.4, 0.35, 0.30), Vector3(-5.6, 0.85, 4.7), Color(0.12, 0.14, 0.18), false)
	var scr := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(1.2, 0.6)
	scr.mesh = sq
	scr.position = Vector3(-5.55, 1.35, 5.30)
	scr.rotation_degrees = Vector3(0, 90, 0)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	sm.albedo_color = Color(0.05, 0.12, 0.10)
	sm.emission_enabled = true
	sm.emission = Color(0.20, 0.78, 0.55)
	sm.emission_energy_multiplier = 0.5
	scr.material_override = sm
	add_child(scr)
	ActUtil.screen_label(self, "TX ORIENTATION:\n* INWARD *\nUPLINK: FAILED x412", Vector3(-5.50, 1.35, 5.30), 90, 13, Color(0.55, 0.92, 0.70))
	Interactable.attach(console, "Read the comms log", "examine_only", {
		"text": "COMMS CORE - TRANSMITTER LOG\n----------------------------\nUplink attempts:  412.  All failed.\nDish orientation:  INWARD.  Locked.\nLast manual override:  (none on record)\n\nThe dish has been pointed back at the station since before any of you arrived.  Every message you ever tried to send home, you sent into yourselves.  412 times.  412 little doors, held open one after another.",
		"duration": 12.0,
	})

	# Cable bundles draped from the ceiling.
	for cz in [-3.0, 0.5, 3.5]:
		Chamber.make_prop_box(self, Vector3(0.08, 1.0, 0.08), Vector3(randf_range(-2.0, 2.0), H - 0.6, cz), Color(0.14, 0.14, 0.18), false)

	# --- Horror dressing -------------------------------------------------
	ActUtil.corpse(self, Vector3(-4.7, 0, 4.6), 120)
	ActUtil.blood_trail(self, Vector3(-2.4, 0, 3.0), Vector3(-4.4, 0, 4.4), 6)
	ActUtil.signal_growth(self, Vector3(-4.7, 1.2, -4.6), 1.3)
	ActUtil.signal_growth(self, Vector3(4.7, 1.2, 1.4), 1.2)
	ActUtil.viscera(self, Vector3(4.6, 0, -5.2))
	ActUtil.bloody_smears(self, Vector3(6.92, 2.0, -2.0), -90, 4)
	ActUtil.wall_scrawl(self, "STOP\nSENDING", Vector3(6.92, 2.0, 3.0), -90, 40)
	ActUtil.add_peeker(self, Vector3(-5.4, 0, -5.4), HorrorShape.KIND_FELIX, 30)

	ActUtil.haunt(self, {
		"intensity": 0.50,
		"lurkers": [{"kind": "felix", "points": [
			Vector3(-5, 0, 3), Vector3(5, 0, 3), Vector3(-5, 0, -4), Vector3(5, 0, -4)], "creep": 0.8}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _server_rack(x: float, z: float, face_east: bool) -> void:
	Chamber.make_prop_box(self, Vector3(1.0, 2.8, 1.2), Vector3(x, 1.4, z), Color(0.13, 0.14, 0.18))
	var fx := x + (0.52 if face_east else -0.52)
	for li in 9:
		var on := randf() < 0.7
		var led := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.05, 0.05, 0.02)
		led.mesh = lb
		led.position = Vector3(fx, 0.5 + li * 0.27, z + randf_range(-0.42, 0.42))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		var c := Color(0.20, 0.86, 0.42) if on else Color(0.24, 0.06, 0.06)
		m.albedo_color = c
		if on:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = 0.9
		led.material_override = m
		add_child(led)


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act5")
