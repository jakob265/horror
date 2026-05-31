extends Node3D
# VESPER - ACT 0: THE OUTER STATION
# Walking in. The arrival annex you crossed when the Sno-Cat dropped you:
# customs, admin offices, security, a long storage spine. Procedurally laid
# out so the station reads as a PLACE, not a level. No hunter; the cold took
# everyone already. One peeker watches from the dark at the far end.
#
# Layout is a single south->north spine of chained corridor wings. Each wing's
# north end is left UNSEALED (doorway at x=0); the next wing's south end is
# also unsealed at the same x=0, so they connect through one shared opening.
# Wings never run perpendicular, so side rooms never collide.

var _crossed := false
var _room_count := 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.10, 0.024)
	_build_entry_hall()
	_build_spine()
	_build_final_passage()

	ActUtil.haunt(self, {
		"intensity": 0.30, "flicker": true, "flicker_rate": 0.7,
		"peekers": [{"pos": Vector3(0, 0, -204.0), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0}],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 5.5)
		GameState.player.rotation_degrees.y = 180.0

	print("Act 0: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -205.5:
		_crossed = true
		SceneRouter.transition_to("act1")


# --- Hand-crafted entry hall (south, spawn) ------------------------------

func _build_entry_hall() -> void:
	var wall := Color(0.32, 0.34, 0.38)
	var floor_c := Color(0.36, 0.38, 0.42)
	var ceil_c := Color(0.14, 0.15, 0.18)

	# x [-4, 4], z [0, 12], h=3.6. North wall opens (x=0) into the spine.
	Chamber.add_floor_ceiling(self, 8, 12, 3.6, floor_c, ceil_c, Vector3(0, 0, 6))
	Chamber.add_wall(self, "x", -4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, 3.6, wall)
	Chamber.add_wall(self, "z",  0, -4, 4, 3.6, wall, 0.0)

	Chamber.make_prop_box(self, Vector3(2.4, 1.0, 1.0), Vector3(-1.5, 0.50, 9.0), Color(0.30, 0.27, 0.22))
	Chamber.make_prop_box(self, Vector3(2.4, 0.1, 1.2), Vector3(-1.5, 1.05, 9.0), Color(0.40, 0.36, 0.28))
	Chamber.make_chair(self, Vector3(-1.5, 0, 7.8), Color(0.30, 0.31, 0.34), 180.0)
	Chamber.make_prop_box(self, Vector3(0.8, 0.5, 0.5), Vector3(2.2, 0.25, 10.0), Color(0.55, 0.30, 0.20))
	for fz in [5.0, 4.0, 3.0]:
		ActUtil.blood_decal(self, Vector3(0.6, 0.02, fz), Vector2(0.5, 0.8), "up",
			Color(0.70, 0.78, 0.90, 0.20))
	ActUtil.corpse(self, Vector3(1.6, 0, 11.0), -60.0, true, Color(0.20, 0.22, 0.26))
	Interactable.make_examine(self, Vector3(-1.4, 1.10, 8.8), Vector3(0.05, 0.30, 0.40),
		"Read the customs board",
		"Customs receipt board, names crossed off one per line through the rotation. " +
		"The latest entry, hand-printed at the bottom: 'NO MORE COMING. " +
		"NO ONE TO BE SIGNED OUT.'", 6.0)
	ActUtil.wall_label(self, "OUTER STATION", Vector3(0, 3.0, 11.85), 24, Color(0.7, 0.84, 0.9))
	_room_count += 1


# --- Procedural spine: four chained wings, south to north ----------------
# Each wing is a z-axis corridor at perp x=0, width 4. Adjacent wings share
# the boundary plane: wing A's high (north) end is unsealed; wing B sits
# directly north of it with its low (south) end unsealed at the same x=0
# opening. Because both corridors center on x=0 and are width 4, their floors
# and side walls line up exactly - no seam, no overlap.

func _build_spine() -> void:
	# (theme, z_low, z_high, rooms_left, rooms_right, seed)
	# Each wing is 40 long with 4 rooms/side => doors spaced 10 apart, ~4-unit
	# gaps between the 6-wide rooms (same density as the locked-in spacing,
	# just more rooms per wing). 5 wings = 5 themes = 45 procedural rooms.
	var wings := [
		["admin",      -40.0,    0.0, 4, 4, 110],
		["dorm",       -80.0,  -40.0, 4, 4, 220],
		["lab",       -120.0,  -80.0, 4, 4, 330],
		["industrial",-160.0, -120.0, 4, 4, 440],
		["industrial",-196.0, -160.0, 3, 4, 550],
	]
	for i in wings.size():
		var w: Array = wings[i]
		# South end sealed only for the first wing (the entry hall connects via
		# its own north doorway at x=0, z=0). Every north end is UNSEALED -
		# including the last wing's, whose opening at x=0, z=-196 the final
		# passage chains onto. So no wing seals its north; only the very first
		# wing seals its south.
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


# --- Final passage (north tunnel to act 1's bay) -------------------------

func _build_final_passage() -> void:
	var wall := Color(0.30, 0.32, 0.36)
	var floor_c := Color(0.34, 0.36, 0.40)
	var ceil_c := Color(0.13, 0.14, 0.17)

	# x [-2, 2], z [-206, -196], h=3.0. The last spine wing (z up to -196)
	# leaves its north end unsealed with a doorway at x=0; this passage's
	# south wall (z=-196) has the matching doorway, so they connect through
	# one opening. North end (z=-206) is the act-exit threshold.
	Chamber.add_floor_ceiling(self, 4, 10, 3.0, floor_c, ceil_c, Vector3(0, 0, -201))
	Chamber.add_wall(self, "x", -2, -206, -196, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -206, -196, 3.0, wall)
	Chamber.add_wall(self, "z", -206, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -196, -2, 2, 3.0, wall, 0.0)

	ActUtil.corpse(self, Vector3(-1.2, 0, -200.0), 35.0, true, Color(0.22, 0.24, 0.28))
	ActUtil.signal_growth(self, Vector3(1.3, 0, -204.0), 1.2, Color(0.07, 0.13, 0.10))
	ActUtil.wall_scrawl(self, "VESPER WAITS", Vector3(0, 2.2, -205.85), 0.0, 22, Color(0.50, 0.06, 0.06))
	ActUtil.wall_label(self, "BAY ACCESS", Vector3(0, 2.6, -205.7), 13, Color(0.7, 0.84, 0.9))
	_room_count += 1
