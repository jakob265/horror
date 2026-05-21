extends Node3D
# ACT 3 - RESIDENTIAL CORRIDOR + 4 CABIN ALCOVES.
# Cabins: OKAFOR (Felix, open, Note 2 + Felix-Shape at viewport)
#         PARK   (Yuna,  Note 3 on door, conditional Shape)
#         HARGROVE (Note 4, locked code 4301)
#         VOSS   (Note 3 + mirror + Intercom 3 manual)
# Maintenance hatch at z=18, code 7741.
# Intercom 2 fires near Felix's cabin.

const CORRIDOR_LEN := 24.0
const CORRIDOR_W := 6.0
const H := 3.0

var hatch: Node3D = null


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	# Corridor floor, ceiling, side walls with gaps at cabin doors
	Chamber.add_floor_ceiling(self, CORRIDOR_W, CORRIDOR_LEN, H,
		Color(0.55, 0.57, 0.62), Color(0.34, 0.37, 0.42),
		Vector3(0, 0, 6))
	var wall := Color(0.59, 0.65, 0.71)
	# West wall: Felix at z=0, Hargrove at z=9 (each gap)
	_wall_with_gaps(-3, [0.0, 9.0], wall)
	# East wall: Yuna at z=4.5, Mara at z=13.5
	_wall_with_gaps(3, [4.5, 13.5], wall)
	# South cap with sealed entry door
	Chamber.add_wall(self, "z", -6, -CORRIDOR_W/2, CORRIDOR_W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -6 + 0.05, 0, "MED", Color(0.36, 0.35, 0.30), Callable(), "", true)
	# North cap with hatch
	Chamber.add_wall(self, "z", 18, -CORRIDOR_W/2, CORRIDOR_W/2, H, wall, 0.0)
	hatch = Chamber.add_door(self, "z", 18 - 0.05, 0, "MAINT", Color(0.43, 0.35, 0.27), Callable(), "Door MAINT", true)
	# Add keypad next to hatch
	var keypad := Chamber.make_prop_box(self, Vector3(0.18, 0.30, 0.08), Vector3(1.0, 1.4, 18.0 - 0.15), Color(0.23, 0.27, 0.31))
	Interactable.attach(keypad, "Enter code", "keypad", {
		"code": "7741",
		"on_unlock": Callable(self, "_open_hatch"),
	})
	# Code hint scratched on wall
	ActUtil.wall_label(self, "7741", Vector3(2.0, 1.7, 17.85), 22, Color(0.78, 0.74, 0.71))

	# ---- Felix cabin (west, z=0) ----
	_build_cabin(Vector3(-5.5, 0, 0.0), "OKAFOR", false)
	_furnish_felix_cabin(Vector3(-5.5, 0, 0.0))
	# Felix-Shape at viewport
	var felix_shape := HorrorShape.create(HorrorShape.KIND_FELIX, Vector3(-4.5, 0, -2.2), 180)
	add_child(felix_shape)
	ShapeTracker.register(felix_shape)
	# Intercom 2
	ActUtil.register_intercom(self, 2, Vector3(-2.8, 1.8, 0), 90, Vector3(-2.0, 1.6, 0), 3.5)

	# ---- Yuna cabin (east, z=4.5) ----
	_build_cabin(Vector3(5.5, 0, 4.5), "PARK", true)
	_furnish_yuna_cabin(Vector3(5.5, 0, 4.5))
	# Note 3 taped to door
	var n3 := Interactable.make_note(self, Vector3(2.6, 1.55, 4.5), "note_3", "Read door note")
	n3.rotation_degrees = Vector3(0, 90, 0)

	# ---- Hargrove cabin (west, z=9), locked ----
	_build_cabin(Vector3(-5.5, 0, 9.0), "HARGROVE", true, true, "4301")
	_furnish_hargrove_cabin(Vector3(-5.5, 0, 9.0))

	# ---- Mara cabin (east, z=13.5) ----
	_build_cabin(Vector3(5.5, 0, 13.5), "VOSS", false)
	_furnish_mara_cabin(Vector3(5.5, 0, 13.5))
	# Intercom 3 manual (inside Mara's cabin)
	var ic3 := IntercomPanel.create(Vector3(6.9, 1.7, 11.05), 0)
	add_child(ic3)
	Interactable.attach(ic3, "Press intercom", "trigger_event", {
		"callback": Callable(self, "_trigger_ic3").bind(ic3),
	})

	# Spawn near south door
	ActUtil.spawn_player(Vector3(0, 0.5, -5.5), 0)


func _furnish_felix_cabin(c: Vector3) -> void:
	# Bunk against outer wall (x = c.x - 2.5)
	var ox: float = c.x - 2.0
	# Bed base
	Chamber.make_prop_box(self, Vector3(0.8, 0.40, 1.9), Vector3(ox, 0.20, c.z), Color(0.27, 0.24, 0.22))
	# Mattress
	Chamber.make_prop_box(self, Vector3(0.78, 0.15, 1.86), Vector3(ox, 0.48, c.z), Color(0.62, 0.55, 0.47))
	# Crumpled blanket
	Chamber.make_prop_box(self, Vector3(0.76, 0.10, 1.10), Vector3(ox, 0.60, c.z - 0.30), Color(0.42, 0.31, 0.24), false)
	# Pillow
	Chamber.make_prop_box(self, Vector3(0.70, 0.10, 0.40), Vector3(ox, 0.61, c.z - 0.70), Color(0.82, 0.78, 0.70), false)
	# Nightstand at the foot of the bed
	var ns_z: float = c.z + 1.10
	Chamber.make_prop_box(self, Vector3(0.60, 0.55, 0.45), Vector3(ox + 0.10, 0.28, ns_z), Color(0.23, 0.20, 0.16))
	# Lamp on nightstand
	Chamber.make_prop_box(self, Vector3(0.15, 0.10, 0.15), Vector3(ox + 0.10, 0.61, ns_z), Color(0.18, 0.18, 0.22), false)
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.12
	lm.height = 0.20
	lamp.mesh = lm
	lamp.position = Vector3(ox + 0.10, 0.80, ns_z)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1.0, 0.86, 0.62)
	lmat.emission_enabled = true
	lmat.emission = Color(1.0, 0.86, 0.62)
	lmat.emission_energy_multiplier = 1.0
	lamp.material_override = lmat
	add_child(lamp)
	ActUtil.add_omni(self, Vector3(ox + 0.10, 0.95, ns_z), Color(1.0, 0.86, 0.62), 1.0, 3.0, false)
	# Tall locker on inner-corridor wall
	Chamber.make_prop_box(self, Vector3(0.40, 1.80, 0.60), Vector3(c.x + 1.8, 0.90, c.z + 1.5), Color(0.27, 0.27, 0.32))
	# Posters / drawings on the outer wall (north of bed)
	for cfg in [[c.z - 1.0, Color(0.86, 0.71, 0.48)], [c.z + 0.5, Color(0.55, 0.65, 0.82)]]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.55, 0.40), Vector3(c.x - 2.40, 1.7, cfg[0]), cfg[1], false)
	# Note 2 on the nightstand top, not floating
	Interactable.make_note(self, Vector3(ox + 0.10, 0.58, ns_z + 0.20), "note_2", "Read journal")
	# Crumpled paper ball on floor
	Chamber.make_prop_box(self, Vector3(0.06, 0.06, 0.06), Vector3(ox + 0.40, 0.04, c.z + 0.30), Color(0.85, 0.78, 0.62), false)


func _furnish_yuna_cabin(c: Vector3) -> void:
	# Bed against outer wall
	var ox: float = c.x + 2.0
	Chamber.make_prop_box(self, Vector3(0.8, 0.40, 1.9), Vector3(ox, 0.20, c.z), Color(0.24, 0.27, 0.30))
	Chamber.make_prop_box(self, Vector3(0.78, 0.15, 1.86), Vector3(ox, 0.48, c.z), Color(0.55, 0.62, 0.65))
	# Neatly folded blanket
	Chamber.make_prop_box(self, Vector3(0.76, 0.06, 0.65), Vector3(ox, 0.59, c.z + 0.40), Color(0.31, 0.45, 0.55), false)
	Chamber.make_prop_box(self, Vector3(0.70, 0.08, 0.40), Vector3(ox, 0.60, c.z - 0.70), Color(0.86, 0.84, 0.78), false)
	# Plants on a window-shelf along outer wall
	var sh_x: float = c.x + 2.42
	for sz in [c.z - 1.0, c.z + 0.0, c.z + 1.0]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.04, 0.20), Vector3(sh_x, 1.45, sz), Color(0.22, 0.18, 0.14), false)
		Chamber.make_prop_box(self, Vector3(0.14, 0.16, 0.14), Vector3(sh_x - 0.10, 1.55, sz), Color(0.55, 0.42, 0.27), false)
		Chamber.make_prop_box(self, Vector3(0.04, 0.30, 0.04), Vector3(sh_x - 0.10, 1.78, sz), Color(0.27, 0.50, 0.30), false)
	# Desk against inner wall
	Chamber.make_prop_box(self, Vector3(0.95, 0.85, 0.55), Vector3(c.x + 1.7, 0.42, c.z - 1.5), Color(0.31, 0.27, 0.22))
	# Closed laptop + notebook + pen
	Chamber.make_prop_box(self, Vector3(0.35, 0.04, 0.30), Vector3(c.x + 1.7, 0.87, c.z - 1.5), Color(0.16, 0.18, 0.20), false)
	Chamber.make_prop_box(self, Vector3(0.22, 0.04, 0.28), Vector3(c.x + 1.7, 0.87, c.z - 1.1), Color(0.78, 0.74, 0.66), false)


func _furnish_hargrove_cabin(c: Vector3) -> void:
	# Tidy bunk, footlocker — strict and military
	var ox: float = c.x - 2.0
	Chamber.make_prop_box(self, Vector3(0.8, 0.40, 1.9), Vector3(ox, 0.20, c.z), Color(0.20, 0.20, 0.22))
	Chamber.make_prop_box(self, Vector3(0.78, 0.12, 1.86), Vector3(ox, 0.46, c.z), Color(0.42, 0.46, 0.50))
	# Tight blanket
	Chamber.make_prop_box(self, Vector3(0.76, 0.04, 1.50), Vector3(ox, 0.54, c.z + 0.20), Color(0.20, 0.27, 0.34), false)
	# Pillow squared off
	Chamber.make_prop_box(self, Vector3(0.70, 0.10, 0.34), Vector3(ox, 0.57, c.z - 0.78), Color(0.92, 0.90, 0.86), false)
	# Footlocker
	Chamber.make_prop_box(self, Vector3(0.7, 0.40, 0.40), Vector3(ox + 0.10, 0.20, c.z + 1.40), Color(0.16, 0.18, 0.22))
	# Desk with framed photo
	Chamber.make_prop_box(self, Vector3(0.85, 0.80, 0.50), Vector3(c.x + 1.7, 0.40, c.z + 1.5), Color(0.23, 0.20, 0.16))
	# Frame on desk
	Chamber.make_prop_box(self, Vector3(0.20, 0.18, 0.04), Vector3(c.x + 1.7, 0.90, c.z + 1.4), Color(0.78, 0.74, 0.66), false)
	# Photo on the wall above desk
	Chamber.make_prop_box(self, Vector3(0.04, 0.30, 0.40), Vector3(c.x + 1.95, 1.5, c.z + 1.5), Color(0.27, 0.22, 0.18), false)
	# Note 4 sitting on top of footlocker
	Interactable.make_note(self, Vector3(ox + 0.10, 0.42, c.z + 1.40), "note_4", "Read handwritten log")


func _furnish_mara_cabin(c: Vector3) -> void:
	# Outer wall is at x = c.x + 2.5 = 8.0; mirror should be on it, not floating
	var ox: float = c.x + 2.0
	# Bed (rumpled, lived in)
	Chamber.make_prop_box(self, Vector3(0.8, 0.40, 1.9), Vector3(ox, 0.20, c.z), Color(0.22, 0.18, 0.18))
	Chamber.make_prop_box(self, Vector3(0.78, 0.15, 1.86), Vector3(ox, 0.48, c.z), Color(0.62, 0.46, 0.42))
	Chamber.make_prop_box(self, Vector3(0.76, 0.10, 1.10), Vector3(ox - 0.05, 0.60, c.z + 0.30), Color(0.43, 0.27, 0.27), false)
	Chamber.make_prop_box(self, Vector3(0.70, 0.10, 0.36), Vector3(ox, 0.61, c.z - 0.78), Color(0.82, 0.78, 0.70), false)
	# Nightstand on the bedside
	var ns_z: float = c.z - 1.30
	Chamber.make_prop_box(self, Vector3(0.55, 0.55, 0.45), Vector3(ox + 0.05, 0.28, ns_z), Color(0.20, 0.18, 0.16))
	# Framed photo of Eli — on the nightstand, no longer floating
	Interactable.make_examine(self, Vector3(ox + 0.05, 0.60, ns_z + 0.05), Vector3(0.18, 0.13, 0.03),
		"Look at photo",
		"Your brother.  He had your eyes.  You haven't looked at this photo in two months.  You don't remember taking it out of the drawer.",
		5.0, Color(0.78, 0.78, 0.82))
	# Small lamp on the nightstand
	var lamp := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.10
	lm.bottom_radius = 0.14
	lm.height = 0.18
	lamp.mesh = lm
	lamp.position = Vector3(ox + 0.10, 0.65, ns_z - 0.10)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.92, 0.78, 0.55)
	lmat.emission_enabled = true
	lmat.emission = Color(0.95, 0.78, 0.55)
	lmat.emission_energy_multiplier = 0.8
	lamp.material_override = lmat
	add_child(lamp)
	ActUtil.add_omni(self, Vector3(ox + 0.10, 0.85, ns_z - 0.10), Color(0.95, 0.78, 0.55), 0.9, 3.0, false)
	# Wardrobe against inner wall
	Chamber.make_prop_box(self, Vector3(0.40, 1.80, 0.70), Vector3(c.x + 1.7, 0.90, c.z + 1.5), Color(0.27, 0.22, 0.20))
	# Wall mirror — properly mounted on the OUTER wall (x = c.x + 2.5)
	var outer_x: float = c.x + 2.5 - 0.06
	var mirror := Chamber.make_prop_box(self, Vector3(0.04, 0.9, 0.7), Vector3(outer_x, 1.5, c.z - 0.6), Color(0.16, 0.16, 0.20))
	# Mirror glass face
	var mglass := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(0.02, 0.84, 0.64)
	mglass.mesh = mb
	mglass.position = Vector3(outer_x - 0.04, 1.5, c.z - 0.6)
	var mmat := StandardMaterial3D.new()
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mmat.albedo_color = Color(0.62, 0.70, 0.78)
	mmat.metallic = 0.9
	mmat.roughness = 0.05
	mglass.material_override = mmat
	add_child(mglass)
	Interactable.attach(mirror, "Look in mirror", "examine_only", {
		"text": "Lipstick on the mirror.  In your handwriting:  YOU STARTED IT.  The mirror itself is just a mirror.",
		"duration": 4.0,
	})
	# Tangled clothes pile by the wardrobe
	Chamber.make_prop_box(self, Vector3(0.50, 0.18, 0.40), Vector3(c.x + 1.7, 0.09, c.z + 0.7), Color(0.31, 0.27, 0.27), false)
	# Posters/photographs on the inner wall above the wardrobe
	Chamber.make_prop_box(self, Vector3(0.04, 0.45, 0.30), Vector3(c.x + 1.95, 2.10, c.z + 1.50), Color(0.62, 0.43, 0.31), false)


func _trigger_ic3(panel: IntercomPanel) -> void:
	OlenManager.trigger_manual(3, panel)


func _open_hatch() -> void:
	GameState.hatch_open = true
	if hatch:
		var tween := hatch.create_tween()
		tween.tween_property(hatch, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
		tween.tween_callback(func():
			hatch.visible = false
			for c in hatch.get_children():
				if c is CollisionShape3D:
					c.disabled = true
		)
		AudioManager.door()


func _wall_with_gaps(x: float, gap_zs: Array, wall_color: Color) -> void:
	var z_min := -CORRIDOR_W
	var z_max := 18.0
	gap_zs = gap_zs.duplicate()
	gap_zs.sort()
	var cursor: float = z_min
	for gz_raw in gap_zs:
		var gz: float = float(gz_raw)
		var seg_start: float = cursor
		var seg_end: float = gz - Chamber.DOOR_W / 2
		if seg_end > seg_start:
			Chamber.add_wall(self, "x", x, seg_start, seg_end, H, wall_color)
		# Header above gap
		var header_h: float = H - Chamber.DOOR_H
		Chamber.make_prop_box(self,
			Vector3(0.2, header_h, Chamber.DOOR_W),
			Vector3(x, Chamber.DOOR_H + header_h / 2, gz),
			wall_color)
		cursor = gz + Chamber.DOOR_W / 2
	if z_max > cursor:
		Chamber.add_wall(self, "x", x, cursor, z_max, H, wall_color)


func _build_cabin(center: Vector3, label: String, has_door: bool, locked: bool = false, code: String = "") -> void:
	# Floor + back/side walls of a 5x5 cabin alcove off the corridor.
	var sx := 2.5
	var sz := 2.5
	var sy := 1.5
	# Floor
	Chamber.make_prop_box(self, Vector3(sx * 2, 0.2, sz * 2), Vector3(center.x, -0.1, center.z), Color(0.23, 0.23, 0.25))
	# Ceiling
	Chamber.make_prop_box(self, Vector3(sx * 2, 0.2, sz * 2), Vector3(center.x, sy * 2, center.z), Color(0.20, 0.22, 0.26))
	var wall := Color(0.22, 0.22, 0.27)
	# North + south walls
	Chamber.add_wall(self, "z", center.z - sz, center.x - sx, center.x + sx, sy * 2, wall)
	Chamber.add_wall(self, "z", center.z + sz, center.x - sx, center.x + sx, sy * 2, wall)
	# Outer wall (facing away from corridor)
	var outer_x := center.x + (-sx if center.x < 0 else sx)
	Chamber.add_wall(self, "x", outer_x, center.z - sz, center.z + sz, sy * 2, wall)
	# Doorframe trim for the corridor-side opening (always present)
	var gap_x := -3.0 if center.x < 0 else 3.0
	_add_cabin_doorframe(gap_x, center.z, center.x < 0)
	# Nameplate above doorway
	var label_pos := Vector3(gap_x + (-0.12 if center.x > 0 else 0.12), Chamber.DOOR_H + 0.18, center.z)
	ActUtil.wall_label(self, label, label_pos, 14, Color(0.92, 0.94, 1.0))
	# Door in corridor wall (corridor wall already has gap)
	if has_door:
		var door := Chamber.make_prop_box(self, Vector3(0.10, Chamber.DOOR_H, Chamber.DOOR_W),
			Vector3(gap_x, Chamber.DOOR_H / 2, center.z),
			Color(0.30, 0.35, 0.40), true, "door_panel", SurfaceFactory.CAT_WALL_METAL)
		if locked:
			# Wall keypad on the CORRIDOR side of the wall, not clipping into it
			var kp_x: float = gap_x + (0.10 if center.x < 0 else -0.10)
			var kp := Chamber.make_prop_box(self,
				Vector3(0.08, 0.30, 0.18),
				Vector3(kp_x, 1.4, center.z + 0.7),
				Color(0.23, 0.27, 0.31), true, "keypad")
			# Keypad screen + LED so it reads as a real device
			var kpscr := MeshInstance3D.new()
			var kpsq := BoxMesh.new()
			kpsq.size = Vector3(0.02, 0.10, 0.12)
			kpscr.mesh = kpsq
			kpscr.position = Vector3(kp_x + (0.05 if center.x < 0 else -0.05), 1.50, center.z + 0.7)
			var kpsm := StandardMaterial3D.new()
			kpsm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			kpsm.albedo_color = Color(0.04, 0.20, 0.08)
			kpsm.emission_enabled = true
			kpsm.emission = Color(0.20, 0.86, 0.28)
			kpsm.emission_energy_multiplier = 0.8
			kpscr.material_override = kpsm
			add_child(kpscr)
			Interactable.attach(kp, "Enter code", "keypad", {
				"code": code,
				"on_unlock": func():
					var t := door.create_tween()
					t.tween_property(door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H/2, 0.45)
					t.tween_callback(func():
						door.visible = false
						for c in door.get_children():
							if c is CollisionShape3D:
								c.disabled = true
					)
					AudioManager.door()
			})
			Interactable.attach(door, "Door " + label, "trigger_event", {
				"callback": func(): InteractionManager.show_examine(label + " cabin door locked.  Use the wall keypad.", 3.0)
			})
		else:
			Interactable.attach(door, "Open " + label, "trigger_event", {
				"callback": func():
					if door.has_meta("opened") and door.get_meta("opened"): return
					door.set_meta("opened", true)
					var t := door.create_tween()
					t.tween_property(door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H/2, 0.45)
					t.tween_callback(func():
						door.visible = false
						for c in door.get_children():
							if c is CollisionShape3D:
								c.disabled = true
					)
					AudioManager.door()
			})
	else:
		# Cabin opening — display a door panel slid up into the doorframe so the
		# opening reads as an actual doorway and not a featureless gap.
		Chamber.make_prop_box(self, Vector3(0.08, 0.32, Chamber.DOOR_W),
			Vector3(gap_x, Chamber.DOOR_H + 0.10, center.z),
			Color(0.18, 0.20, 0.24), false, "door_open_panel", SurfaceFactory.CAT_WALL_METAL)


# Emissive trim around a cabin doorway gap
func _add_cabin_doorframe(gap_x: float, gap_z: float, is_west: bool) -> void:
	var trim_col := Color(0.18, 0.32, 0.42)
	var trim_emit := Color(0.45, 0.78, 0.95)
	var thickness := 0.03
	var depth := 0.20
	var horiz_size := Vector3(depth, thickness, Chamber.DOOR_W + 2 * thickness)
	var vert_size := Vector3(depth, Chamber.DOOR_H, thickness)
	# top
	for entry in [
		[horiz_size, Vector3(gap_x, Chamber.DOOR_H + thickness / 2, gap_z)],
		[vert_size, Vector3(gap_x, Chamber.DOOR_H / 2, gap_z - Chamber.DOOR_W / 2 - thickness / 2)],
		[vert_size, Vector3(gap_x, Chamber.DOOR_H / 2, gap_z + Chamber.DOOR_W / 2 + thickness / 2)],
	]:
		var bm := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = entry[0]
		bm.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.albedo_color = trim_col
		mat.emission_enabled = true
		mat.emission = trim_emit
		mat.emission_energy_multiplier = 1.4
		mat.metallic = 0.6
		mat.roughness = 0.4
		bm.material_override = mat
		bm.position = entry[1]
		add_child(bm)


func _process(_dt: float) -> void:
	if GameState.hatch_open and GameState.player and GameState.player.global_position.z > 18.2:
		SceneRouter.transition_to("act4")
