extends Node3D
# VESPER - ACT 1.5: THE OLD WING
# Between the bay and the dormitory. An older section of the station built for
# the previous rotation's larger crew; half-stripped when they downsized, half-
# flooded by a burst service line nobody bothered fixing. Empty bunks, missing
# fixtures, water staining the floors. The cold got here first, too. One
# peeker watches from the dark at the far end - same shape, different room.
#
# Layout mirrors Act 0: hand-crafted entry vestibule -> south-to-north spine
# of four chained corridor wings -> hand-crafted final passage. Each wing's
# north end is left UNSEALED (doorway at x=0); the next wing's south end is
# also unsealed at the same x=0 opening so they connect through one shared
# portal. Spacing is locked to the same 6/8/4-unit grid the rest of the
# station uses.

var _crossed := false
var _room_count := 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.09, 0.026)
	_build_entry_hall()
	_build_spine()
	_build_final_passage()

	ActUtil.haunt(self, {
		"intensity": 0.35, "flicker": true, "flicker_rate": 0.8,
		"peekers": [{"pos": Vector3(0, 0, -168.0), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0}],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 5.5)
		GameState.player.rotation_degrees.y = 180.0

	print("Act 1.5: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -169.5:
		_crossed = true
		SceneRouter.transition_to("act2")


# --- Hand-crafted entry vestibule (south, spawn) -------------------------

func _build_entry_hall() -> void:
	var wall := Color(0.30, 0.33, 0.38)
	var floor_c := Color(0.34, 0.36, 0.40)
	var ceil_c := Color(0.13, 0.14, 0.17)

	# x [-4, 4], z [0, 12], h=3.4. North wall opens (x=0) into the spine.
	Chamber.add_floor_ceiling(self, 8, 12, 3.4, floor_c, ceil_c, Vector3(0, 0, 6))
	Chamber.add_wall(self, "x", -4, 0, 12, 3.4, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, 3.4, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, 3.4, wall)
	Chamber.add_wall(self, "z",  0, -4, 4, 3.4, wall, 0.0)

	# Stripped-out vestibule: an empty fixture frame where a desk used to be,
	# a coat row half-emptied, water pooling out from under the threshold.
	Chamber.make_prop_box(self, Vector3(2.6, 0.08, 1.0), Vector3(-2.0, 0.60, 9.4), Color(0.28, 0.25, 0.20))
	Chamber.make_prop_box(self, Vector3(0.08, 1.2, 0.08), Vector3(-3.2, 0.60, 9.0), Color(0.18, 0.18, 0.20), false)
	Chamber.make_prop_box(self, Vector3(0.08, 1.2, 0.08), Vector3(-0.8, 0.60, 9.0), Color(0.18, 0.18, 0.20), false)
	Chamber.make_prop_box(self, Vector3(2.6, 0.06, 0.06), Vector3(-2.0, 2.20, 9.4), Color(0.20, 0.20, 0.22), false)
	for pj in 4:
		var pjx: float = 1.8 + pj * 0.45
		Chamber.make_prop_box(self, Vector3(0.36, 0.90, 0.22), Vector3(pjx, 1.40, 9.55), Color(0.22, 0.24, 0.28), false)
	Chamber.make_chair(self, Vector3(-1.4, 0, 7.0), Color(0.28, 0.30, 0.33), 200.0)
	Chamber.make_prop_box(self, Vector3(1.2, 0.1, 0.8), Vector3(2.6, 0.05, 7.6), Color(0.20, 0.18, 0.15), false)

	# Standing meltwater - pale blue puddles where the floor has dipped.
	for fz in [3.5, 4.6, 5.8, 7.0]:
		ActUtil.blood_decal(self, Vector3(-1.0 + fz * 0.18, 0.02, fz), Vector2(1.4, 1.0), "up",
			Color(0.62, 0.74, 0.88, 0.30))
	ActUtil.blood_decal(self, Vector3(1.4, 0.02, 4.0), Vector2(1.8, 1.4), "up",
		Color(0.62, 0.74, 0.88, 0.28))

	# A body slumped against the south wall - someone who never left when the
	# wing was condemned.
	ActUtil.corpse(self, Vector3(-2.8, 0, 11.2), 70.0, true, Color(0.22, 0.20, 0.18))

	# One hiding spot - a maintenance locker by the east wall.
	ActUtil.hide_locker(self, Vector3(3.3, 0, 4.0), -90.0)

	# An examine note explaining what this place is.
	Interactable.make_examine(self, Vector3(-3.92, 1.5, 5.4), Vector3(0.05, 0.6, 1.4),
		"Read the condemnation notice",
		"VESPER STATION - OLD WING. POSTED 14-3. Closed by station order pending " +
		"refit. Bunks 1-32 evacuated. Plumbing risers isolated; do not restore. " +
		"Personal effects to be removed by next supply. - There is no next supply. " +
		"The handwritten line under the print: 'twelve never came up to be moved.'", 6.5)

	ActUtil.wall_label(self, "OLD WING", Vector3(0, 3.0, 11.85), 24, Color(0.66, 0.78, 0.86))
	ActUtil.wall_label(self, "CONDEMNED", Vector3(0, 2.55, 11.85), 14, Color(0.80, 0.50, 0.40))
	_room_count += 1


# --- Procedural spine: four chained wings, south to north ----------------
# Each wing is a z-axis corridor at perp x=0, width 4. Adjacent wings share
# the boundary plane; both corridors center on x=0 and are width 4 so floors
# and side walls line up exactly - no seam, no overlap.
#
# Theme order tells a small story: dorm (the old bunks) -> dorm (the showers
# and mess) -> industrial (the burst service line that started the flooding)
# -> admin (the abandoned wing office). Each wing is 40 long with 4 rooms per
# side. 4 wings -> 36 procedural rooms, matching the locked spacing.

func _build_spine() -> void:
	# (theme, z_low, z_high, rooms_left, rooms_right, seed)
	var wings := [
		["dorm",       -40.0,    0.0, 4, 4, 115],
		["dorm",       -80.0,  -40.0, 4, 4, 225],
		["industrial",-120.0,  -80.0, 4, 4, 335],
		["admin",     -160.0, -120.0, 4, 4, 445],
	]
	for i in wings.size():
		var w: Array = wings[i]
		# Only the first wing seals its south end (the entry hall connects via
		# its own north doorway at x=0, z=0). All north ends are UNSEALED -
		# including the last wing's, whose opening at x=0, z=-160 the final
		# passage chains onto.
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


# --- Final passage (north tunnel to act 2's dormitory) -------------------

func _build_final_passage() -> void:
	var wall := Color(0.28, 0.31, 0.36)
	var floor_c := Color(0.32, 0.34, 0.38)
	var ceil_c := Color(0.12, 0.13, 0.16)

	# x [-2, 2], z [-170, -160], h=3.0. The last spine wing (z up to -160)
	# leaves its north end unsealed with a doorway at x=0; this passage's
	# south wall (z=-160) has the matching doorway, so they connect through
	# one opening. North end (z=-170) is the act-exit threshold.
	Chamber.add_floor_ceiling(self, 4, 10, 3.0, floor_c, ceil_c, Vector3(0, 0, -165))
	Chamber.add_wall(self, "x", -2, -170, -160, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -170, -160, 3.0, wall)
	Chamber.add_wall(self, "z", -170, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -160, -2, 2, 3.0, wall, 0.0)

	# A body left where it fell, water still running thin under the door,
	# growth creeping out of a wall vent.
	ActUtil.corpse(self, Vector3(1.2, 0, -164.0), -140.0, true, Color(0.20, 0.22, 0.24))
	ActUtil.blood_decal(self, Vector3(-0.5, 0.02, -167.0), Vector2(2.4, 1.6), "up",
		Color(0.60, 0.72, 0.86, 0.32))
	ActUtil.signal_growth(self, Vector3(-1.3, 0, -168.0), 1.0, Color(0.07, 0.13, 0.10))

	# One hiding spot just before the next act's threshold.
	ActUtil.hide_locker(self, Vector3(1.65, 0, -166.5), -90.0)

	ActUtil.wall_scrawl(self, "THEY DID NOT GO UP", Vector3(0, 2.2, -169.85), 0.0, 20, Color(0.50, 0.06, 0.06))
	ActUtil.wall_label(self, "DORM ACCESS", Vector3(0, 2.6, -169.7), 13, Color(0.7, 0.84, 0.9))
	_room_count += 1
