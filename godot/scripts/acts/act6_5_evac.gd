extends Node3D
# VESPER - ACT 6.5: EVAC SUBLEVEL
# Directly below the morgue. The mustering deck the crew tried to fall back
# to when the rotation went bad. Sno-Cats they were prepping never left;
# half-packed grab-bags, an inventory hatch hanging open, names struck out
# on a roster. Industrial corridors lined with abandoned evac gear, supply
# caches, and the dead.
#
# Same proven layout as Act 0: hand-crafted entry hall (the morgue freezer
# dropped you here), procedural south->north spine of corridor wings, hand-
# crafted final passage to the shaft head. One lurker pacing the middle of
# the spine. One peeker at the very far end.

var _crossed: bool = false
var _room_count: int = 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.06, 0.028)
	_build_entry_hall()
	_build_spine()
	_build_final_passage()

	ActUtil.haunt(self, {
		"intensity": 0.45, "flicker": true, "flicker_rate": 0.85,
		"lurkers": [
			{
				"points": [
					Vector3(0, 0, -90.0),
					Vector3(0, 0, -100.0),
					Vector3(0, 0, -110.0),
					Vector3(0, 0, -100.0),
				],
				"kind": HorrorShape.KIND_YUNA, "creep": 0.55,
			},
		],
		"peekers": [
			{"pos": Vector3(0, 0, -208.5), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 5.5)
		GameState.player.rotation_degrees.y = 180.0

	print("Act 6.5: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -209.5:
		_crossed = true
		SceneRouter.transition_to("act7")


# --- Hand-crafted entry hall (south, spawn) ------------------------------
# The morgue freezer dropped you in here. Z runs [0, 12], north wall opens
# at x=0 into the spine. Industrial cast: bare bulkhead, kit racks, the
# mustering board with names struck out.

func _build_entry_hall() -> void:
	var wall: Color = Color(0.30, 0.32, 0.36)
	var floor_c: Color = Color(0.34, 0.36, 0.40)
	var ceil_c: Color = Color(0.13, 0.14, 0.17)

	Chamber.add_floor_ceiling(self, 8, 12, 3.6, floor_c, ceil_c, Vector3(0, 0, 6))
	Chamber.add_wall(self, "x", -4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, 3.6, wall)
	Chamber.add_wall(self, "z",  0, -4, 4, 3.6, wall, 0.0)

	# Mustering kit bench + half-packed grab-bag spilled across it.
	Chamber.make_prop_box(self, Vector3(2.6, 1.0, 1.0), Vector3(-1.8, 0.50, 9.4), Color(0.30, 0.32, 0.36))
	Chamber.make_prop_box(self, Vector3(2.6, 0.10, 1.2), Vector3(-1.8, 1.05, 9.4), Color(0.40, 0.42, 0.46))
	Chamber.make_prop_box(self, Vector3(0.7, 0.5, 0.5), Vector3(-1.4, 1.35, 9.6), Color(0.55, 0.30, 0.18))
	Chamber.make_prop_box(self, Vector3(0.4, 0.4, 0.4), Vector3(-2.4, 1.30, 9.0), Color(0.30, 0.27, 0.22))
	# Evac kit pegs along the east wall — most pegs empty, two bags still hanging.
	for ez in [4.4, 6.4, 8.4, 10.4]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.30, 0.30), Vector3(3.95, 1.95, ez), Color(0.18, 0.20, 0.24), false)
	Chamber.make_prop_box(self, Vector3(0.5, 0.9, 0.4), Vector3(3.65, 1.40, 6.4), Color(0.46, 0.30, 0.20))
	Chamber.make_prop_box(self, Vector3(0.5, 0.9, 0.4), Vector3(3.65, 1.40, 10.4), Color(0.46, 0.30, 0.20))
	# Stretcher slumped against the south wall.
	Chamber.make_prop_box(self, Vector3(0.6, 0.10, 2.4), Vector3(2.6, 0.05, 11.0), Color(0.40, 0.42, 0.46))
	Chamber.make_chair(self, Vector3(-1.8, 0, 7.6), Color(0.28, 0.30, 0.34), 180.0)
	# A body collapsed by the bench, grab-bag still on his shoulder.
	ActUtil.corpse(self, Vector3(-0.6, 0, 8.6), 45.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_decal(self, Vector3(-0.6, 0.02, 8.6), Vector2(1.2, 1.0), "up",
		Color(0.22, 0.04, 0.05, 0.75))
	# Frost where the morgue cold leaks through the threshold above.
	for fz in [10.5, 11.0, 11.5]:
		ActUtil.blood_decal(self, Vector3(0.0, 0.02, fz), Vector2(0.7, 0.6), "up",
			Color(0.70, 0.78, 0.90, 0.18))

	# The mustering board: every name crossed off. Examine for the failed evac.
	Interactable.make_examine(self, Vector3(-3.85, 1.20, 9.4), Vector3(0.05, 0.30, 0.40),
		"Read the mustering roster",
		"Steel clipboard wired to the bulkhead. Roster of twenty-two for evac " +
		"rotation. Every name struck through with the same marker, hard enough " +
		"to gouge the paper. At the bottom in different handwriting: 'NO ONE " +
		"WENT UP. THE CATS ARE STILL OUT FRONT. WE CAME BACK DOWN BECAUSE WE " +
		"HEARD THEM CALLING US FROM THE SHAFT.'", 7.5)
	ActUtil.wall_label(self, "EVAC SUBLEVEL", Vector3(0, 3.0, 11.85), 22, Color(0.78, 0.84, 0.6))
	ActUtil.wall_label(self, "MUSTER POINT", Vector3(-3.9, 2.55, 6.0), 13, Color(0.78, 0.84, 0.6))
	ActUtil.wall_scrawl(self, "NO ONE WENT UP", Vector3(0, 2.1, 11.85), 0.0, 22, Color(0.50, 0.06, 0.06))

	# One hide locker tucked in the SE corner of the muster hall.
	ActUtil.hide_locker(self, Vector3(3.5, 0, 2.0), -90.0)

	_room_count += 1


# --- Procedural spine: five chained wings, south to north ----------------
# Each wing is a z-axis corridor at x=0, width 4, 40 long. Adjacent wings
# share the boundary plane (north of A is unsealed, south of B is unsealed
# at the same x=0 gap), so they connect seam-perfect through one shared
# opening. 5 wings * (1 corridor + 4 + 4 side rooms) = 45 procedural rooms.
# Wing themes south->north: industrial, dorm, industrial, industrial, dorm
# - the deck reads as kit/lockers/mess/kit/bunks; the abandoned mustering
# floor below the morgue.

func _build_spine() -> void:
	var wings: Array = [
		["industrial", -40.0,    0.0, 4, 4, 660],
		["dorm",       -80.0,  -40.0, 4, 4, 770],
		["industrial",-120.0,  -80.0, 4, 4, 880],
		["industrial",-160.0, -120.0, 4, 4, 990],
		["dorm",      -200.0, -160.0, 4, 4, 1010],
	]
	for i in wings.size():
		var w: Array = wings[i]
		# Only the very first wing seals its south end (the entry hall mates onto
		# its south doorway). Every north end is UNSEALED - including the last
		# wing's, which the final passage chains onto at x=0, z=-200.
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


# --- Final passage (north tunnel to act 7's shaft head) ------------------
# z [-210, -200], width 4. Mates onto the last wing's north opening at
# x=0, z=-200 and ends in the act-exit threshold at z=-210. Two more
# examine notes here lay out what the failed evac actually was.

func _build_final_passage() -> void:
	var wall: Color = Color(0.28, 0.30, 0.34)
	var floor_c: Color = Color(0.32, 0.34, 0.38)
	var ceil_c: Color = Color(0.12, 0.13, 0.16)

	Chamber.add_floor_ceiling(self, 4, 10, 3.0, floor_c, ceil_c, Vector3(0, 0, -205))
	Chamber.add_wall(self, "x", -2, -210, -200, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -210, -200, 3.0, wall)
	Chamber.add_wall(self, "z", -210, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -200, -2, 2, 3.0, wall, 0.0)

	# Supply cache shoved against the east wall - crates, a torn-open med kit.
	Chamber.make_prop_box(self, Vector3(0.6, 0.8, 1.2), Vector3(1.4, 0.40, -203.0), Color(0.40, 0.30, 0.18))
	Chamber.make_prop_box(self, Vector3(0.6, 0.5, 0.8), Vector3(1.4, 0.25, -204.5), Color(0.55, 0.30, 0.20))
	Chamber.make_prop_box(self, Vector3(0.5, 0.3, 0.5), Vector3(1.5, 0.85, -203.0), Color(0.85, 0.85, 0.82), false)
	# A body crumpled against the cache, hand still on the kit.
	ActUtil.corpse(self, Vector3(0.6, 0, -202.5), 110.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_decal(self, Vector3(0.6, 0.02, -202.5), Vector2(1.4, 1.2), "up",
		Color(0.22, 0.04, 0.05, 0.80))
	# Drag trail running north — something pulled this one toward the shaft.
	ActUtil.blood_decal(self, Vector3(-0.4, 0.02, -204.0), Vector2(0.6, 1.4), "up",
		Color(0.22, 0.04, 0.05, 0.55))
	ActUtil.blood_decal(self, Vector3(-0.6, 0.02, -206.0), Vector2(0.5, 1.4), "up",
		Color(0.22, 0.04, 0.05, 0.45))
	ActUtil.blood_decal(self, Vector3(-0.7, 0.02, -208.0), Vector2(0.5, 1.4), "up",
		Color(0.22, 0.04, 0.05, 0.35))
	# Signal growth taking the wall on the far end — the shaft is right there.
	ActUtil.signal_growth(self, Vector3(-1.3, 0, -208.5), 1.3, Color(0.07, 0.13, 0.10))

	# Two hide lockers wedged in the cramped passage — you'll want them with
	# the peeker watching from the head of the shaft.
	ActUtil.hide_locker(self, Vector3(-1.5, 0, -202.5), 90.0)
	ActUtil.hide_locker(self, Vector3(-1.5, 0, -206.5), 90.0)

	# Examine 2: the radio call that never went out.
	Interactable.make_examine(self, Vector3(1.85, 1.15, -201.5), Vector3(0.05, 0.30, 0.36),
		"Read the radio log",
		"Field radio still keyed open, log sheet clipped to the strap. Last " +
		"transmission attempt: 'PRINCE ALBERT, EVAC FOUR, ANY RAVEN. WE ARE " +
		"NOT COMING UP. THE CATS WILL NOT START. WE CAN HEAR EACH OTHER ON " +
		"THE SHAFT INTERCOM AND WE ARE NOT THE ONES TALKING. DO NOT SEND " +
		"ANOTHER ROTATION.' Time-coded six days ago. The PTT button is " +
		"still depressed.", 8.0)
	# Examine 3: the duty-officer's last note, taped to the bulkhead.
	Interactable.make_examine(self, Vector3(-1.85, 1.10, -207.0), Vector3(0.05, 0.30, 0.36),
		"Read the duty note",
		"Index card taped to the bulkhead in shaking hand: 'they called " +
		"the muster down. we mustered. then we heard ourselves call the " +
		"muster down again from the shaft. lukas went to look. ten of us " +
		"went after lukas. none of us came back the right number. don't " +
		"answer the intercom. don't board the cage if it comes up empty.'", 8.0)

	ActUtil.wall_scrawl(self, "DON'T BOARD EMPTY", Vector3(0, 2.2, -209.85), 0.0, 20, Color(0.50, 0.06, 0.06))
	ActUtil.wall_label(self, "SHAFT HEAD", Vector3(0, 2.6, -209.7), 13, Color(0.78, 0.84, 0.6))
	_room_count += 1
