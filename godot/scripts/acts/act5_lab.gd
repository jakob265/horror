extends Node3D
# ACT 5 - SIGNAL LAB + HARGROVE'S OFFICE.
# Entry corridor from mess, bank of waveform monitors that flip to EEG on entry,
# central workbench (Note 5), side bench (array keycard + Felix's mug),
# Felix-Shape crouched, off-east is Hargrove's office with readable terminal
# (Note 11 is in engineering, but the array maintenance log is readable here).

const LAB_W := 16.0
const LAB_D := 12.0
const LAB_H := 3.5
const ARRAY_DOOR_X := -6.0
const OFFICE_DOOR_Z := 4.0
const DOOR_W := 1.4

var array_door: Node3D = null
var array_keycard_node: StaticBody3D = null
var array_keycard_slot: MeshInstance3D = null
var monitors: Array[Node3D] = []
var eeg_done := false


func _ready() -> void:
	ActUtil.light_rig_act3(self)

	# --- Access corridor from south (mess hall) at z=-10 ---
	# Floor
	Chamber.make_prop_box(self, Vector3(3.0, 0.2, 8), Vector3(0, -0.1, -10), Color(0.22, 0.24, 0.27))
	# Ceiling
	Chamber.make_prop_box(self, Vector3(3.0, 0.2, 8), Vector3(0, 3, -10), Color(0.12, 0.14, 0.18), false)
	# Side walls
	for x in [-1.5, 1.5]:
		Chamber.make_prop_box(self, Vector3(0.2, 3, 8), Vector3(x, 1.5, -10), Color(0.27, 0.30, 0.35))
	# Back cap
	Chamber.make_prop_box(self, Vector3(3, 3, 0.2), Vector3(0, 1.5, -14.1), Color(0.23, 0.26, 0.31))
	# Sealed entry door
	Chamber.make_prop_box(self, Vector3(1.4, 2.4, 0.10), Vector3(0, 1.2, -14.0), Color(0.67, 0.69, 0.78))

	# --- Lab room ---
	Chamber.add_floor_ceiling(self, LAB_W, LAB_D, LAB_H, Color(0.51, 0.55, 0.59), Color(0.31, 0.35, 0.41))
	var wall := Color(0.20, 0.22, 0.26)

	# North wall: split around the array door at x=-6
	var left_w := (ARRAY_DOOR_X - DOOR_W / 2) - (-LAB_W / 2)
	if left_w > 0:
		Chamber.make_prop_box(self, Vector3(left_w, LAB_H, 0.2),
			Vector3(-LAB_W / 2 + left_w / 2, LAB_H / 2, LAB_D / 2), wall)
	var right_w := LAB_W / 2 - (ARRAY_DOOR_X + DOOR_W / 2)
	if right_w > 0:
		Chamber.make_prop_box(self, Vector3(right_w, LAB_H, 0.2),
			Vector3(ARRAY_DOOR_X + DOOR_W / 2 + right_w / 2, LAB_H / 2, LAB_D / 2), wall)
	# Header
	Chamber.make_prop_box(self, Vector3(DOOR_W + 0.2, LAB_H - 2.4, 0.2),
		Vector3(ARRAY_DOOR_X, 2.4 + (LAB_H - 2.4) / 2, LAB_D / 2), wall)

	# South wall: gap centered at x=0 leading to corridor
	var seg_w := (LAB_W - 3.0) / 2
	for sx in [-(1.5 + seg_w / 2), (1.5 + seg_w / 2)]:
		Chamber.make_prop_box(self, Vector3(seg_w, LAB_H, 0.2), Vector3(sx, LAB_H / 2, -LAB_D / 2), wall)
	# South header above gap
	Chamber.make_prop_box(self, Vector3(3.2, LAB_H - 2.4, 0.2),
		Vector3(0, 2.4 + (LAB_H - 2.4) / 2, -LAB_D / 2), wall)

	# East wall: split around office door at z=4
	var east_seg1_w := (OFFICE_DOOR_Z - DOOR_W / 2) - (-LAB_D / 2)
	if east_seg1_w > 0:
		Chamber.make_prop_box(self, Vector3(0.2, LAB_H, east_seg1_w),
			Vector3(LAB_W / 2, LAB_H / 2, -LAB_D / 2 + east_seg1_w / 2), wall)
	var east_seg2_w := LAB_D / 2 - (OFFICE_DOOR_Z + DOOR_W / 2)
	if east_seg2_w > 0:
		Chamber.make_prop_box(self, Vector3(0.2, LAB_H, east_seg2_w),
			Vector3(LAB_W / 2, LAB_H / 2, OFFICE_DOOR_Z + DOOR_W / 2 + east_seg2_w / 2), wall)
	Chamber.make_prop_box(self, Vector3(0.2, LAB_H - 2.4, DOOR_W + 0.2),
		Vector3(LAB_W / 2, 2.4 + (LAB_H - 2.4) / 2, OFFICE_DOOR_Z), wall)

	# West wall: solid
	Chamber.add_wall(self, "x", -LAB_W / 2, -LAB_D / 2, LAB_D / 2, LAB_H, wall)

	# Cool blue ceiling glow strips
	for x in [-5, 0, 5]:
		for z in [-4, 0, 4]:
			var glow := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.2, 0.06, 0.4)
			glow.mesh = bm
			glow.position = Vector3(x, LAB_H - 0.15, z)
			var gmat := StandardMaterial3D.new()
			gmat.albedo_color = Color(0.70, 0.86, 0.94)
			gmat.emission_enabled = true
			gmat.emission = Color(0.70, 0.86, 0.94)
			gmat.emission_energy_multiplier = 1.0
			glow.material_override = gmat
			add_child(glow)

	# Bank of waveform monitors along north wall — shifted east so the leftmost
	# monitor clears the array door at x=-6 (door panel spans x=-6.7..-5.3).
	for x in [-3.0, -1.5, 0.0, 1.5, 3.0, 4.5]:
		var mon := _build_monitor(Vector3(x, 1.8, LAB_D / 2 - 0.15))
		monitors.append(mon)

	# Central workbench
	Chamber.make_prop_box(self, Vector3(3.0, 1.0, 1.2), Vector3(0, 0.5, 0), Color(0.27, 0.30, 0.34))
	# Note 5 on the bench
	Interactable.make_note(self, Vector3(-0.6, 1.02, 0.2), "note_5", "Read lab notebook")

	# Side bench - array access keycard + Felix's mug
	Chamber.make_prop_box(self, Vector3(2.4, 1.0, 0.9), Vector3(-6.0, 0.5, 0), Color(0.25, 0.27, 0.31))

	# Label plate
	ActUtil.wall_label(self, "ARRAY ACCESS - AUTHORIZED PERSONNEL ONLY",
		Vector3(-6.0, 1.05, -0.46), 18, Color(1.0, 0.94, 0.71))

	# Array keycard
	array_keycard_node = StaticBody3D.new()
	array_keycard_node.position = Vector3(-6.0, 1.04, 0.0)
	var kmesh := MeshInstance3D.new()
	var kbox := BoxMesh.new()
	kbox.size = Vector3(0.22, 0.04, 0.13)
	kmesh.mesh = kbox
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(0.86, 0.70, 0.47)
	kmat.emission_enabled = true
	kmat.emission = Color(0.5, 0.4, 0.2)
	kmat.emission_energy_multiplier = 0.3
	kmesh.material_override = kmat
	array_keycard_node.add_child(kmesh)
	var kshape := CollisionShape3D.new()
	var kcol := BoxShape3D.new()
	kcol.size = Vector3(0.22, 0.04, 0.13)
	kshape.shape = kcol
	array_keycard_node.add_child(kshape)
	add_child(array_keycard_node)
	Interactable.attach(array_keycard_node, "Take array keycard", "trigger_event",
		{"callback": Callable(self, "_take_array_keycard")})

	# Felix's mug
	var mug := Chamber.make_prop_box(self, Vector3(0.18, 0.20, 0.18), Vector3(-5.0, 1.05, 0.0), Color(0.62, 0.31, 0.23))
	Interactable.attach(mug, "Look at mug", "examine_only", {
		"text": "Felix's mug.  'WORLD'S OKAYEST ASTROPHYSICIST' in block letters.  He won it in a crew bet in month four.  He was so pleased with himself.",
		"duration": 5.0,
	})

	# Felix-Shape crouched in the corner
	var felix := HorrorShape.create(HorrorShape.KIND_FELIX, Vector3(5.5, 0, -4.5), 210, true)
	add_child(felix)
	ShapeTracker.register(felix)

	# Intercom 4 panel near the south doorway
	ActUtil.register_intercom(self, 4, Vector3(-1.5, 1.7, -LAB_D / 2 + 0.15), 0, Vector3(0, 1.6, -LAB_D / 2 + 0.5), 3.5)

	# --- Hargrove's office (off east) ---
	var ox := 11.5
	var oz := 4.0
	var o_w := 7.0
	var o_d := 4.0
	Chamber.make_prop_box(self, Vector3(o_w, 0.2, o_d), Vector3(ox, -0.1, oz), Color(0.18, 0.18, 0.22))
	Chamber.make_prop_box(self, Vector3(o_w, 0.2, o_d), Vector3(ox, 3.0, oz), Color(0.10, 0.12, 0.16), false)
	# Walls - north and south
	for zz in [oz - o_d / 2, oz + o_d / 2]:
		Chamber.make_prop_box(self, Vector3(o_w, 3.0, 0.2), Vector3(ox, 1.5, zz), Color(0.18, 0.20, 0.22))
	# East wall
	Chamber.make_prop_box(self, Vector3(0.2, 3.0, o_d), Vector3(ox + o_w / 2, 1.5, oz), Color(0.18, 0.20, 0.22))

	# Office door
	var office_door := Chamber.make_prop_box(self, Vector3(0.10, 2.4, DOOR_W),
		Vector3(LAB_W / 2, 1.2, OFFICE_DOOR_Z), Color(0.55, 0.51, 0.47))
	Interactable.attach(office_door, "Open OFFICE", "trigger_event", {
		"callback": func():
			if office_door.has_meta("opened") and office_door.get_meta("opened"): return
			office_door.set_meta("opened", true)
			var t := office_door.create_tween()
			t.tween_property(office_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.45)
			t.tween_callback(func():
				office_door.visible = false
				for c in office_door.get_children():
					if c is CollisionShape3D:
						c.disabled = true
			)
			AudioManager.door()
	})

	# Desk + drawers
	Chamber.make_prop_box(self, Vector3(1.8, 0.85, 0.9), Vector3(ox - 0.8, 0.42, oz - 0.5), Color(0.22, 0.20, 0.18))
	# Drawer fronts
	for dy in [0.30, 0.62]:
		Chamber.make_prop_box(self, Vector3(0.55, 0.22, 0.04), Vector3(ox - 0.8, dy, oz - 0.05), Color(0.14, 0.13, 0.11), false)
		Chamber.make_prop_box(self, Vector3(0.10, 0.04, 0.04), Vector3(ox - 0.8, dy, oz - 0.03), Color(0.55, 0.51, 0.39), false)

	# Captain's chair on castors
	Chamber.make_prop_box(self, Vector3(0.55, 0.45, 0.55), Vector3(ox - 0.8, 0.22, oz + 0.4), Color(0.14, 0.16, 0.20))
	Chamber.make_prop_box(self, Vector3(0.55, 1.30, 0.10), Vector3(ox - 0.8, 1.10, oz + 0.75), Color(0.14, 0.16, 0.20), false)
	# Castor base
	Chamber.make_prop_box(self, Vector3(0.45, 0.08, 0.45), Vector3(ox - 0.8, 0.04, oz + 0.4), Color(0.14, 0.14, 0.18), false)

	# Scattered papers around the desk
	for i in range(7):
		var px := ox - 1.6 + randf_range(-1.0, 1.0)
		var pz := oz + randf_range(-0.9, 1.5)
		var paper := MeshInstance3D.new()
		var pq := QuadMesh.new()
		pq.size = Vector2(0.28, 0.35)
		paper.mesh = pq
		paper.rotation_degrees = Vector3(-90, randf_range(0, 180), 0)
		paper.position = Vector3(px, 0.02, pz)
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.92, 0.88, 0.78)
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		paper.material_override = pm
		add_child(paper)

	# Bookshelf on the east wall, stacked with engineering binders
	var shelf_x: float = ox + o_w / 2 - 0.20
	Chamber.make_prop_box(self, Vector3(0.20, 2.20, 1.6), Vector3(shelf_x, 1.10, oz + 0.6), Color(0.16, 0.14, 0.12))
	for shy in [0.45, 0.85, 1.25, 1.65, 2.05]:
		Chamber.make_prop_box(self, Vector3(0.30, 0.04, 1.5), Vector3(shelf_x - 0.20, shy, oz + 0.6), Color(0.22, 0.18, 0.14), false)
		# Books on this shelf
		var bx_off := 0.0
		while bx_off < 1.4:
			var bw := randf_range(0.06, 0.12)
			var bh := randf_range(0.20, 0.34)
			Chamber.make_prop_box(self, Vector3(0.18, bh, bw),
				Vector3(shelf_x - 0.25, shy + bh / 2 + 0.02, oz + 0.6 - 0.7 + bx_off + bw / 2),
				Color(randf_range(0.20, 0.55), randf_range(0.15, 0.40), randf_range(0.15, 0.35)),
				false)
			bx_off += bw + 0.01

	# Filing cabinet against the north wall
	var cab_x: float = ox + o_w / 2 - 0.50
	var cab_z: float = oz - o_d / 2 + 0.45
	Chamber.make_prop_box(self, Vector3(0.70, 1.30, 0.55), Vector3(cab_x, 0.65, cab_z), Color(0.30, 0.27, 0.22))
	for dy in [0.30, 0.65, 1.00]:
		Chamber.make_prop_box(self, Vector3(0.62, 0.05, 0.04), Vector3(cab_x, dy, cab_z - 0.30), Color(0.18, 0.16, 0.13), false)
		Chamber.make_prop_box(self, Vector3(0.10, 0.04, 0.05), Vector3(cab_x, dy, cab_z - 0.30), Color(0.55, 0.51, 0.39), false)
	# Folder stack on top of the cabinet
	Chamber.make_prop_box(self, Vector3(0.40, 0.04, 0.30), Vector3(cab_x, 1.32, cab_z), Color(0.78, 0.45, 0.20), false)
	Chamber.make_prop_box(self, Vector3(0.38, 0.04, 0.28), Vector3(cab_x - 0.04, 1.36, cab_z - 0.04), Color(0.42, 0.55, 0.32), false)

	# Coat rack
	Chamber.make_prop_box(self, Vector3(0.06, 1.85, 0.06), Vector3(ox + o_w / 2 - 1.2, 0.93, oz - o_d / 2 + 0.30), Color(0.22, 0.18, 0.14), false)
	Chamber.make_prop_box(self, Vector3(0.55, 0.04, 0.55), Vector3(ox + o_w / 2 - 1.2, 0.04, oz - o_d / 2 + 0.30), Color(0.22, 0.18, 0.14), false)
	# Coat
	Chamber.make_prop_box(self, Vector3(0.55, 0.95, 0.18), Vector3(ox + o_w / 2 - 1.2, 1.40, oz - o_d / 2 + 0.32), Color(0.27, 0.22, 0.16), false)

	# Whiteboard above the desk
	var wb_pos := Vector3(ox - 0.8, 1.90, oz - 0.85)
	Chamber.make_prop_box(self, Vector3(1.4, 0.90, 0.04), wb_pos, Color(0.94, 0.94, 0.92), false)
	ActUtil.wall_label(self, "0.7 P-units\n442-K\nWE MADE IT", wb_pos + Vector3(0, 0, -0.04),
		16, Color(0.78, 0.16, 0.16))

	# Warm desk lamp
	var lamp := MeshInstance3D.new()
	var lsphere := SphereMesh.new()
	lsphere.radius = 0.18
	lsphere.height = 0.36
	lamp.mesh = lsphere
	lamp.position = Vector3(ox + 0.4, 1.10, oz - 0.55)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1.0, 0.86, 0.55)
	lmat.emission_enabled = true
	lmat.emission = Color(1.0, 0.86, 0.55)
	lmat.emission_energy_multiplier = 1.5
	lamp.material_override = lmat
	add_child(lamp)

	# Readable terminal on the desk
	Chamber.make_prop_box(self, Vector3(0.85, 0.55, 0.06), Vector3(ox - 0.8, 1.10, oz - 0.85), Color(0.12, 0.12, 0.14))
	var term_screen := StaticBody3D.new()
	term_screen.position = Vector3(ox - 0.8, 1.10, oz - 0.82)
	var ts_mesh := MeshInstance3D.new()
	var ts_box := BoxMesh.new()
	ts_box.size = Vector3(0.76, 0.48, 0.02)
	ts_mesh.mesh = ts_box
	var ts_mat := StandardMaterial3D.new()
	ts_mat.albedo_color = Color(0.08, 0.16, 0.12)
	ts_mat.emission_enabled = true
	ts_mat.emission = Color(0.0, 0.4, 0.3)
	ts_mat.emission_energy_multiplier = 0.5
	ts_mesh.material_override = ts_mat
	term_screen.add_child(ts_mesh)
	var ts_col := CollisionShape3D.new()
	var ts_cs := BoxShape3D.new()
	ts_cs.size = Vector3(0.76, 0.48, 0.06)
	ts_col.shape = ts_cs
	term_screen.add_child(ts_col)
	add_child(term_screen)
	var log_text := """ARRAY MAINTENANCE LOG
STATION CRESTFALL-9 / DEEP SPACE ARRAY
============================================================

Entry 0117 - R. HARGROVE
Date:  [REDACTED - 3 months prior to 'first contact']

Array resonance at 0.7 Planck units.
Unexpected harmonic.
Flagged for review.
LOW PRIORITY.

------------------------------------------------------------
    cross-reference:    calibration index 442-K
    note (R.H.):        return to this later.
------------------------------------------------------------

Entry 0118 - R. HARGROVE
Date:  [REDACTED]

(no entries logged)

Entry 0119 - R. HARGROVE
Date:  [REDACTED - day of 'first contact']

*** STANDING WAVE DETECTED ***
Coordinates pending.  Signature unknown.
REC: full alert.  Convene crew.
============================================================"""
	Interactable.attach(term_screen, "Read terminal", "read_terminal", {
		"title": "ARRAY MAINTENANCE LOG",
		"text": log_text,
	})

	# --- Array door (sliding, locked until keycard) ---
	array_door = Chamber.make_prop_box(self, Vector3(DOOR_W, 2.4, 0.10),
		Vector3(ARRAY_DOOR_X, 1.2, LAB_D / 2), Color(0.43, 0.31, 0.23))
	# Hazard stripes
	Chamber.make_prop_box(array_door, Vector3(0.9, 0.08, 0.20), Vector3(0, 0.40, -0.06), Color(0.86, 0.70, 0.12), false)
	Chamber.make_prop_box(array_door, Vector3(0.9, 0.08, 0.20), Vector3(0, -0.50, -0.06), Color(0.86, 0.70, 0.12), false)
	# Keycard slot (red until unlocked)
	array_keycard_slot = MeshInstance3D.new()
	var slot_box := BoxMesh.new()
	slot_box.size = Vector3(0.20, 0.08, 0.20)
	array_keycard_slot.mesh = slot_box
	array_keycard_slot.position = Vector3(0.40, -0.10, -0.06)
	var slot_mat := StandardMaterial3D.new()
	slot_mat.albedo_color = Color(0.86, 0.23, 0.23)
	slot_mat.emission_enabled = true
	slot_mat.emission = Color(0.86, 0.23, 0.23)
	slot_mat.emission_energy_multiplier = 0.5
	array_keycard_slot.material_override = slot_mat
	array_door.add_child(array_keycard_slot)

	# "ARRAY" label above door — billboard keeps the text readable from any angle
	ActUtil.wall_label(self, "ARRAY", Vector3(ARRAY_DOOR_X, 2.65, LAB_D / 2 - 0.20),
		36, Color(0.95, 0.80, 0.55))

	Interactable.attach(array_door, "Try array door", "trigger_event", {
		"callback": Callable(self, "_try_open_array_door"),
	})

	# Intercom 5 - just inside the array door (proximity)
	ActUtil.register_intercom(self, 5, Vector3(-4.6, 1.7, LAB_D / 2 - 0.15), 180, Vector3(-6, 1.6, LAB_D / 2 - 1.2), 3.5)

	# Extra fill — lab equipment + ceiling clutter so the room feels lived-in
	# Microscope + sample tray on the west bench (need a bench first)
	Chamber.make_prop_box(self, Vector3(0.55, 0.85, 0.5), Vector3(-LAB_W/2 + 0.40, 0.42, -3.0), Color(0.31, 0.31, 0.35))
	Chamber.make_prop_box(self, Vector3(0.14, 0.40, 0.14), Vector3(-LAB_W/2 + 0.40, 1.05, -3.0), Color(0.20, 0.22, 0.27), false)
	Chamber.make_prop_box(self, Vector3(0.20, 0.06, 0.12), Vector3(-LAB_W/2 + 0.40, 1.30, -3.0), Color(0.16, 0.16, 0.20), false)
	# Petri dish on the bench
	Chamber.make_prop_box(self, Vector3(0.08, 0.02, 0.08), Vector3(-LAB_W/2 + 0.55, 0.87, -3.20), Color(0.86, 0.88, 0.92, 0.6), false)

	# A glass-fronted instrument cabinet on the west wall
	Chamber.make_prop_box(self, Vector3(0.06, 1.6, 1.2), Vector3(-LAB_W/2 + 0.05, 1.65, 3.0), Color(0.20, 0.22, 0.27))
	# Interior shelves
	for sy in [1.10, 1.60, 2.10]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.04, 1.10), Vector3(-LAB_W/2 + 0.10, sy, 3.0), Color(0.40, 0.42, 0.45), false)
		# Items on shelf
		for sz in [-0.40, -0.10, 0.20]:
			Chamber.make_prop_box(self, Vector3(0.06, 0.18, 0.08), Vector3(-LAB_W/2 + 0.10, sy + 0.11, 3.0 + sz), Color(0.62, 0.70, 0.82, 0.5), false)

	# Storage crates stacked NE corner
	Chamber.make_prop_box(self, Vector3(0.7, 0.55, 0.5), Vector3(5.5, 0.28, 4.5), Color(0.55, 0.43, 0.27))
	Chamber.make_prop_box(self, Vector3(0.65, 0.45, 0.45), Vector3(5.5, 0.78, 4.5), Color(0.43, 0.31, 0.20))
	Chamber.make_prop_box(self, Vector3(0.50, 0.30, 0.50), Vector3(5.0, 0.16, 5.0), Color(0.55, 0.43, 0.27))

	# Whiteboard on south wall (west of door gap)
	Chamber.make_prop_box(self, Vector3(1.6, 1.2, 0.06), Vector3(-4.0, 1.7, -LAB_D/2 + 0.15), Color(0.94, 0.92, 0.96))
	ActUtil.wall_label(self, "WAVEFORM 442-K\n   0.7 Pu\n   STABLE",
		Vector3(-4.0, 1.7, -LAB_D/2 + 0.10), 14, Color(0.20, 0.20, 0.20))

	# Ceiling pipes + cable runs
	ActUtil.add_ceiling_pipes(self, LAB_W, LAB_D, LAB_H)
	# Floor decals near the array door
	ActUtil.add_floor_decals(self, LAB_W, LAB_D, Vector3.ZERO, Color(0.86, 0.86, 0.16, 0.55))
	# Wall vents
	ActUtil.wall_vent(self, "x", -LAB_W/2 + 0.05, -1.5, 2.8, Vector2(0.6, 0.4))

	ActUtil.haunt(self, {
		"intensity": 0.46,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(0, 0, -8), Vector3(-5, 0, 2), Vector3(5, 0, 3), Vector3(0, 0, 5)]}],
	})

	# Player spawns at the south end of the corridor
	ActUtil.spawn_player(Vector3(0, 0.5, -13.5), 0)


# --- Monitor builder + animation ----------------------------------------

func _build_monitor(pos: Vector3) -> Node3D:
	var body := Chamber.make_prop_box(self, Vector3(1.0, 0.7, 0.08), pos, Color(0.12, 0.14, 0.20))
	# Screen
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.92, 0.62)
	screen.mesh = quad
	screen.position = Vector3(0, 0, -0.05)
	screen.rotation_degrees = Vector3(0, 180, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.06, 0.10, 0.22)
	smat.emission_enabled = true
	smat.emission = Color(0.06, 0.10, 0.22)
	smat.emission_energy_multiplier = 0.4
	screen.material_override = smat
	body.add_child(screen)

	# Waveform bars
	var bars: Array = []
	for i in 28:
		var bar := MeshInstance3D.new()
		var bq := QuadMesh.new()
		bq.size = Vector2(0.025, 0.10)
		bar.mesh = bq
		bar.position = Vector3(-0.43 + i * 0.031, 0, -0.06)
		bar.rotation_degrees = Vector3(0, 180, 0)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.47, 0.86, 0.94)
		bm.emission_enabled = true
		bm.emission = Color(0.47, 0.86, 0.94)
		bm.emission_energy_multiplier = 0.8
		bar.material_override = bm
		body.add_child(bar)
		bars.append(bar)
	body.set_meta("bars", bars)
	body.set_meta("phase", randf() * 10.0)
	body.set_meta("mode", "sine")
	return body


func _set_monitor_eeg(mon: Node3D) -> void:
	mon.set_meta("mode", "eeg")
	for bar in mon.get_meta("bars"):
		if is_instance_valid(bar):
			var mat: StandardMaterial3D = bar.material_override
			mat.albedo_color = Color(0.86, 0.90, 0.98)
			mat.emission = Color(0.86, 0.90, 0.98)


# --- Callbacks ----------------------------------------------------------

func _take_array_keycard() -> void:
	GameState.array_keycard = true
	if array_keycard_node:
		array_keycard_node.queue_free()
		array_keycard_node = null
	if array_keycard_slot:
		var slot_mat: StandardMaterial3D = array_keycard_slot.material_override
		slot_mat.albedo_color = Color(0.31, 0.86, 0.35)
		slot_mat.emission = Color(0.31, 0.86, 0.35)
	InteractionManager.show_examine("ARRAY ACCESS KEYCARD secured.  The way to the array room is open.", 4.0)


func _try_open_array_door() -> void:
	if not GameState.array_keycard:
		InteractionManager.show_examine("Door locked.  ARRAY ACCESS keycard required.", 3.5)
		return
	if GameState.array_door_open: return
	GameState.array_door_open = true
	var tween := array_door.create_tween()
	tween.tween_property(array_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.6)
	tween.tween_callback(func():
		array_door.visible = false
		for c in array_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	AudioManager.door()


func _process(dt: float) -> void:
	# EEG shift on lab entry
	if not eeg_done and GameState.player and GameState.player.global_position.z > -5.5:
		for m in monitors:
			_set_monitor_eeg(m)
		eeg_done = true

	# Animate waveform bars
	for m in monitors:
		if not is_instance_valid(m): continue
		var phase: float = m.get_meta("phase") + dt
		m.set_meta("phase", phase)
		var bars: Array = m.get_meta("bars")
		var mode: String = m.get_meta("mode")
		for i in bars.size():
			var b = bars[i]
			if not is_instance_valid(b): continue
			var y := 0.0
			if mode == "sine":
				y = 0.18 * sin(phase * 4.0 + i * 0.5)
			else:
				y = 0.05 * sin(phase * 8.0 + i) + 0.10 * sin(phase * 3.0 + i * 1.7) + 0.08 * (randf() - 0.5)
			b.position.y = y

	# Transition to act6 when crossing array door
	if GameState.array_door_open and GameState.player and GameState.player.global_position.z > LAB_D / 2 + 0.2 and abs(GameState.player.global_position.x - ARRAY_DOOR_X) < 1.0:
		SceneRouter.transition_to("act6")
