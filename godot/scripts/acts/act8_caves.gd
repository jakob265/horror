extends Node3D
# VESPER - ACT 8: THE ICE CAVES
# Its domain. An evasion gauntlet through a glacial cavern choked with the
# nest's growth and cocooned crew. Two hunters prowl. Pick your way north
# through the ice formations to the fissure that drops to the sealed chamber.

const WALL := Color(0.34, 0.42, 0.52)
const FLOOR := Color(0.40, 0.48, 0.58)
const CEIL := Color(0.14, 0.18, 0.24)
const ICE := Color(0.52, 0.66, 0.80)


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_cavern()

	for cfg in [
		{"pos": Vector3(-4, 0, 0), "kind": HorrorShape.KIND_HARGROVE, "pts": [Vector3(-6, 0, 1), Vector3(6, 0, 1), Vector3(0, 0, -5)]},
		{"pos": Vector3(4, 0, 4), "kind": HorrorShape.KIND_FELIX, "pts": [Vector3(4, 0, 5), Vector3(-5, 0, -3), Vector3(5, 0, -4)]},
	]:
		var s := HorrorShape.create(cfg["kind"], cfg["pos"], 0.0)
		s.set_stalk(cfg["pts"], 1.2, 4.2)
		add_child(s)
		ShapeTracker.register(s)

	ActUtil.haunt(self, {"intensity": 0.7, "flicker": true, "flicker_rate": 0.9})

	# A handheld radio frozen into the ice still has a fragment in its buffer.
	ActUtil.register_note_echo(self, Vector3(10.85, 1.6, 3.0), -90.0, "note_9")

	# Kael, who came down here to end it and understood there was nothing to end.
	ActUtil.enable_lure(self, {
		"voice": "Kael",
		"calls": [
			{"call": "it isn't many. it's one. and there's room. you'll never be cold again.",
			 "answer": "come down. we've been keeping your place."},
			{"call": "i was wrong about the lamp. the lamp is fine. bring it. we'll keep it lit forever.",
			 "answer": "yes. that's it. don't stop walking."},
			{"call": "frey says hello. pak says hello. we all say hello. with one mouth.",
			 "answer": "good. you heard us. now stand still."},
		],
		"gap_min": 22.0, "gap_max": 50.0,
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 8.5)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if GameState.player and GameState.player.global_position.z < -9.4:
		SceneRouter.transition_to("act8_5")


func _build_cavern() -> void:
	Chamber.add_room(self, 22, 20, 6.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": -10.0, "gap": 0.0}, {"axis": "z", "fixed": 10.0, "gap": 0.0}])
	Chamber.invis_wall(self, "z", 10, 0)

	# Ice formations: leaning slabs + floor/ceiling columns. They break sight
	# lines and force a winding path - cover from the hunters.
	var slabs := [
		[Vector3(-4, 1.6, 6), Vector3(2.5, 3.2, 0.9), 22.0],
		[Vector3(4, 1.4, 4), Vector3(2.2, 2.8, 0.9), -28.0],
		[Vector3(-6, 1.8, 0), Vector3(2.6, 3.6, 1.0), 12.0],
		[Vector3(5, 1.6, -1), Vector3(2.4, 3.2, 1.0), 30.0],
		[Vector3(-3, 1.5, -5), Vector3(2.4, 3.0, 0.9), -18.0],
		[Vector3(3.5, 1.7, -6), Vector3(2.4, 3.4, 1.0), 20.0],
	]
	for s in slabs:
		var slab := Chamber.make_prop_box(self, s[1], s[0], ICE, true, "ice")
		slab.rotation_degrees = Vector3(0, 0, s[2])
	for cp in [Vector3(-8, 0, 4), Vector3(8, 0, 6), Vector3(-7, 0, -6), Vector3(7, 0, -7), Vector3(0, 0, 2)]:
		Chamber.make_prop_box(self, Vector3(0.8, 3.0, 0.8), cp + Vector3(0, 1.5, 0), ICE, true, "ice")          # stalagmite
		Chamber.make_prop_box(self, Vector3(0.7, 2.2, 0.7), cp + Vector3(0.4, 5.0, 0.4), ICE, false, "ice")     # stalactite

	# The nest: growth smothering the centre + north, cocooned crew overhead.
	for gp in [Vector3(0, 0, -3), Vector3(-5, 0, -7), Vector3(6, 0, -5), Vector3(-2, 0, 5), Vector3(4, 0, 8)]:
		ActUtil.signal_growth(self, gp, randf_range(1.4, 2.4), Color(0.07, 0.13, 0.12))
	for hp in [Vector3(-3, 4.4, -2), Vector3(3, 4.4, -4), Vector3(-6, 4.4, 2), Vector3(5, 4.4, 1)]:
		ActUtil.hanging_corpse(self, hp, randf_range(1.6, 2.2), Color(0.30, 0.36, 0.34))
	ActUtil.viscera(self, Vector3(0, 0.02, -3.0))
	ActUtil.viscera(self, Vector3(-4.0, 0.02, -6.0))

	# Crevices to hide in.
	ActUtil.hide_locker(self, Vector3(-10.4, 0, 3.0), 90.0, ICE)
	ActUtil.hide_locker(self, Vector3(10.4, 0, -2.0), -90.0, ICE)

	# Kael's last entry on a frozen body near the fissure.
	ActUtil.corpse(self, Vector3(-1.5, 0, -8.0), 10.0, true, Color(0.34, 0.40, 0.48))
	Interactable.make_note(self, Vector3(-1.0, 0.04, -7.4), "v_caves", "Read the frozen log")
	# A torn corridor panel half-buried in ice. "It feels like home. It isn't home."
	Interactable.make_note(self, Vector3(6.0, 0.04, -3.0), "note_13", "Read the scratched panel")
	ActUtil.wall_scrawl(self, "IT IS ONE", Vector3(0, 2.4, -9.85), 0.0, 40, Color(0.45, 0.06, 0.07))
	ActUtil.wall_label(self, "THE CAVITY - 1114 m", Vector3(0, 3.4, 9.8), 18, Color(0.6, 0.78, 0.9))

	# Fill the cavern: ice rubble, the dangling drill string + cables, more nest.
	for rp in [Vector3(-2, 0, 8), Vector3(4, 0, 9), Vector3(-8, 0, -2), Vector3(8, 0, 2), Vector3(0, 0, -8)]:
		var rk := Chamber.make_prop_box(self, Vector3(randf_range(0.8, 1.6), randf_range(0.6, 1.4), randf_range(0.8, 1.6)), rp + Vector3(0, 0.4, 0), ICE, true, "ice")
		rk.rotation_degrees = Vector3(randf_range(-12, 12), randf_range(0, 360), randf_range(-12, 12))
	Chamber.make_prop_box(self, Vector3(0.18, 6.0, 0.18), Vector3(1.5, 4.0, -2), Color(0.30, 0.28, 0.22), false)
	for cc in [Vector3(-2, 4.5, 3), Vector3(3, 4.5, -5), Vector3(-5, 4.5, -2)]:
		Chamber.make_prop_box(self, Vector3(0.05, randf_range(1.5, 3.0), 0.05), cc, Color(0.12, 0.12, 0.14), false)
	for gp in [Vector3(-9, 0, 6), Vector3(9, 0, 8), Vector3(-3, 0, -9)]:
		ActUtil.signal_growth(self, gp, randf_range(1.2, 2.0), Color(0.07, 0.13, 0.12))
	ActUtil.hanging_corpse(self, Vector3(0, 4.4, 6), 2.0, Color(0.30, 0.36, 0.34))
	ActUtil.viscera(self, Vector3(6, 0.02, 5))
	ActUtil.viscera(self, Vector3(-5, 0.02, 8))

	ActUtil.add_dust_motes(self, Vector3(0, 2.0, 0), Vector3(11, 3, 10), 90, Color(0.7, 0.82, 0.95, 0.16))
