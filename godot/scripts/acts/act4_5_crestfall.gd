extends Node3D
# VESPER - ACT 4.5: CRESTFALL-9
# The sister station alluded to in the recovered tablet. A wormholed underground
# passage connects Vesper's research deck to this older drill station: Crestfall-9.
# Same experiments, abandoned earlier and more thoroughly. The largest stretch in
# the game by room count: an administrative entry block, paired research wings,
# crew dormitory, and two industrial sections trailing off into the dark.
#
# Layout follows the proven outer-station pattern: a hand-crafted entry hall, a
# south->north procedural spine of six chained corridor wings, and a hand-crafted
# final passage that opens onto Act 5's generator vestibule.

var _crossed := false
var _room_count := 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.09, 0.026)
	_build_entry_hall()
	_build_spine()
	_build_final_passage()

	ActUtil.haunt(self, {
		"intensity": 0.55, "flicker": true, "flicker_rate": 1.1,
		"peekers": [
			{"pos": Vector3(0, 0, -244.0), "kind": HorrorShape.KIND_FELIX, "rot": 0.0},
			{"pos": Vector3(1.4, 0, -247.0), "kind": HorrorShape.KIND_YUNA, "rot": 200.0},
		],
		"lurkers": [
			{"kind": HorrorShape.KIND_YUNA, "creep": 0.65, "points": [
				Vector3(0, 0, -90.0),
				Vector3(0, 0, -110.0),
				Vector3(0, 0, -130.0),
				Vector3(0, 0, -150.0),
			]},
		],
	})

	if GameState.player:
		var spawn: Vector3 = Vector3(0, 0.5, 5.5)
		GameState.player.global_position = spawn
		GameState.player.rotation_degrees.y = 180.0

	print("Act 4.5: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -249.5:
		_crossed = true
		SceneRouter.transition_to("act5")


# --- Hand-crafted entry hall (Vesper-Crestfall interconnect tunnel) ------
# A wider, older arrival vestibule. The wormhole behind you, Crestfall-9 ahead.
# Floor plates buckled, two derelict hide-lockers against the side walls, a
# bolted welcome board with the first note. North wall opens (x=0) into the
# spine's first wing (admin).

func _build_entry_hall() -> void:
	var wall: Color = Color(0.30, 0.32, 0.36)
	var floor_c: Color = Color(0.34, 0.36, 0.40)
	var ceil_c: Color = Color(0.13, 0.14, 0.17)

	# x [-4, 4], z [0, 12], h=3.6. North wall opens (x=0) into the spine.
	Chamber.add_floor_ceiling(self, 8, 12, 3.6, floor_c, ceil_c, Vector3(0, 0, 6))
	Chamber.add_wall(self, "x", -4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, 3.6, wall)
	Chamber.add_wall(self, "z",  0, -4, 4, 3.6, wall, 0.0)

	# Wormhole frame at the south end - irradiated, faintly glowing.
	Chamber.make_prop_box(self, Vector3(7.6, 0.4, 0.6), Vector3(0, 0.2, 11.4), Color(0.18, 0.20, 0.24))
	Chamber.make_prop_box(self, Vector3(0.6, 3.0, 0.6), Vector3(-3.5, 1.5, 11.4), Color(0.18, 0.20, 0.24))
	Chamber.make_prop_box(self, Vector3(0.6, 3.0, 0.6), Vector3( 3.5, 1.5, 11.4), Color(0.18, 0.20, 0.24))
	ActUtil.signal_growth(self, Vector3(0, 0, 10.8), 1.6, Color(0.07, 0.13, 0.10))
	ActUtil.signal_growth(self, Vector3(-2.4, 0, 10.0), 1.0, Color(0.08, 0.13, 0.10))

	# A pair of welded crates, a tilted chair, a long-cold coffee tin.
	Chamber.make_prop_box(self, Vector3(2.4, 1.0, 1.0), Vector3(2.0, 0.50, 8.6), Color(0.30, 0.27, 0.22))
	Chamber.make_prop_box(self, Vector3(1.4, 0.6, 1.0), Vector3(2.6, 0.30, 7.4), Color(0.28, 0.26, 0.22))
	Chamber.make_chair(self, Vector3(-1.8, 0, 7.6), Color(0.30, 0.31, 0.34), 120.0)
	Chamber.make_prop_box(self, Vector3(0.2, 0.25, 0.2), Vector3(-1.6, 1.15, 8.4), Color(0.50, 0.30, 0.18), false)

	# Blood smear leading from the south wormhole inward.
	for fz in [10.5, 9.5, 8.5, 7.5]:
		ActUtil.blood_decal(self, Vector3(-0.6, 0.02, fz), Vector2(0.7, 0.9), "up",
			Color(0.60, 0.10, 0.12, 0.55))
	ActUtil.corpse(self, Vector3(-2.4, 0, 9.6), 30.0, true, Color(0.20, 0.22, 0.26))

	# Two hide-lockers tucked against the side walls.
	ActUtil.hide_locker(self, Vector3(-3.4, 0, 6.0), 90.0)
	ActUtil.hide_locker(self, Vector3( 3.4, 0, 4.5), -90.0)

	# Welcome board / entry note.
	Interactable.make_examine(self, Vector3(-3.85, 1.20, 4.0), Vector3(0.05, 0.35, 0.45),
		"Read the entrance plaque",
		"A brass entrance plaque, bolted to the wall, half-eaten by frost: " +
		"'CRESTFALL-9 ARRIVAL. PHASE-II DRILL STATION. ALL CREW SIGN IN AT ADMIN.' " +
		"Underneath, a fresher scratch, sharper than the engraving: " +
		"'WHAT HAPPENED HERE HAPPENED FIRST.'", 7.0)

	ActUtil.wall_label(self, "CRESTFALL-9", Vector3(0, 3.0, 11.85), 24, Color(0.7, 0.84, 0.9))
	ActUtil.wall_scrawl(self, "SAME WORK. EARLIER START.", Vector3(0, 2.2, 0.15), 180.0, 18, Color(0.55, 0.08, 0.08))
	_room_count += 1


# --- Procedural spine: six chained wings, south to north -----------------
# Each wing is a z-axis corridor at perp x=0, width 4. Adjacent wings share
# the boundary plane: wing A's north end unsealed, wing B's south end unsealed
# at the same x=0 opening. Themes mirror Vesper's organisation - admin at the
# threshold, paired labs (the same experiments started here first), dorm,
# then two industrial wings trailing off toward the deep drill.

func _build_spine() -> void:
	# (theme, z_low, z_high, rooms_left, rooms_right, seed)
	var wings: Array = [
		["admin",       -40.0,    0.0, 4, 4, 1010],
		["lab",         -80.0,  -40.0, 4, 4, 2020],
		["lab",        -120.0,  -80.0, 4, 4, 3030],
		["dorm",       -160.0, -120.0, 4, 4, 4040],
		["industrial", -200.0, -160.0, 4, 4, 5050],
		["industrial", -240.0, -200.0, 4, 4, 6060],
	]
	for i in wings.size():
		var w: Array = wings[i]
		# Only the very first wing seals its south end (the entry hall connects
		# via its own north doorway at x=0, z=0). All north ends remain open;
		# the last wing's north opening at x=0, z=-240 hands off to the final
		# passage. No wing seals its north end.
		var seal_south: bool = (i == 0)
		var seal_north: bool = false
		_room_count += RoomGen.stamp_corridor_wing(self, {
			"theme": w[0],
			"axis": "z",
			"along_min": float(w[1]), "along_max": float(w[2]),
			"perp": 0.0,
			"corridor_w": 4.0, "corridor_h": 3.4,
			"rooms_left": int(w[3]), "rooms_right": int(w[4]),
			"room_depth": 8.0, "room_w_along": 6.0, "room_h": 3.2,
			"seal_low_end": seal_south, "seal_high_end": seal_north,
			"seed": int(w[5]),
		})


# --- Final passage (north tunnel to act 5's generator vestibule) ---------

func _build_final_passage() -> void:
	var wall: Color = Color(0.28, 0.30, 0.34)
	var floor_c: Color = Color(0.32, 0.34, 0.38)
	var ceil_c: Color = Color(0.12, 0.13, 0.16)

	# x [-2, 2], z [-250, -240], h=3.0. The last spine wing (z up to -240)
	# leaves its north end unsealed with a doorway at x=0; this passage's
	# south wall (z=-240) carries the matching doorway. North end (z=-250)
	# is the act-exit threshold.
	Chamber.add_floor_ceiling(self, 4, 10, 3.0, floor_c, ceil_c, Vector3(0, 0, -245))
	Chamber.add_wall(self, "x", -2, -250, -240, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -250, -240, 3.0, wall)
	Chamber.add_wall(self, "z", -250, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -240, -2, 2, 3.0, wall, 0.0)

	# Hide-lockers against the side walls - the peekers wait at the far end.
	ActUtil.hide_locker(self, Vector3(-1.6, 0, -242.0),  90.0)
	ActUtil.hide_locker(self, Vector3( 1.6, 0, -242.0), -90.0)

	# Horror dressing: bodies arranged at the threshold, growth, blood.
	ActUtil.corpse(self, Vector3(-1.2, 0, -245.0), 60.0, true, Color(0.22, 0.24, 0.28))
	ActUtil.corpse(self, Vector3( 1.2, 0, -247.0), -45.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.signal_growth(self, Vector3(1.3, 0, -248.0), 1.4, Color(0.07, 0.13, 0.10))
	ActUtil.signal_growth(self, Vector3(-1.3, 0, -246.5), 1.0, Color(0.08, 0.13, 0.10))
	ActUtil.blood_decal(self, Vector3(0.0, 0.02, -244.0), Vector2(1.4, 1.2), "up",
		Color(0.55, 0.08, 0.10, 0.60))

	# Two notes inline. First: a station log fragment. Second: a hand-written
	# message that arrived here from Vesper before Vesper existed.
	Interactable.make_examine(self, Vector3(-1.85, 1.20, -244.5), Vector3(0.05, 0.30, 0.40),
		"Read the station log fragment",
		"A torn page from Crestfall's operations log, frost-bonded to the wall: " +
		"'Day 219. The samples are listening. They turn toward the radio before " +
		"the call comes. Day 221. They learned my wife's voice. I never told it. " +
		"Day 222. We're sealing the drill. If Vesper opens this far south, tell " +
		"them: it isn't a sample. It's an echo of us, coming back. Don't answer.'", 8.0)
	Interactable.make_examine(self, Vector3( 1.85, 1.20, -246.0), Vector3(0.05, 0.30, 0.40),
		"Read the pinned letter",
		"A letter pinned to the wall with a surgical pin, in a hand none of us " +
		"have seen yet: 'You will arrive after we are gone. We did what you are " +
		"doing. We named it what you will name it. What happened here happened " +
		"first - and it will happen there next, in the same order, by the same " +
		"hands. The seed remembers the gardener.'", 8.0)

	ActUtil.wall_scrawl(self, "WE WERE YOU FIRST", Vector3(0, 2.3, -249.85), 0.0, 22, Color(0.55, 0.06, 0.06))
	ActUtil.wall_label(self, "GENERATOR ACCESS", Vector3(0, 2.6, -249.7), 13, Color(0.7, 0.84, 0.9))
	_room_count += 1
