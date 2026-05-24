extends Node3D
# ACT 7 - ENGINEERING / POWER CORE.
# 18x20 reactor bay, central reactor cylinder, catwalk, coolant tanks,
# calibration panel with Note 11 (maintenance tape).

const W := 18.0
const D := 20.0
const H := 4.6

var core: MeshInstance3D = null
var warn_bulb: MeshInstance3D = null
var phase := 0.0


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.55, 0.62, 0.70), Color(0.10, 0.14, 0.18), 0.020, 0.55)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.27, 0.29, 0.31), Color(0.14, 0.16, 0.18))
	var wall := Color(0.27, 0.31, 0.37)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "HYDRO", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "STORAGE", Color(0.28, 0.27, 0.23),
		func(): GameState.engineering_door_open = true, "Open STORAGE")

	# Central reactor housing — segmented industrial cylinder with bolts and panels
	var housing := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.7
	cyl.height = H - 0.4
	housing.mesh = cyl
	housing.position = Vector3(0, (H - 0.4) / 2, 0)
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	hmat.albedo_color = Color(0.36, 0.36, 0.40)
	hmat.metallic = 0.75
	hmat.roughness = 0.45
	housing.material_override = hmat
	add_child(housing)
	# Collider for housing
	var hbody := StaticBody3D.new()
	var hshape := CollisionShape3D.new()
	var hcyl := CylinderShape3D.new()
	hcyl.radius = 1.7
	hcyl.height = H - 0.4
	hshape.shape = hcyl
	hbody.add_child(hshape)
	hbody.position = Vector3(0, (H - 0.4) / 2, 0)
	add_child(hbody)

	# Riveted hoop bands at 4 heights
	for hy in [0.45, 1.30, 2.20, 3.30]:
		var hoop := MeshInstance3D.new()
		var hb := CylinderMesh.new()
		hb.top_radius = 1.74
		hb.bottom_radius = 1.74
		hb.height = 0.10
		hoop.mesh = hb
		hoop.position = Vector3(0, hy, 0)
		var hpm := StandardMaterial3D.new()
		hpm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		hpm.albedo_color = Color(0.20, 0.22, 0.26)
		hpm.metallic = 0.85
		hpm.roughness = 0.40
		hoop.material_override = hpm
		add_child(hoop)
		# Rivet bumps around each hoop
		for ang_i in range(16):
			var ang: float = ang_i * TAU / 16.0
			var rivet := MeshInstance3D.new()
			var rb := SphereMesh.new()
			rb.radius = 0.05
			rb.height = 0.10
			rivet.mesh = rb
			rivet.position = Vector3(cos(ang) * 1.78, hy, sin(ang) * 1.78)
			var rm := StandardMaterial3D.new()
			rm.albedo_color = Color(0.55, 0.55, 0.59)
			rm.metallic = 0.9
			rm.roughness = 0.35
			rivet.material_override = rm
			add_child(rivet)

	# Yellow hazard band at the base
	var band := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 1.76
	bcyl.bottom_radius = 1.76
	bcyl.height = 0.30
	band.mesh = bcyl
	band.position = Vector3(0, 0.20, 0)
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	bmat.albedo_color = Color(0.86, 0.70, 0.12)
	bmat.emission_enabled = true
	bmat.emission = Color(0.86, 0.70, 0.12)
	bmat.emission_energy_multiplier = 0.4
	band.material_override = bmat
	add_child(band)

	# Coolant hoses running from the housing to the wall tanks (east)
	for hi in [-0.6, 0.0, 0.6]:
		var pipe_a := MeshInstance3D.new()
		var pa := BoxMesh.new()
		pa.size = Vector3(W/2 - 1.7, 0.12, 0.12)
		pipe_a.mesh = pa
		pipe_a.position = Vector3(W/4 + 0.4, 1.7 + hi, hi)
		var pam := StandardMaterial3D.new()
		pam.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		pam.albedo_color = Color(0.40, 0.25, 0.16) if hi > 0 else Color(0.20, 0.30, 0.45)
		pam.metallic = 0.4
		pam.roughness = 0.55
		pipe_a.material_override = pam
		add_child(pipe_a)

	# Gauge cluster on the housing (south face)
	for gi in 4:
		var gx: float = -0.6 + gi * 0.4
		var gauge := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.14
		gm.bottom_radius = 0.14
		gm.height = 0.04
		gauge.mesh = gm
		gauge.rotation_degrees = Vector3(90, 0, 0)
		gauge.position = Vector3(gx, 1.85, -1.72)
		var gmat := StandardMaterial3D.new()
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		gmat.albedo_color = Color(0.94, 0.92, 0.86)
		gauge.material_override = gmat
		add_child(gauge)
		# Gauge needle
		var needle := MeshInstance3D.new()
		var nb := BoxMesh.new()
		nb.size = Vector3(0.02, 0.10, 0.005)
		needle.mesh = nb
		needle.position = Vector3(gx, 1.85, -1.74)
		needle.rotation_degrees = Vector3(0, 0, randf_range(-50, 50))
		var nm := StandardMaterial3D.new()
		nm.albedo_color = Color(0.86, 0.16, 0.12)
		nm.emission_enabled = true
		nm.emission = Color(0.86, 0.16, 0.12)
		nm.emission_energy_multiplier = 0.6
		needle.material_override = nm
		add_child(needle)

	# Valve wheel on top of housing
	for vi in [Vector3(0.9, H - 0.6, -0.6), Vector3(-0.9, H - 0.6, 0.6)]:
		var stem := MeshInstance3D.new()
		var sb := CylinderMesh.new()
		sb.top_radius = 0.05
		sb.bottom_radius = 0.05
		sb.height = 0.30
		stem.mesh = sb
		stem.position = vi
		var stm := StandardMaterial3D.new()
		stm.albedo_color = Color(0.16, 0.18, 0.22)
		stm.metallic = 0.7
		stem.material_override = stm
		add_child(stem)
		var wheel := MeshInstance3D.new()
		var wb := CylinderMesh.new()
		wb.top_radius = 0.22
		wb.bottom_radius = 0.22
		wb.height = 0.05
		wheel.mesh = wb
		wheel.position = vi + Vector3(0, 0.18, 0)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.78, 0.20, 0.16)
		wmat.metallic = 0.6
		wmat.roughness = 0.40
		wheel.material_override = wmat
		add_child(wheel)
		# Spokes
		for sp in 4:
			var spoke := MeshInstance3D.new()
			var spb := BoxMesh.new()
			spb.size = Vector3(0.40, 0.03, 0.04)
			spoke.mesh = spb
			spoke.position = vi + Vector3(0, 0.18, 0)
			spoke.rotation_degrees = Vector3(0, sp * 45, 0)
			var spm := StandardMaterial3D.new()
			spm.albedo_color = Color(0.20, 0.20, 0.22)
			spoke.material_override = spm
			add_child(spoke)

	# Pulsing core sphere above
	core = MeshInstance3D.new()
	var csphere := SphereMesh.new()
	csphere.radius = 1.2
	csphere.height = 2.4
	core.mesh = csphere
	core.position = Vector3(0, H - 1.4, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.47, 0.62, 0.78)
	cmat.emission_enabled = true
	cmat.emission = Color(0.47, 0.62, 0.78)
	cmat.emission_energy_multiplier = 1.4
	core.material_override = cmat
	add_child(core)

	# Catwalk ring (4 segments)
	var ring_outer := 4.0
	var ring_y := 1.40
	for cz in [-ring_outer, ring_outer]:
		Chamber.make_prop_box(self, Vector3(2 * ring_outer + 0.4, 0.20, 0.6), Vector3(0, ring_y, cz), Color(0.33, 0.35, 0.39))
	for cx in [-ring_outer, ring_outer]:
		Chamber.make_prop_box(self, Vector3(0.6, 0.20, 2 * ring_outer + 0.4), Vector3(cx, ring_y, 0), Color(0.33, 0.35, 0.39))
	# Outer hand rails (yellow)
	for cfg in [[0.0, -ring_outer - 0.3, 2 * ring_outer + 0.4, 0.05],
				[0.0, ring_outer + 0.3, 2 * ring_outer + 0.4, 0.05],
				[-ring_outer - 0.3, 0.0, 0.05, 2 * ring_outer + 0.4],
				[ring_outer + 0.3, 0.0, 0.05, 2 * ring_outer + 0.4]]:
		Chamber.make_prop_box(self, Vector3(cfg[2], 1.0, cfg[3]), Vector3(cfg[0], ring_y + 0.6, cfg[1]), Color(0.70, 0.59, 0.16))

	# Calibration maintenance panel (west wall)
	var panel := Chamber.make_prop_box(self, Vector3(1.5, 1.1, 0.10), Vector3(-W/2 + 0.10, 1.5, -4.0), Color(0.23, 0.27, 0.31))
	var screen := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(1.30, 0.90)
	screen.mesh = sq
	screen.position = Vector3(-W/2 + 0.17, 1.5, -4.0)
	screen.rotation_degrees = Vector3(0, 90, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.06, 0.12, 0.20)
	smat.emission_enabled = true
	smat.emission = Color(0.78, 0.90, 0.98)
	smat.emission_energy_multiplier = 0.3
	screen.material_override = smat
	add_child(screen)
	ActUtil.wall_label(self, "CALIBRATION 442-K\n\nARRAY  =  0.7 P-UNITS\nSTATUS =  ACTIVE\n\n*** READ TAPE ***",
		Vector3(-W/2 + 0.22, 1.5, -4.0), 18, Color(0.78, 0.90, 0.98))

	# Note 11 - maintenance tape on shelf below the panel
	Interactable.make_note(self, Vector3(-W/2 + 0.55, 0.85, -4.0), "note_11", "Play tape")

	# Two secondary panels
	for cfg in [[-1.0, "PROPULSION\n  THRUST    0.0 kN\n  STATUS    STBY"],
				[2.0, "LIFE SUPPORT\n  O2        NOMINAL\n  CO2 SCR.  NOMINAL\n  THERMAL   NOMINAL"]]:
		var panel_z: float = cfg[0]
		var ptext: String = cfg[1]
		Chamber.make_prop_box(self, Vector3(1.5, 1.0, 0.10), Vector3(-W/2 + 0.10, 1.5, panel_z), Color(0.22, 0.25, 0.29))
		var s2 := MeshInstance3D.new()
		var q2 := QuadMesh.new()
		q2.size = Vector2(1.30, 0.80)
		s2.mesh = q2
		s2.position = Vector3(-W/2 + 0.17, 1.5, panel_z)
		s2.rotation_degrees = Vector3(0, 90, 0)
		var sm2 := StandardMaterial3D.new()
		sm2.albedo_color = Color(0.06, 0.12, 0.16)
		sm2.emission_enabled = true
		sm2.emission = Color(0.63, 0.86, 0.71)
		sm2.emission_energy_multiplier = 0.3
		s2.material_override = sm2
		add_child(s2)
		ActUtil.wall_label(self, ptext, Vector3(-W/2 + 0.22, 1.5, panel_z),
			14, Color(0.63, 0.86, 0.71))

	# Coolant tanks along east wall
	for cfg2 in [[-5.0, "COOL A"], [-1.0, "COOL B"], [3.0, "COOL C"], [6.0, "COOL D"]]:
		_build_coolant_tank(W/2 - 1.0, cfg2[0], cfg2[1])

	# Pipes along east wall
	Chamber.make_prop_box(self, Vector3(0.20, 0.20, 13.0), Vector3(W/2 - 0.30, 0.40, 0), Color(0.55, 0.43, 0.23), false)
	Chamber.make_prop_box(self, Vector3(0.20, 0.20, 13.0), Vector3(W/2 - 0.50, 0.80, 0), Color(0.23, 0.31, 0.43), false)

	# Tool bench (NW)
	var bench := Chamber.make_prop_box(self, Vector3(2.0, 0.85, 0.7), Vector3(-W/2 + 1.6, 0.42, 5.5), Color(0.31, 0.31, 0.35))
	Chamber.make_prop_box(self, Vector3(0.06, 0.04, 0.55), Vector3(-W/2 + 1.2, 0.87, 5.5), Color(0.70, 0.73, 0.76), false)
	Chamber.make_prop_box(self, Vector3(0.30, 0.10, 0.20), Vector3(-W/2 + 1.8, 0.92, 5.5), Color(0.86, 0.70, 0.23), false)
	Chamber.make_prop_box(self, Vector3(0.24, 0.20, 0.24), Vector3(-W/2 + 2.3, 0.95, 5.6), Color(0.70, 0.20, 0.16), false)
	Interactable.attach(bench, "Look at the tool bench", "examine_only", {
		"text": "Hargrove's tool bench.  Wrench, multimeter, spool of red wire.  A small framed photo at the back: two children, smiling, one holding a fishing pole.  Behind the photo a folded note that reads 'do better.'",
		"duration": 6.0,
	})

	# Hargrove's chair
	var chair := Chamber.make_prop_box(self, Vector3(0.5, 0.4, 0.5), Vector3(-W/2 + 1.8, 0.20, -3.6), Color(0.16, 0.18, 0.22))
	Chamber.make_prop_box(self, Vector3(1.0, 1.4, 0.10), Vector3(-W/2 + 1.8, 1.10, -4.05), Color(0.16, 0.18, 0.22), false)
	# Coat
	Chamber.make_prop_box(self, Vector3(0.9, 0.90, 0.20), Vector3(-W/2 + 1.8, 0.50, -3.80), Color(0.31, 0.23, 0.16), false)

	# Corner plant - leaves point east
	var corner_pot := Chamber.make_prop_box(self, Vector3(0.35, 0.35, 0.35), Vector3(W/2 - 1.5, 0.17, D/2 - 1.2), Color(0.47, 0.39, 0.31))
	# Stalk leaning east
	var stalk := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.08, 2.4, 0.08)
	stalk.mesh = sb
	stalk.position = Vector3(W/2 - 1.7, 1.4, D/2 - 1.2)
	stalk.rotation_degrees = Vector3(0, 0, 18)
	var stmat := StandardMaterial3D.new()
	stmat.albedo_color = Color(0.27, 0.39, 0.25)
	stalk.material_override = stmat
	add_child(stalk)
	# Foliage
	var foliage := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.35
	fm.height = 0.70
	foliage.mesh = fm
	foliage.position = Vector3(W/2 - 2.0, 2.0, D/2 - 0.6)
	var folmat := StandardMaterial3D.new()
	folmat.albedo_color = Color(0.31, 0.51, 0.31)
	foliage.material_override = folmat
	add_child(foliage)
	Interactable.attach(corner_pot, "Look at the plant", "examine_only", {
		"text": "Every leaf points east.  Toward the array.  Even the ones in shadow.",
		"duration": 4.0,
	})

	# Conduit + cables on ceiling
	for tz in range(-8, 9, 4):
		Chamber.make_prop_box(self, Vector3(W - 1, 0.10, 0.15), Vector3(0, H - 0.20, tz), Color(0.20, 0.24, 0.29), false)

	# Warning light near entry
	Chamber.make_prop_box(self, Vector3(0.30, 0.18, 0.30), Vector3(0, H - 0.15, -D/2 + 1.5), Color(0.16, 0.16, 0.20))
	warn_bulb = MeshInstance3D.new()
	var ws := SphereMesh.new()
	ws.radius = 0.21
	ws.height = 0.42
	warn_bulb.mesh = ws
	warn_bulb.position = Vector3(0, H - 0.35, -D/2 + 1.5)
	var wbmat := StandardMaterial3D.new()
	wbmat.albedo_color = Color(0.86, 0.70, 0.23)
	wbmat.emission_enabled = true
	wbmat.emission = Color(0.86, 0.70, 0.23)
	wbmat.emission_energy_multiplier = 0.6
	warn_bulb.material_override = wbmat
	add_child(warn_bulb)

	# EXIT sign — emissive backplate + readable text
	var exit_box := MeshInstance3D.new()
	var ebm := BoxMesh.new()
	ebm.size = Vector3(0.06, 0.30, 0.80)
	exit_box.mesh = ebm
	exit_box.position = Vector3(W/2 - 0.10, 2.4, 6.5)
	var ebmat := StandardMaterial3D.new()
	ebmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	ebmat.albedo_color = Color(0.05, 0.20, 0.09)
	ebmat.emission_enabled = true
	ebmat.emission = Color(0.18, 0.92, 0.32)
	ebmat.emission_energy_multiplier = 1.4
	exit_box.material_override = ebmat
	add_child(exit_box)
	ActUtil.wall_label(self, "EXIT", Vector3(W/2 - 0.18, 2.4, 6.5), 26,
		Color(0.06, 0.06, 0.08), Color(0.55, 1.0, 0.65, 0.9))

	# Ceiling pipes already partially exist, add more atmospheric clutter
	ActUtil.add_ceiling_pipes(self, W, D, H)
	# Floor decals around the reactor
	ActUtil.add_floor_decals(self, W, D, Vector3.ZERO, Color(0.86, 0.86, 0.16, 0.6))
	# Wall vents
	ActUtil.wall_vent(self, "x", W/2 - 0.05, 8.0, 3.0, Vector2(0.7, 0.5))
	ActUtil.wall_vent(self, "x", -W/2 + 0.05, 8.0, 3.0, Vector2(0.7, 0.5))

	# Signage above the doors
	ActUtil.wall_label(self, "<-  HYDROPONICS",
		Vector3(0, Chamber.DOOR_H + 0.30, -D/2 + 0.18), 16, Color(0.55, 0.95, 0.65))
	ActUtil.wall_label(self, "STORAGE  ->",
		Vector3(0, Chamber.DOOR_H + 0.30, D/2 - 0.18), 16, Color(0.62, 0.78, 0.94))

	# Power cable thicket leading from reactor base to east wall
	for ci in 4:
		Chamber.make_prop_box(self, Vector3(W/2 - 2.0, 0.10, 0.08),
			Vector3(W/4, 0.06, -1.0 + ci * 0.30),
			Color(0.14, 0.14, 0.18), false)

	# A workbench-mounted vise on the tool bench
	Chamber.make_prop_box(self, Vector3(0.18, 0.16, 0.14), Vector3(-W/2 + 1.0, 0.93, 5.5), Color(0.55, 0.55, 0.59), false)

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _build_coolant_tank(x: float, z: float, label_text: String) -> void:
	# Base
	Chamber.make_prop_box(self, Vector3(0.8, 0.20, 0.8), Vector3(x, 0.10, z), Color(0.23, 0.25, 0.29))
	# Body
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 3.0
	body.mesh = cyl
	body.position = Vector3(x, 1.7, z)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.70, 0.70, 0.74)
	body.material_override = bmat
	add_child(body)
	# Collider
	var col := StaticBody3D.new()
	col.position = Vector3(x, 1.7, z)
	var cs := CollisionShape3D.new()
	var ccyl := CylinderShape3D.new()
	ccyl.radius = 0.4
	ccyl.height = 3.0
	cs.shape = ccyl
	col.add_child(cs)
	add_child(col)
	# Top cap
	var cap := MeshInstance3D.new()
	var capmesh := SphereMesh.new()
	capmesh.radius = 0.42
	capmesh.height = 0.5
	cap.mesh = capmesh
	cap.position = Vector3(x, 3.20, z)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.55, 0.57, 0.61)
	cap.material_override = cap_mat
	add_child(cap)
	# Yellow label band
	var band := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.42
	bm.bottom_radius = 0.42
	bm.height = 0.2
	band.mesh = bm
	band.position = Vector3(x, 1.50, z)
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.86, 0.70, 0.12)
	band.material_override = band_mat
	add_child(band)
	# Label text — billboard so it reads from the room centre regardless of approach
	ActUtil.wall_label(self, label_text, Vector3(x - 0.45, 1.50, z), 18,
		Color(0.18, 0.12, 0.06), Color(1, 0.95, 0.8, 0.7))


func _process(dt: float) -> void:
	# Core breathing
	phase += dt
	if core:
		var v := 0.5 + 0.5 * sin(phase * 0.7)
		var mat: StandardMaterial3D = core.material_override
		var bch := int(140 + 80 * v)
		mat.emission = Color(0.43, 0.62, bch / 255.0)
	# Warning bulb pulse
	if warn_bulb:
		var v := 0.4 + 0.6 * (0.5 + 0.5 * sin(phase * 1.6))
		var mat: StandardMaterial3D = warn_bulb.material_override
		mat.emission = Color(0.86 * v, 0.70 * v, 0.23 * v)
		mat.emission_energy_multiplier = 0.4 + 0.6 * v

	if GameState.engineering_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_storage")
