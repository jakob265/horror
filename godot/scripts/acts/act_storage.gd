extends Node3D
# ACT - SECONDARY CRYO STORAGE.
# 10 pods in two rows. 4 cycling (SATO, OKAFOR, HARGROVE, PARK). V-05 (VOSS) open and waiting.
# Note 17 - Sato's tech log. Wall plaque with crew manifest.

const W := 14.0
const D := 22.0
const H := 3.6

var pod_lights: Array = []
var phase := 0.0


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.43, 0.51, 0.62), Color(0.08, 0.10, 0.16), 0.022, 0.5)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.18, 0.22, 0.27), Color(0.08, 0.10, 0.14))
	var wall := Color(0.22, 0.25, 0.33)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "ENGINEERING", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "BRIDGE", Color(0.28, 0.27, 0.23),
		func(): GameState.storage_door_open = true, "Open BRIDGE")

	# Two rows of 5 pods
	var west_x := -3.5
	var east_x := 3.5
	var pod_zs := [-8.0, -4.0, 0.0, 4.0, 8.0]
	var west_labels := ["V-06", "V-07", "V-08", "V-09", "V-10"]
	var east_labels := ["SATO", "OKAFOR", "HARGROVE", "PARK", "VOSS"]

	for i in pod_zs.size():
		_build_pod(west_x, pod_zs[i], west_labels[i], false, false)
	for i in pod_zs.size():
		var label_str: String = east_labels[i]
		var opened := label_str == "VOSS"
		_build_pod(east_x, pod_zs[i], label_str, not opened, opened)

	# Console at south end with tape (Note 17)
	var console := Chamber.make_prop_box(self, Vector3(2.0, 1.0, 0.8), Vector3(0, 0.50, -D/2 + 1.4), Color(0.20, 0.24, 0.29))
	var scr := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(1.4, 0.7)
	scr.mesh = sq
	scr.position = Vector3(0, 0.80, -D/2 + 0.99)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.06, 0.16, 0.20)
	sm.emission_enabled = true
	sm.emission = Color(0.55, 0.86, 0.78)
	sm.emission_energy_multiplier = 0.3
	scr.material_override = sm
	add_child(scr)
	var slabel := Label3D.new()
	slabel.text = "CRYO STORAGE - CRESTFALL-9\n10 pods.  4 cycling.  1 staged.  5 dark.\n\n*** PLAY TECH LOG ***"
	slabel.position = Vector3(0, 0.80, -D/2 + 0.97)
	slabel.font_size = 20
	slabel.modulate = Color(0.55, 0.86, 0.78)
	add_child(slabel)
	# Tape
	Interactable.make_note(self, Vector3(0, 1.08, -D/2 + 1.0), "note_17", "Play tech tape")

	# Centre aisle floor lights
	for fz in range(-9, 10, 3):
		var stripe := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.6, 0.18)
		stripe.mesh = q
		stripe.rotation_degrees = Vector3(-90, 0, 0)
		stripe.position = Vector3(0, 0.02, fz)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.66, 0.82, 0.94)
		smat.emission_enabled = true
		smat.emission = Color(0.66, 0.82, 0.94)
		smat.emission_energy_multiplier = 0.5
		stripe.material_override = smat
		add_child(stripe)

	# Overhead conduit / pipes
	for tz in range(-9, 10, 4):
		Chamber.make_prop_box(self, Vector3(W - 0.6, 0.14, 0.18), Vector3(0, H - 0.35, tz), Color(0.16, 0.20, 0.25), false)
		Chamber.make_prop_box(self, Vector3(W - 0.6, 0.10, 0.14), Vector3(0, H - 0.60, tz + 0.5), Color(0.31, 0.27, 0.20), false)

	# Workstation between pods with duty roster
	var bench := Chamber.make_prop_box(self, Vector3(1.4, 0.85, 0.6), Vector3(0, 0.42, -6), Color(0.23, 0.27, 0.33))
	Interactable.attach(bench, "Read the duty roster", "examine_only", {
		"text": "CRYO STORAGE DUTY ROSTER\nTech of record:  K. SATO\n\nCycle 0079:  V-01 prep.   (Sato)\nCycle 0080:  V-02 prep.   (Sato)\nCycle 0081:  V-03 prep.   (Sato)\nCycle 0082:  V-04 prep.   (Sato)\nCycle 0083:  V-05 prep.   (VOSS, in own hand)\nCycle 0084:  V-05 commit. (VOSS, in own hand)\n\nThe last two entries are in your handwriting.\nYou do not remember writing them.",
		"duration": 10.0,
	})

	# Wall plaque on north wall above exit door
	var plaque := Chamber.make_prop_box(self, Vector3(2.0, 0.40, 0.06), Vector3(0, H - 0.5, D/2 - 0.10), Color(0.55, 0.43, 0.27))
	Interactable.attach(plaque, "Read the manifest plaque", "examine_only", {
		"text": "The official crew manifest plaque.  All five names engraved in brass.  The first four are familiar.\n\nSATO.  Kenji Sato.  Station technician.  You stare at the name and feel exactly nothing.  You are sure he was here.  His handwriting was on the duty roster.  His pod is cycling four feet to your left.\n\nThe signal has been eating the spaces where memories used to be.  You should have noticed when the first one went missing.  You did not.  You did not notice.",
		"duration": 12.0,
	})
	var plaque_lbl := Label3D.new()
	plaque_lbl.text = "CRESTFALL-9   CREW MANIFEST\nVOSS  OKAFOR  PARK  HARGROVE  SATO"
	plaque_lbl.position = Vector3(0, H - 0.5, D/2 - 0.14)
	plaque_lbl.font_size = 16
	plaque_lbl.modulate = Color(0.16, 0.12, 0.08)
	add_child(plaque_lbl)

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _build_pod(x: float, z: float, label_str: String, occupied: bool, opened: bool) -> void:
	# Body
	var pod := Chamber.make_prop_box(self, Vector3(1.0, 0.9, 2.6), Vector3(x, 0.50, z), Color(0.27, 0.31, 0.37))
	# End caps
	for dz in [-1.30, 1.30]:
		var cap := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.35
		cm.height = 0.40
		cap.mesh = cm
		cap.position = Vector3(x, 0.50, z + dz)
		cap.scale = Vector3(1, 1, 1)
		var capmat := StandardMaterial3D.new()
		capmat.albedo_color = Color(0.23, 0.27, 0.33)
		cap.material_override = capmat
		add_child(cap)

	if not opened:
		# Window on top
		var win := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.65, 0.10, 1.8)
		win.mesh = wb
		win.position = Vector3(x, 1.00, z)
		var wmat := StandardMaterial3D.new()
		if occupied:
			wmat.albedo_color = Color(0.55, 0.78, 0.90, 0.85)
		else:
			wmat.albedo_color = Color(0.20, 0.24, 0.31, 0.85)
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wmat.emission_enabled = true
		wmat.emission = Color(0.55, 0.78, 0.90)
		wmat.emission_energy_multiplier = 0.2 if occupied else 0.0
		win.material_override = wmat
		add_child(win)
	else:
		# Opened lid lifted
		var lid := Chamber.make_prop_box(self, Vector3(0.95, 0.10, 2.40), Vector3(x, 1.45, z - 0.6), Color(0.23, 0.27, 0.33))
		lid.rotation_degrees = Vector3(-22, 0, 0)
		# Inner glow
		var inner := MeshInstance3D.new()
		var ib := BoxMesh.new()
		ib.size = Vector3(0.80, 0.04, 2.10)
		inner.mesh = ib
		inner.position = Vector3(x, 0.96, z)
		var imat := StandardMaterial3D.new()
		imat.albedo_color = Color(0.31, 0.62, 0.78)
		imat.emission_enabled = true
		imat.emission = Color(0.31, 0.62, 0.78)
		imat.emission_energy_multiplier = 0.6
		inner.material_override = imat
		add_child(inner)

	# Name plate
	var plate_lbl := Label3D.new()
	plate_lbl.text = label_str
	plate_lbl.position = Vector3(x + 0.55, 0.60, z - 0.5)
	plate_lbl.rotation_degrees = Vector3(0, 90, 0)
	plate_lbl.font_size = 22
	plate_lbl.modulate = Color(0.16, 0.12, 0.08)
	add_child(plate_lbl)

	# Status light
	var light := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.12, 0.04, 0.04)
	light.mesh = lb
	light.position = Vector3(x + 0.30, 0.96, z + 1.10)
	var lmat := StandardMaterial3D.new()
	if opened:
		lmat.albedo_color = Color(0.31, 0.62, 0.78)
		lmat.emission_enabled = true
		lmat.emission = Color(0.31, 0.62, 0.78)
	elif occupied:
		lmat.albedo_color = Color(0.23, 0.86, 0.70)
		lmat.emission_enabled = true
		lmat.emission = Color(0.23, 0.86, 0.70)
	else:
		lmat.albedo_color = Color(0.70, 0.23, 0.23)
		lmat.emission_enabled = true
		lmat.emission = Color(0.70, 0.23, 0.23)
	lmat.emission_energy_multiplier = 0.6
	light.material_override = lmat
	add_child(light)
	if occupied:
		pod_lights.append({"node": light, "phase": x * 0.3 + z * 0.4, "base": Color(0.23, 0.86, 0.70)})

	# Frost on floor near cycling pods
	if occupied:
		var frost := MeshInstance3D.new()
		var fc := CylinderMesh.new()
		fc.top_radius = 1.3
		fc.bottom_radius = 1.3
		fc.height = 0.01
		frost.mesh = fc
		frost.position = Vector3(x, 0.02, z)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.70, 0.82, 0.90, 0.35)
		fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		frost.material_override = fmat
		add_child(frost)

	# Readout
	var body := ""
	if opened:
		body = "Pod V-05 (assigned to:  VOSS, M.)\n\nSTATUS:  STAGED.  AWAITING SUBJECT.\nSample chamber:  primed.\nNeural lock:  ARMED.\n\nLast technician note:\n  'pod prepped per array calibration target.\n   subject scheduled for cycle 0084.\n   - Sato.'"
	elif label_str == "OKAFOR":
		body = "Pod V-02 - OKAFOR, F.\n\nSTATUS:  CYCLING (slow).\nSubharmonic lock:  STABLE.  0.7 P-units.\nNeural waveform:  matches array transmission.\n\nThrough the rime on the window you can see\nhim.  His eyes are open.  He is not blinking."
	elif label_str == "HARGROVE":
		body = "Pod V-03 - HARGROVE, R.\n\nSTATUS:  CYCLING (slow).\nSubharmonic lock:  STABLE.  0.7 P-units.\nNeural waveform:  matches array transmission.\n\nHe looks asleep.  He does not look at peace."
	elif label_str == "PARK":
		body = "Pod V-04 - PARK, Y.\n\nSTATUS:  CYCLING (slow).\nSubharmonic lock:  STABLE.  0.7 P-units.\nNeural waveform:  matches array transmission.\n\nHer mouth is slightly open.  Like she was\nin the middle of saying something."
	elif label_str == "SATO":
		body = "Pod V-01 - SATO, K.\n\nSTATUS:  CYCLING (slow).\nSubharmonic lock:  UNSTABLE.  drift +0.02 P-units.\nNeural waveform:  partial match.\n\nSato was the station technician.  You do not\nremember him at all.  His face is unfamiliar.\nHis name is on the duty roster in your own\nhandwriting."
	else:
		body = "Pod " + label_str + "\n\nSTATUS:  DARK.  Empty.\nNo subject record."
	Interactable.attach(pod, "Read pod readout", "examine_only", {"text": body, "duration": 8.0})


func _process(dt: float) -> void:
	phase += dt
	for pl in pod_lights:
		var node = pl["node"]
		if not is_instance_valid(node): continue
		var v := 0.4 + 0.6 * (0.5 + 0.5 * sin((phase + pl["phase"]) * (TAU / 4.0)))
		var base: Color = pl["base"]
		var mat: StandardMaterial3D = node.material_override
		mat.emission = Color(base.r * v, base.g * v, base.b * v)

	if GameState.storage_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act8")
