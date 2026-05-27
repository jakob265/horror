extends Node3D
# VESPER - ACT 9: THE SEALED CHAMBER
# The origin. A vast space around the central mass; the crew stand in the dark
# and turn to look (gone when you meet their eyes). No chase here - this is to
# be walked through and understood. Reach the far side to face the choice.

const WALL := Color(0.30, 0.40, 0.50)
const FLOOR := Color(0.36, 0.44, 0.54)
const CEIL := Color(0.10, 0.14, 0.20)


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_chamber()

	# The crew, standing in the dark, gone when you look straight at them.
	ActUtil.haunt(self, {
		"intensity": 0.75, "flicker": true, "flicker_rate": 0.6,
		"peekers": [
			{"pos": Vector3(-5, 0, -3), "kind": HorrorShape.KIND_HARGROVE, "rot": 200.0},
			{"pos": Vector3(5, 0, -3), "kind": HorrorShape.KIND_YUNA, "rot": 160.0},
			{"pos": Vector3(-7, 0, 3), "kind": HorrorShape.KIND_FELIX, "rot": 210.0},
			{"pos": Vector3(7, 0, 3), "kind": HorrorShape.KIND_HARGROVE, "rot": 150.0},
			{"pos": Vector3(0, 0, -7), "kind": HorrorShape.KIND_FELIX, "rot": 180.0},
			{"pos": Vector3(-3, 0, 5), "kind": HorrorShape.KIND_YUNA, "rot": 195.0},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 9.5)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if GameState.player and GameState.player.global_position.z < -10.4:
		SceneRouter.transition_to("act10")


func _build_chamber() -> void:
	Chamber.add_room(self, 24, 22, 8.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": -11.0, "gap": 0.0}, {"axis": "z", "fixed": 11.0, "gap": 0.0}])

	# The central mass: a pillar of grown dark rising through the chamber,
	# its filament spread out across the floor, faintly breathing.
	Chamber.make_prop_box(self, Vector3(2.0, 8.0, 2.0), Vector3(0, 4.0, -1.0), Color(0.05, 0.09, 0.08))
	ActUtil.signal_growth(self, Vector3(0, 0, -1.0), 3.2, Color(0.07, 0.13, 0.11))
	for gp in [Vector3(-3, 0, -1), Vector3(3, 0, -1), Vector3(0, 0, -4), Vector3(0, 0, 2), Vector3(-5, 0, -5), Vector3(5, 0, -5)]:
		ActUtil.signal_growth(self, gp, randf_range(1.4, 2.6), Color(0.06, 0.12, 0.10))
	ActUtil.add_omni(self, Vector3(0, 5.5, -1.0), Color(0.3, 0.5, 0.45), 1.0, 8.0, false)

	# Cocooned crew hung around the mass.
	for hp in [Vector3(-4, 5.0, -2), Vector3(4, 5.0, -2), Vector3(-6, 5.0, 4), Vector3(6, 5.0, 4), Vector3(0, 5.0, -8)]:
		ActUtil.hanging_corpse(self, hp, randf_range(1.8, 2.6), Color(0.30, 0.38, 0.40))
	ActUtil.viscera(self, Vector3(-2.0, 0.02, -2.0))
	ActUtil.viscera(self, Vector3(2.5, 0.02, 0.5))

	# Your recorder, dropped at the threshold.
	Interactable.make_note(self, Vector3(1.0, 0.04, 8.5), "v_chamber", "Play your recorder")
	ActUtil.wall_scrawl(self, "DECIDE WHAT MERCY MEANS", Vector3(0, 3.0, -10.85), 0.0, 30, Color(0.45, 0.06, 0.07))
	ActUtil.wall_label(self, "THE CHAMBER", Vector3(0, 4.2, 10.8), 22, Color(0.6, 0.78, 0.9))
	ActUtil.add_dust_motes(self, Vector3(0, 2.4, 0), Vector3(12, 3.5, 11), 110, Color(0.7, 0.84, 0.95, 0.14))
