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
	var hint := Label3D.new()
	hint.text = "7741"
	hint.position = Vector3(2.0, 1.7, 17.9)
	hint.rotation_degrees = Vector3(0, 180, 0)
	hint.font_size = 22
	hint.modulate = Color(0.78, 0.74, 0.71, 0.7)
	add_child(hint)

	# ---- Felix cabin (west, z=0) ----
	_build_cabin(Vector3(-5.5, 0, 0.0), "OKAFOR", false)
	Interactable.make_note(self, Vector3(-6.9, 0.72, -1.3), "note_2", "Read journal")
	# Felix-Shape at viewport
	var felix_shape := HorrorShape.create(HorrorShape.KIND_FELIX, Vector3(-4.5, 0, -2.2), 180)
	add_child(felix_shape)
	ShapeTracker.register(felix_shape)
	# Intercom 2
	ActUtil.register_intercom(self, 2, Vector3(-2.8, 1.8, 0), 90, Vector3(-2.0, 1.6, 0), 3.5)

	# ---- Yuna cabin (east, z=4.5) ----
	_build_cabin(Vector3(5.5, 0, 4.5), "PARK", true)
	# Note 3 taped to door
	var n3 := Interactable.make_note(self, Vector3(2.6, 1.55, 4.5), "note_3", "Read door note")
	n3.rotation_degrees = Vector3(0, 90, 0)

	# ---- Hargrove cabin (west, z=9), locked ----
	_build_cabin(Vector3(-5.5, 0, 9.0), "HARGROVE", true, true, "4301")
	Interactable.make_note(self, Vector3(-6.8, 0.72, 7.5), "note_4", "Read handwritten log")

	# ---- Mara cabin (east, z=13.5) ----
	_build_cabin(Vector3(5.5, 0, 13.5), "VOSS", false)
	# Eli photo
	Interactable.make_examine(self, Vector3(6.4, 0.72, 12.0), Vector3(0.18, 0.02, 0.13),
		"Look at photo",
		"Your brother.  He had your eyes.  You haven't looked at this photo in two months.  You don't remember taking it out of the drawer.",
		5.0, Color(0.78, 0.78, 0.82))
	# Mirror with text
	var mirror := Chamber.make_prop_box(self, Vector3(0.05, 0.9, 0.7), Vector3(4.3, 1.5, 11.05), Color(0.59, 0.67, 0.78))
	Interactable.attach(mirror, "Look in mirror", "examine_only", {
		"text": "Lipstick on the mirror.  In your handwriting:  YOU STARTED IT.  The mirror itself is just a mirror.",
		"duration": 4.0,
	})
	# Intercom 3 manual (inside Mara's cabin)
	var ic3 := IntercomPanel.create(Vector3(6.9, 1.7, 11.05), 0)
	add_child(ic3)
	Interactable.attach(ic3, "Press intercom", "trigger_event", {
		"callback": Callable(self, "_trigger_ic3").bind(ic3),
	})

	# Spawn near south door
	ActUtil.spawn_player(Vector3(0, 0.5, -5.5), 0)


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
	var cursor := z_min
	for gz in gap_zs:
		var seg_start := cursor
		var seg_end := gz - Chamber.DOOR_W / 2
		if seg_end > seg_start:
			Chamber.add_wall(self, "x", x, seg_start, seg_end, H, wall_color)
		# Header above gap
		var header_h := H - Chamber.DOOR_H
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
	# Door in corridor wall (corridor wall already has gap)
	if has_door:
		var gap_x := -3.0 if center.x < 0 else 3.0
		var door := Chamber.make_prop_box(self, Vector3(0.10, Chamber.DOOR_H, Chamber.DOOR_W),
			Vector3(gap_x, Chamber.DOOR_H / 2, center.z),
			Color(0.30, 0.35, 0.40))
		if locked:
			# Wall keypad next to door
			var kp := Chamber.make_prop_box(self,
				Vector3(0.08, 0.30, 0.18),
				Vector3(gap_x + (0.10 if center.x > 0 else -0.10), 1.4, center.z + 0.7),
				Color(0.23, 0.27, 0.31))
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


func _process(_dt: float) -> void:
	if GameState.hatch_open and GameState.player and GameState.player.global_position.z > 18.2:
		SceneRouter.transition_to("act4")
