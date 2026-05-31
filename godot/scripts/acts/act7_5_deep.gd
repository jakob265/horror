extends Node3D
# VESPER - ACT 7.5: DEEP DRILL 1500-2000m
# Between the borehole derrick at 1114m and the natural ice cavity below,
# the engineers drilled a service spine straight down through the strata
# and then turned the cage runs sideways at five sub-levels. The cage
# dropped you into the topmost. Walk north through each level, descend
# stair after stair, until the bored-out concrete gives way to the ice
# the drill never finished cutting and you're standing in the cavity's
# own throat.
#
# Six chained corridor wings, south->north, each a "drill-down level":
# industrial, industrial, lab, industrial, ice, ice. The cavity's growth
# thickens with depth. One peeker watches at the bottom of the descent.

var _crossed: bool = false
var _room_count: int = 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.08, 0.030)
	_build_entry_hall()
	_build_spine()
	_build_final_passage()

	ActUtil.haunt(self, {
		"intensity": 0.50, "flicker": true, "flicker_rate": 1.1,
		"lurkers": [
			{"kind": HorrorShape.KIND_FELIX, "creep": 0.55, "points": [
				Vector3(0, 0, -90.0), Vector3(-6, 0, -100.0), Vector3(0, 0, -110.0),
				Vector3(6, 0, -100.0), Vector3(0, 0, -85.0),
			]},
			{"kind": HorrorShape.KIND_HARGROVE, "creep": 0.50, "points": [
				Vector3(0, 0, -135.0), Vector3(-5, 0, -148.0), Vector3(5, 0, -155.0),
				Vector3(0, 0, -140.0), Vector3(-6, 0, -130.0),
			]},
		],
		"peekers": [
			{"pos": Vector3(0, 0, -247.5), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 5.5)
		GameState.player.rotation_degrees.y = 180.0

	print("Act 7.5: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -249.5:
		_crossed = true
		SceneRouter.transition_to("act8")


# --- Hand-crafted entry hall (cage drop, south, spawn) -------------------
# The cage from Act 7 set you down here. The hall is poured concrete with
# the service-spine signage still painted on the wall. North wall opens
# (x=0) into the first procedural wing at z=0.

func _build_entry_hall() -> void:
	var wall: Color = Color(0.28, 0.30, 0.34)
	var floor_c: Color = Color(0.32, 0.34, 0.38)
	var ceil_c: Color = Color(0.11, 0.12, 0.15)

	# x [-4, 4], z [0, 12], h=3.6. North wall opens (x=0) into the spine.
	Chamber.add_floor_ceiling(self, 8, 12, 3.6, floor_c, ceil_c, Vector3(0, 0, 6))
	Chamber.add_wall(self, "x", -4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, 3.6, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, 3.6, wall)
	Chamber.add_wall(self, "z",  0, -4, 4, 3.6, wall, 0.0)

	# The cage shaft above: a black square overhead with rails dangling.
	var shaft_cap: MeshInstance3D = MeshInstance3D.new()
	var sb: BoxMesh = BoxMesh.new()
	sb.size = Vector3(2.4, 0.05, 2.4)
	shaft_cap.mesh = sb
	shaft_cap.position = Vector3(0, 3.58, 10.5)
	var sm: StandardMaterial3D = StandardMaterial3D.new()
	sm.albedo_color = Color(0.01, 0.01, 0.015)
	shaft_cap.material_override = sm
	add_child(shaft_cap)
	# Cage floor plate left behind where it came to rest.
	Chamber.make_prop_box(self, Vector3(2.0, 0.12, 2.0), Vector3(0, 0.06, 10.5), Color(0.28, 0.29, 0.32), false)
	for cx in [-0.9, 0.9]:
		for cz in [9.6, 11.4]:
			Chamber.make_prop_box(self, Vector3(0.08, 2.2, 0.08), Vector3(cx, 1.1, cz), Color(0.34, 0.35, 0.38), false)
	# Drill log board + a stack of charts.
	Chamber.make_prop_box(self, Vector3(2.6, 1.0, 0.8), Vector3(-1.6, 0.50, 7.0), Color(0.30, 0.27, 0.20))
	Chamber.make_prop_box(self, Vector3(2.6, 0.10, 1.0), Vector3(-1.6, 1.05, 7.0), Color(0.42, 0.38, 0.28))
	Chamber.make_prop_box(self, Vector3(0.5, 0.05, 0.7), Vector3(-1.6, 1.13, 7.0), Color(0.78, 0.74, 0.62))
	# A worker's overcoat slumped against a crate.
	ActUtil.corpse(self, Vector3(2.4, 0, 8.0), -75.0, true, Color(0.22, 0.20, 0.16))
	ActUtil.blood_decal(self, Vector3(2.0, 0.02, 6.0), Vector2(0.9, 1.4), "up", Color(0.18, 0.10, 0.05, 0.55))

	# Hide niche tucked against the east wall (one only in the entry hall).
	ActUtil.hide_locker(self, Vector3(3.4, 0, 3.5), -90.0)

	# Signage and the drill-pattern examine note.
	ActUtil.wall_label(self, "SERVICE SPINE - LVL D1 - 1500 m", Vector3(0, 3.0, 11.85), 16, Color(0.7, 0.82, 0.88))
	ActUtil.wall_scrawl(self, "WE DRILLED DOWN TO MEET IT", Vector3(0, 2.1, -0.15), 180.0, 22, Color(0.45, 0.06, 0.07))
	Interactable.make_examine(self, Vector3(-1.55, 1.18, 7.0), Vector3(0.05, 0.30, 0.40),
		"Read the drill pattern",
		"A pinned schematic of the service spine. Five sub-levels, each set " +
		"a hundred metres deeper than the last, each turned ninety degrees " +
		"from the cage shaft so the boys could lay out side bays for pumps " +
		"and stores. The note pencilled across the bottom in a different hand: " +
		"'D5 is not lined. D5 is what was already there. we just opened it.'", 6.0)
	_room_count += 1


# --- Procedural spine: six chained drill-down levels, south to north -----
# Each wing is a z-axis corridor at perp x=0, width 4. Adjacent wings share
# the boundary plane: wing A's high (north) end is unsealed; wing B sits
# directly north of it with its low (south) end unsealed at the same x=0
# opening. Because both corridors center on x=0 and are width 4, their floors
# and side walls line up exactly - no seam, no overlap. Theme gradient walks
# from industrial through lab into ice, mirroring the descent.

func _build_spine() -> void:
	# (theme, z_low, z_high, rooms_left, rooms_right, seed)
	# Each wing is 40 long with 4 rooms/side => 8 side rooms + corridor = 9
	# rooms per wing. 6 wings = 54 procedural rooms.
	var wings: Array = [
		["industrial", -40.0,    0.0, 4, 4, 1500],
		["industrial", -80.0,  -40.0, 4, 4, 1600],
		["lab",       -120.0,  -80.0, 4, 4, 1700],
		["industrial",-160.0, -120.0, 4, 4, 1800],
		["ice",       -200.0, -160.0, 4, 4, 1900],
		["ice",       -240.0, -200.0, 4, 4, 2000],
	]
	for i in wings.size():
		var w: Array = wings[i]
		# South end sealed only for the first wing (the entry hall connects
		# via its own north doorway at x=0, z=0). Every north end is UNSEALED
		# - including the last wing's, whose opening at x=0, z=-240 the
		# final passage chains onto. So no wing seals its north; only the
		# very first wing seals its south.
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


# --- Final passage (north tunnel into act 8's cavity) --------------------
# Concrete liner gives way mid-passage to bare ice. The last spine wing
# (z up to -240) leaves its north end unsealed at x=0; this passage's
# south wall at z=-240 has the matching doorway. North end (z=-250) is
# the act-exit threshold.

func _build_final_passage() -> void:
	var wall: Color = Color(0.34, 0.42, 0.52)
	var floor_c: Color = Color(0.40, 0.48, 0.58)
	var ceil_c: Color = Color(0.14, 0.18, 0.24)
	var ice: Color = Color(0.52, 0.66, 0.80)

	# x [-2, 2], z [-250, -240], h=3.0. South doorway centred at x=0.
	Chamber.add_floor_ceiling(self, 4, 10, 3.0, floor_c, ceil_c, Vector3(0, 0, -245))
	Chamber.add_wall(self, "x", -2, -250, -240, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -250, -240, 3.0, wall)
	Chamber.add_wall(self, "z", -250, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -240, -2, 2, 3.0, wall, 0.0)

	# The transition: poured concrete on the south half, raw ice on the north.
	# Lean a couple of ice slabs in to sell the shift.
	var slab_a: StaticBody3D = Chamber.make_prop_box(self, Vector3(1.8, 2.6, 0.6), Vector3(-1.0, 1.3, -247.0), ice, true, "ice")
	slab_a.rotation_degrees = Vector3(0, 0, 14.0)
	var slab_b: StaticBody3D = Chamber.make_prop_box(self, Vector3(1.6, 2.4, 0.6), Vector3(1.0, 1.2, -248.5), ice, true, "ice")
	slab_b.rotation_degrees = Vector3(0, 0, -10.0)
	# Ice stalagmite pinching the path.
	Chamber.make_prop_box(self, Vector3(0.6, 2.0, 0.6), Vector3(-0.6, 1.0, -249.0), ice, true, "ice")

	# Two hide niches: the final passage is where the peeker shows itself.
	ActUtil.hide_locker(self, Vector3(-1.4, 0, -242.0), 90.0)
	ActUtil.hide_locker(self, Vector3(1.4, 0, -246.0), -90.0, ice)

	# Dressing + the closing notes.
	ActUtil.corpse(self, Vector3(-1.2, 0, -243.5), 35.0, true, Color(0.22, 0.24, 0.28))
	ActUtil.signal_growth(self, Vector3(1.3, 0, -244.5), 1.4, Color(0.07, 0.13, 0.10))
	ActUtil.signal_growth(self, Vector3(-1.2, 0, -248.0), 1.1, Color(0.07, 0.13, 0.10))
	ActUtil.blood_trail(self, Vector3(-1.0, 0.02, -241.0), Vector3(0.8, 0.02, -249.0), 6)
	ActUtil.wall_scrawl(self, "THE LAST HUNDRED METRES WERE ALREADY HOLLOW",
		Vector3(0, 2.2, -249.85), 0.0, 14, Color(0.50, 0.06, 0.06))
	ActUtil.wall_label(self, "LVL D5 - 2000 m - CAVITY ACCESS",
		Vector3(0, 2.6, -249.7), 12, Color(0.6, 0.78, 0.9))

	# Two examines so the final passage carries the level's payoff.
	Interactable.make_examine(self, Vector3(-1.85, 1.20, -244.0), Vector3(0.05, 0.30, 0.40),
		"Read the boring log",
		"A boring log clipped to a stanchion. The samples drop in even " +
		"strata to 1980m. Below that the auger pulls no sample - the bit " +
		"just falls. Last entry: 'we are not drilling. we are uncovering. " +
		"the shaft was already cut. by what.'", 6.0)
	Interactable.make_examine(self, Vector3(1.85, 1.20, -247.5), Vector3(0.05, 0.30, 0.40),
		"Read the foreman's memo",
		"A foreman's memo wedged into the ice. 'pattern doesn't match a " +
		"drill. spacing is wrong. corners are wrong. corners shouldn't be " +
		"corners at this depth. someone shaped this. recommend halting D5 " +
		"work indefinitely.' Below it, stamped in red: APPROVED - PROCEED.", 6.0)
	_room_count += 1
