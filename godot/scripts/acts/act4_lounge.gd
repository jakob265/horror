extends Node3D
# ACT 4 - OBSERVATION LOUNGE.
# Horseshoe couch, Note 9 on coffee table, porthole, library cart, tea bar
# (Yuna's mug), toy piano, memorial wall, framed photo of young Eli.

const W := 14.0
const D := 12.0
const H := 3.6

var exit_open := false


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.55, 0.45, 0.35), Color(0.31, 0.27, 0.27))
	var wall := Color(0.42, 0.40, 0.45)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "MAINT", Color(0.43, 0.35, 0.27), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "MESS", Color(0.50, 0.40, 0.30),
		func(): exit_open = true, "Open MESS")

	# Porthole (north wall) - dark window into space
	var porthole := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 1.3
	pm.height = 0.3
	porthole.mesh = pm
	porthole.position = Vector3(0, 1.9, D/2 - 0.18)
	porthole.rotation_degrees = Vector3(90, 0, 0)
	porthole.scale = Vector3(1, 0.1, 1)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.05, 0.07, 0.13)
	pmat.emission_enabled = true
	pmat.emission = Color(0.06, 0.10, 0.20)
	pmat.emission_energy_multiplier = 0.5
	porthole.material_override = pmat
	add_child(porthole)

	# Horseshoe couch
	for cfg in [
		[Vector3(2.8, 0.35, -1.0), Vector3(2.0, 0.7, 0.8)],
		[Vector3(-2.8, 0.35, -1.0), Vector3(2.0, 0.7, 0.8)],
		[Vector3(0, 0.35, -2.4), Vector3(4.4, 0.7, 0.8)],
	]:
		Chamber.make_prop_box(self, cfg[1], cfg[0], Color(0.40, 0.32, 0.25))

	# Coffee table with Note 9
	Chamber.make_prop_box(self, Vector3(1.6, 0.40, 0.8), Vector3(0, 0.20, -0.5), Color(0.27, 0.23, 0.20))
	Interactable.make_note(self, Vector3(0, 0.42, -0.5), "note_9", "Read folded paper")

	# Tea bar (east side)
	Chamber.make_prop_box(self, Vector3(0.6, 1.0, 3.0), Vector3(W/2 - 0.5, 0.5, 2), Color(0.45, 0.39, 0.31))
	# Yuna's mug (still has tea)
	Interactable.make_examine(self, Vector3(W/2 - 0.8, 1.05, 2.5), Vector3(0.15, 0.18, 0.15),
		"Yuna's mug",
		"Yuna's mug.  Tea inside.  It is room temperature - which on this station means it has not been here for very long.",
		5.0, Color(0.78, 0.74, 0.71))

	# Library cart
	Chamber.make_prop_box(self, Vector3(0.8, 1.2, 0.5), Vector3(-W/2 + 1.0, 0.6, 3), Color(0.39, 0.31, 0.23))

	# Toy piano (west)
	Interactable.make_examine(self, Vector3(-W/2 + 1.0, 0.4, -3), Vector3(1.2, 0.6, 0.4),
		"Press a key",
		"It plays a flat E.  Mara's mother gave her this when she was eight.  She doesn't remember bringing it.",
		5.0, Color(0.62, 0.39, 0.27))

	# Memorial wall (east)
	Interactable.make_examine(self, Vector3(W/2 - 0.15, 1.6, -2), Vector3(0.05, 1.4, 2.4),
		"Read the memorial wall",
		"Names of previous crews.  Below them, the current crew - VOSS, OKAFOR, PARK, HARGROVE, SATO - each name with a small inked dot beside it.  Three of the dots are in your handwriting.  You do not remember making them.",
		8.0, Color(0.55, 0.51, 0.47))

	# Framed photo of young Eli (north wall)
	Interactable.make_examine(self, Vector3(-3, 2.0, D/2 - 0.15), Vector3(0.4, 0.5, 0.06),
		"Look at the framed photo",
		"A boy on a beach. Eli, maybe seven.  Squinting at the camera.  You don't remember hanging this.  You don't remember packing it.",
		7.0, Color(0.78, 0.78, 0.82))

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_mess")
