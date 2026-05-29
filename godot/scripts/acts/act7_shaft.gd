extends Node3D
# VESPER - ACT 7: THE DRILL SHAFT
# Claustrophobic transition. The drill derrick fills a cramped head-room over
# the borehole. Engage the winch, then board the cage - which only goes down -
# while a hunter works the room. Boarding the live cage drops you into the ice.

const WALL := Color(0.26, 0.29, 0.33)
const FLOOR := Color(0.30, 0.32, 0.36)
const CEIL := Color(0.11, 0.12, 0.15)

var cage_light: OmniLight3D = null
var winch_engaged := false
var descending := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.10, 0.026)
	_build_shaft()

	var stalker := HorrorShape.create(HorrorShape.KIND_FELIX, Vector3(-3, 0, -2.0), 0.0)
	stalker.set_stalk([Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(0, 0, 2)], 1.1, 4.0)
	add_child(stalker)
	ShapeTracker.register(stalker)

	ActUtil.haunt(self, {"intensity": 0.55, "flicker": true, "flicker_rate": 1.5})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 4.5)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if winch_engaged and not descending and GameState.player:
		var p: Vector3 = GameState.player.global_position
		if p.x > 2.4 and p.x < 4.6 and p.z > -5.1 and p.z < -2.9:
			descending = true
			_descend()


func _build_shaft() -> void:
	# Tight room, only a south entrance - you leave by going down.
	Chamber.add_room(self, 12, 12, 4.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 6.0, "gap": 0.0}])
	Chamber.invis_wall(self, "z", 6, 0)
	ActUtil.add_ceiling_pipes(self, 12, 12, 4.0, Vector3(0, 0, 0))

	# The derrick: a heavy mast through the ceiling, drawworks at its base.
	Chamber.make_prop_box(self, Vector3(1.0, 4.0, 1.0), Vector3(-0.5, 2.0, -1.0), Color(0.32, 0.30, 0.22))
	for bx in [-1.1, 0.1]:
		Chamber.make_prop_box(self, Vector3(0.12, 4.0, 0.12), Vector3(bx, 2.0, -1.8), Color(0.28, 0.26, 0.20), false)
		Chamber.make_prop_box(self, Vector3(0.12, 4.0, 0.12), Vector3(bx, 2.0, -0.2), Color(0.28, 0.26, 0.20), false)
	Chamber.make_prop_box(self, Vector3(2.2, 1.0, 1.8), Vector3(-0.5, 0.5, -1.0), Color(0.34, 0.36, 0.40))
	# The borehole: a black square in the floor with a low rail.
	var hole := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(2.6, 0.05, 2.6)
	hole.mesh = hb
	hole.position = Vector3(3.5, 0.02, -4.0)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.01, 0.01, 0.015)
	hole.material_override = hm
	add_child(hole)
	for rr in [Vector3(2.1, 0, -4), Vector3(4.9, 0, -4), Vector3(3.5, 0, -5.4)]:
		Chamber.make_prop_box(self, Vector3(0.1, 0.9, 0.1), rr + Vector3(0, 0.45, 0), Color(0.6, 0.5, 0.1), false)

	# The cage over the hole: open frame on a floor plate.
	Chamber.make_prop_box(self, Vector3(2.0, 0.12, 2.0), Vector3(3.5, 0.06, -4.0), Color(0.30, 0.31, 0.34), false)
	for cx in [2.6, 4.4]:
		for cz in [-4.9, -3.1]:
			Chamber.make_prop_box(self, Vector3(0.1, 2.2, 0.1), Vector3(cx, 1.1, cz), Color(0.36, 0.37, 0.40), false)
	Chamber.make_prop_box(self, Vector3(2.0, 0.1, 2.0), Vector3(3.5, 2.2, -4.0), Color(0.30, 0.31, 0.34), false)
	cage_light = OmniLight3D.new()
	cage_light.light_color = Color(0.9, 0.5, 0.3)
	cage_light.light_energy = 0.0
	cage_light.omni_range = 4.0
	cage_light.position = Vector3(3.5, 2.0, -4.0)
	add_child(cage_light)

	# Winch control on the drawworks (engage, then board the cage).
	var winch := Chamber.make_prop_box(self, Vector3(0.3, 0.5, 0.25), Vector3(0.8, 1.1, -1.0), Color(0.6, 0.15, 0.12))
	Interactable.attach(winch, "Engage the winch", "trigger_event", {"callback": Callable(self, "_engage_winch")})

	# Dressing + dread + the drill log.
	ActUtil.hide_locker(self, Vector3(-5.4, 0, 2.0), 90.0)
	ActUtil.wall_label(self, "SHAFT HEAD - 1114 m", Vector3(0, 3.0, 5.8), 18, Color(0.7, 0.82, 0.88))
	ActUtil.wall_scrawl(self, "IT CAME UP THE SHAFT", Vector3(-3.5, 2.0, -5.85), 0.0, 28, Color(0.45, 0.06, 0.07))
	Interactable.make_note(self, Vector3(-0.5, 1.04, 0.2), "v_shaft", "Read the drill log")
	ActUtil.corpse(self, Vector3(-4.5, 0, -3.5), 60.0, true, Color(0.22, 0.20, 0.16))
	ActUtil.signal_growth(self, Vector3(5.5, 0, -5.5), 1.3, Color(0.08, 0.13, 0.10))
	ActUtil.blood_trail(self, Vector3(-4.5, 0.02, -3.5), Vector3(2.6, 0.02, -3.8), 6)


func _engage_winch() -> void:
	if winch_engaged:
		return
	winch_engaged = true
	if cage_light:
		cage_light.light_energy = 2.2
	AudioManager.door()
	InteractionManager.show_examine("The winch shudders awake. The cage is live. Board it - it only goes down.", 4.0)


func _descend() -> void:
	AudioManager.door()
	InteractionManager.show_examine("The cage drops out from under the station, into the dark of the ice.", 3.0)
	SceneRouter.transition_to("act8")
