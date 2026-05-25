extends Node3D
# ACT - MEDICAL BAY (between decon and residential corridor).
# Note 14 on the autodoc table. Surgical caddy with sealed syringe.

const W := 14.0
const D := 12.0
const H := 3.4


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.51, 0.55, 0.62), Color(0.27, 0.31, 0.39))
	var wall := Color(0.34, 0.39, 0.50)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "DECON", Color(0.39, 0.39, 0.31), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "CORRIDOR", Color(0.39, 0.39, 0.31),
		func(): GameState.med_door_open = true, "Open CORRIDOR")

	# Autodoc table (centre)
	var table := Chamber.make_prop_box(self, Vector3(2.2, 0.9, 0.9), Vector3(0, 0.45, 0), Color(0.78, 0.78, 0.82))
	# EKG monitor next to table
	var ekg_back := Chamber.make_prop_box(self, Vector3(0.75, 0.55, 0.06), Vector3(0, 1.55, 0.45), Color(0.16, 0.17, 0.19))
	var ekg_screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.7, 0.5)
	ekg_screen.mesh = quad
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.05, 0.15, 0.10)
	sm.emission_enabled = true
	sm.emission = Color(0.0, 0.4, 0.20)
	sm.emission_energy_multiplier = 0.4
	ekg_screen.material_override = sm
	ekg_screen.position = Vector3(0, 1.55, 0.41)
	add_child(ekg_screen)

	# Note 14 (autodoc transcript) on the table
	Interactable.make_note(self, Vector3(-0.4, 0.92, 0.0), "note_14", "Read autodoc transcript")

	# Locker bank (east wall)
	for i in range(6):
		var lz := -4 + i * 1.6
		Chamber.make_prop_box(self, Vector3(0.4, 2.2, 1.0), Vector3(W/2 - 0.30, 1.10, lz), Color(0.62, 0.65, 0.70))

	# Wash station with mirror
	Chamber.make_prop_box(self, Vector3(1.8, 0.9, 0.6), Vector3(-W/2 + 1.0, 0.45, -3), Color(0.62, 0.65, 0.71))
	var mirror := Chamber.make_prop_box(self, Vector3(0.06, 1.0, 0.7), Vector3(-W/2 + 0.20, 1.5, -3), Color(0.59, 0.67, 0.78))
	Interactable.attach(mirror, "Look in the mirror", "examine_only", {
		"text": "Your face.  You haven't really looked at it since cryo.  You look tired in a way sleep won't fix.  There's a smudge on your cheek that looks like soot.  You don't remember being near a fire.",
		"duration": 6.0,
	})

	# Spilled drug cart
	Interactable.make_examine(self, Vector3(2.5, 0.4, -2), Vector3(0.8, 0.8, 0.5),
		"Look at the cart",
		"A drug cart tipped on its side.  Empty syringe wrappers everywhere.  One vial is unbroken - the label reads HALDOL.  Someone was sedating someone.",
		6.0, Color(0.66, 0.66, 0.71))

	# Surgical caddy with sealed syringe (the IF YOU READ THIS, USE THIS)
	Interactable.make_examine(self, Vector3(0.8, 1.0, -0.8), Vector3(0.4, 0.3, 0.3),
		"Look at the surgical caddy",
		"Single sealed syringe, capped.  A piece of medical tape across the cap, in your handwriting:  IF YOU READ THIS, USE THIS.  You can't remember writing it.",
		7.0, Color(0.78, 0.82, 0.86))

	# Dried blood trail leading to exit
	for i in range(6):
		var smear := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.4, 0.6)
		smear.mesh = qm
		smear.rotation_degrees = Vector3(-90, 0, 0)
		smear.position = Vector3(-0.5 + (i % 2) * 0.3, 0.02, 1.0 + i * 0.9)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.20, 0.10, 0.10, 0.7)
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smear.material_override = bm
		add_child(smear)

	# Equipment racks along south wall — bulky med equipment to break up empty floor
	for ex in [-4, -2.5]:
		Chamber.make_prop_box(self, Vector3(0.7, 1.5, 0.55), Vector3(ex, 0.75, -D/2 + 0.40), Color(0.55, 0.58, 0.62))
		# Top screen
		Chamber.make_prop_box(self, Vector3(0.55, 0.35, 0.06), Vector3(ex, 1.40, -D/2 + 0.18), Color(0.16, 0.18, 0.22), false)
		var rack_scr := MeshInstance3D.new()
		var rack_sb := BoxMesh.new()
		rack_sb.size = Vector3(0.45, 0.25, 0.02)
		rack_scr.mesh = rack_sb
		rack_scr.position = Vector3(ex, 1.40, -D/2 + 0.14)
		var rack_sm := StandardMaterial3D.new()
		rack_sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		rack_sm.albedo_color = Color(0.06, 0.16, 0.10)
		rack_sm.emission_enabled = true
		rack_sm.emission = Color(0.20, 0.86, 0.42)
		rack_sm.emission_energy_multiplier = 0.5
		rack_scr.material_override = rack_sm
		add_child(rack_scr)
		# Knobs
		for kx in [-0.18, 0, 0.18]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.08, 0.04), Vector3(ex + kx, 0.95, -D/2 + 0.14), Color(0.86, 0.70, 0.20), false)

	# Crash cart by the autodoc
	Chamber.make_prop_box(self, Vector3(0.55, 0.85, 0.45), Vector3(1.8, 0.42, 0.5), Color(0.86, 0.20, 0.20))
	Chamber.make_prop_box(self, Vector3(0.50, 0.04, 0.40), Vector3(1.8, 0.86, 0.5), Color(0.16, 0.16, 0.20), false)
	# Defib paddles on top
	for px in [-0.10, 0.10]:
		Chamber.make_prop_box(self, Vector3(0.08, 0.04, 0.18), Vector3(1.8 + px, 0.90, 0.5), Color(0.16, 0.16, 0.20), false)

	# IV stand next to autodoc table
	Chamber.make_prop_box(self, Vector3(0.05, 1.85, 0.05), Vector3(-1.4, 0.93, 0), Color(0.66, 0.66, 0.70), false)
	Chamber.make_prop_box(self, Vector3(0.35, 0.04, 0.35), Vector3(-1.4, 0.04, 0), Color(0.55, 0.55, 0.59))
	# IV bag
	Chamber.make_prop_box(self, Vector3(0.14, 0.30, 0.14), Vector3(-1.40, 1.70, 0), Color(0.86, 0.88, 0.92, 0.6), false)

	# Surgical light arm over the table
	Chamber.make_prop_box(self, Vector3(0.06, 0.06, 0.80), Vector3(0, H - 0.40, 0), Color(0.20, 0.20, 0.24), false)
	var surg := MeshInstance3D.new()
	var ss := CylinderMesh.new()
	ss.top_radius = 0.20
	ss.bottom_radius = 0.30
	ss.height = 0.10
	surg.mesh = ss
	surg.position = Vector3(0, H - 0.95, 0)
	var sgm := StandardMaterial3D.new()
	sgm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	sgm.albedo_color = Color(0.88, 0.94, 0.96)
	sgm.emission_enabled = true
	sgm.emission = Color(0.94, 0.96, 0.98)
	sgm.emission_energy_multiplier = 1.4
	surg.material_override = sgm
	add_child(surg)
	ActUtil.add_omni(self, Vector3(0, H - 1.0, 0), Color(0.94, 0.96, 1.0), 2.4, 5.0, false)

	# Ceiling pipes + floor decals + vents to keep the room feeling lived-in
	ActUtil.add_ceiling_pipes(self, W, D, H)
	ActUtil.add_floor_decals(self, W, D)
	ActUtil.wall_vent(self, "z", D/2 - 0.05, -4.5, 2.6)
	ActUtil.wall_vent(self, "z", -D/2 + 0.05, 3.5, 2.6)

	# Wall sign above the door
	ActUtil.wall_label(self, "MEDICAL  /  AUTODOC", Vector3(0, Chamber.DOOR_H + 0.12, D/2 - 0.18), 16,
		Color(0.86, 0.92, 0.96))

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _process(_dt: float) -> void:
	if GameState.med_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act3")
