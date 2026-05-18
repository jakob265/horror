extends Node3D
# ACT 2 - DECON ANTECHAMBER.
# Scanner with Note 8. UV arch. Lockers, quarantine cell, biohazard chute.

const W := 9.0
const D := 12.0
const H := 3.4


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.47, 0.47, 0.51), Color(0.20, 0.22, 0.27))
	var wall := Color(0.37, 0.40, 0.47)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	# Sealed entry (cryo)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "CRYO", Color(0.36, 0.35, 0.30), Callable(), "", true)
	# Exit door (medical)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "MEDICAL", Color(0.36, 0.35, 0.30),
		func(): GameState.decon_door_open = true, "Open MEDICAL")

	# UV decon arch
	for ax in [-1.5, 1.5]:
		var col := Chamber.make_prop_box(self, Vector3(0.30, 2.60, 0.30), Vector3(ax, 1.30, -2.5), Color(0.55, 0.57, 0.61))
		# UV strip
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.10, 2.20, 0.10)
		strip.mesh = box
		strip.position = Vector3(0.18, 0, 0.18)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.71, 0.55, 0.94)
		smat.emission_enabled = true
		smat.emission = Color(0.71, 0.55, 0.94)
		smat.emission_energy_multiplier = 1.5
		strip.material_override = smat
		col.add_child(strip)
	Chamber.make_prop_box(self, Vector3(3.0, 0.40, 0.30), Vector3(0, 2.50, -2.5), Color(0.55, 0.57, 0.61))

	# Scanner pillar (west wall)
	var scanner := Chamber.make_prop_box(self, Vector3(0.9, 1.8, 0.55), Vector3(-W/2 + 0.6, 0.90, 0), Color(0.23, 0.25, 0.29))
	# Note 8 reader slot
	var note8 := Interactable.make_note(scanner, Vector3(0, -0.30, -0.10), "note_8", "Read decon log")

	# Hazard suit lockers (east wall)
	for i in range(5):
		var lz := -3.5 + i * 2.0
		Chamber.make_prop_box(self, Vector3(0.45, 2.40, 1.20), Vector3(W/2 - 0.30, 1.20, lz), Color(0.59, 0.61, 0.65))

	# Quarantine cell window
	var qframe := Chamber.make_prop_box(self, Vector3(1.6, 1.8, 0.10), Vector3(2.5, 1.20, -D/2 + 0.10), Color(0.31, 0.33, 0.39))
	Interactable.attach(qframe, "Look into the cell", "examine_only", {
		"text": "Through the inset window a small quarantine bunk.  Cloth - or a person, or a person-shaped pile of cloth.  The interior speaker is on.  Whatever is in there is humming, very quietly, at 0.7 Planck units.",
		"duration": 8.0,
	})

	# Glove with name tag
	Interactable.make_examine(self, Vector3(1.6, 0.04, -3.0), Vector3(0.18, 0.04, 0.10),
		"Pick up the glove",
		"Medical glove.  The name tag reads VOSS, M. in your own handwriting.  You don't remember taking it off.",
		5.0, Color(0.47, 0.43, 0.41))

	# Bench with laid-out jumpsuit
	Interactable.make_examine(self, Vector3(-2.4, 0.22, D/2 - 0.7), Vector3(2.4, 0.45, 0.5),
		"Look at the bench",
		"Folded jumpsuit, boots, towel.  All set out for someone.  The size label on the jumpsuit.  It is yours.  You don't remember laying it out.",
		5.0, Color(0.37, 0.31, 0.23))

	# Biohazard chute
	Interactable.make_examine(self, Vector3(-W/2 + 0.7, 0.70, -D/2 + 1.5), Vector3(0.8, 1.4, 0.8),
		"Look at the waste chute",
		"Biohazard waste chute.  The bag inside is full.  At the top: a station-issue jumpsuit, name tag still attached:  SATO, K.  You feel like you should know who that is.",
		6.0, Color(0.71, 0.55, 0.16))

	# Crew photo (west wall above scanner)
	Interactable.make_examine(self, Vector3(-W/2 + 0.13, 2.40, 0), Vector3(0.06, 0.5, 0.7),
		"Crew photo",
		"Pre-flight crew photo.  Five people, all smiling.  You stand on the left.  Felix has his arm around your shoulder.  Yuna is laughing at something Hargrove just said.  Felix told a joke at the scanner that morning.  You can't remember the joke.",
		8.0, Color(0.86, 0.84, 0.76))

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _process(_dt: float) -> void:
	if GameState.decon_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_med")
