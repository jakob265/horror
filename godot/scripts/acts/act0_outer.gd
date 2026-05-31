extends Node3D
# VESPER - ACT 0: THE OUTER STATION
# Walking in. The arrival annex - admin offices, security shack, customs gate -
# that you crossed when the Sno-Cat dropped you off. Procedurally laid out so
# the station feels like a place that EXISTS, not a series of game levels.
# No hunter yet. The cold has already taken everyone.

const ENTRY_HALL_W := 8.0
const ENTRY_HALL_D := 12.0
const ENTRY_HALL_H := 3.6


var _crossed := false
var _room_count := 0


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.10, 0.024)
	_build_entry_hall()
	_build_admin_wing()
	_build_security_wing()
	_build_final_passage()

	# Low haunt - this is "the dark before the dark", a beat of dread, no chase.
	ActUtil.haunt(self, {
		"intensity": 0.30, "flicker": true, "flicker_rate": 0.7,
		"peekers": [{"pos": Vector3(0, 0, -38.0), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0}],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 5.5)
		GameState.player.rotation_degrees.y = 180.0

	print("Act 0: %d rooms placed." % _room_count)


func _process(_dt: float) -> void:
	if _crossed:
		return
	if GameState.player and GameState.player.global_position.z < -39.5:
		_crossed = true
		SceneRouter.transition_to("act1")


# --- Hand-crafted entry hall (south, where you spawn) --------------------
# The first room you see should still be hand-crafted so the act has a
# coherent opening; the generator handles the wings beyond it.

func _build_entry_hall() -> void:
	var wall := Color(0.32, 0.34, 0.38)
	var floor_c := Color(0.36, 0.38, 0.42)
	var ceil_c := Color(0.14, 0.15, 0.18)

	# Entry hall: x [-4, 4], z [0, 12], h=3.6. Spawn at (0, 0.5, 5.5).
	Chamber.add_floor_ceiling(self, ENTRY_HALL_W, ENTRY_HALL_D, ENTRY_HALL_H,
		floor_c, ceil_c, Vector3(0, 0, 6))
	# East / west / south walls solid.
	Chamber.add_wall(self, "x", -4, 0, 12, ENTRY_HALL_H, wall)
	Chamber.add_wall(self, "x",  4, 0, 12, ENTRY_HALL_H, wall)
	Chamber.add_wall(self, "z", 12, -4, 4, ENTRY_HALL_H, wall)
	# North wall has the doorway through into the admin wing's corridor.
	Chamber.add_wall(self, "z",  0, -4, 4, ENTRY_HALL_H, wall, 0.0)

	# Dressing: a customs desk, dropped duffel bag, three frozen footprints.
	Chamber.make_prop_box(self, Vector3(2.4, 1.0, 1.0), Vector3(-1.5, 0.50, 9.0), Color(0.30, 0.27, 0.22))
	Chamber.make_prop_box(self, Vector3(2.4, 0.1, 1.2), Vector3(-1.5, 1.05, 9.0), Color(0.40, 0.36, 0.28))
	Chamber.make_chair(self, Vector3(-1.5, 0, 7.8), Color(0.30, 0.31, 0.34), 180.0)
	Chamber.make_prop_box(self, Vector3(0.8, 0.5, 0.5), Vector3(2.2, 0.25, 10.0), Color(0.55, 0.30, 0.20))
	for fz in [5.0, 4.0, 3.0]:
		ActUtil.blood_decal(self, Vector3(0.6, 0.02, fz), Vector2(0.5, 0.8), "up",
			Color(0.70, 0.78, 0.90, 0.20))
	ActUtil.corpse(self, Vector3(1.6, 0, 11.0), -60.0, true, Color(0.20, 0.22, 0.26))

	# A pinned arrival note.
	Interactable.make_examine(self, Vector3(-1.4, 1.10, 8.8), Vector3(0.05, 0.30, 0.40),
		"Read the customs board",
		"Customs receipt board, names crossed off one per line through the rotation. " +
		"The latest entry, hand-printed at the bottom: 'NO MORE COMING. " +
		"NO ONE TO BE SIGNED OUT.'", 6.0)
	ActUtil.wall_label(self, "OUTER STATION", Vector3(0, 3.0, 11.85), 24, Color(0.7, 0.84, 0.9))

	_room_count += 1


# --- Procedural admin wing (extends west off the entry hall corridor) ----

func _build_admin_wing() -> void:
	# A long corridor running south->north (z-axis), with side rooms off both
	# sides. Entry hall's north doorway at (0, 0, 0) lands the player in the
	# corridor's south end. Corridor centered at x=0 to align with the entry.
	_room_count += RoomGen.stamp_corridor_wing(self, {
		"theme": "admin",
		"axis": "z",
		"along_min": -14.0, "along_max": 0.0,
		"perp": 0.0,
		"corridor_w": 4.0, "corridor_h": 3.4,
		"rooms_left": 2, "rooms_right": 2,
		"room_depth": 6.0, "room_w_along": 5.5, "room_h": 3.0,
		"seed": 110,
	})


# --- Procedural security wing (perpendicular, branches west at z=-14) ----

func _build_security_wing() -> void:
	# A cross-corridor: the admin wing's far end opens into this east-west
	# corridor. We need the admin corridor's far wall (at z=-14) to have a
	# doorway. We rebuild the joint here: the security corridor's "end" wall
	# at x=0 has the doorway, and the admin's far wall doorway is the same
	# physical opening (since both corridors meet at perp=0).
	_room_count += RoomGen.stamp_corridor_wing(self, {
		"theme": "industrial",
		"axis": "x",
		"along_min": -16.0, "along_max": 16.0,
		"perp": -16.0,
		"corridor_w": 4.0, "corridor_h": 3.4,
		"rooms_left": 3, "rooms_right": 3,
		"room_depth": 6.0, "room_w_along": 5.0, "room_h": 3.0,
		"seed": 220,
	})


# --- Final passage (north tunnel through to act 1's bay) -----------------

func _build_final_passage() -> void:
	var wall := Color(0.30, 0.32, 0.36)
	var floor_c := Color(0.34, 0.36, 0.40)
	var ceil_c := Color(0.13, 0.14, 0.17)

	# Short tunnel x [-2, 2], z [-40, -18], h=3.0. Connects the security
	# corridor (at z=-16) to act 1's bay entrance via z<-39.5 trigger.
	Chamber.add_floor_ceiling(self, 4, 22, 3.0, floor_c, ceil_c, Vector3(0, 0, -29))
	Chamber.add_wall(self, "x", -2, -40, -18, 3.0, wall)
	Chamber.add_wall(self, "x",  2, -40, -18, 3.0, wall)
	Chamber.add_wall(self, "z", -40, -2, 2, 3.0, wall)
	Chamber.add_wall(self, "z", -18, -2, 2, 3.0, wall, 0.0)

	# Peeker at the far end (configured in haunt above), a body half-frozen
	# at the threshold, growth climbing the final wall.
	ActUtil.corpse(self, Vector3(-1.2, 0, -34.0), 35.0, true, Color(0.22, 0.24, 0.28))
	ActUtil.signal_growth(self, Vector3(1.3, 0, -38.0), 1.2, Color(0.07, 0.13, 0.10))
	ActUtil.wall_scrawl(self, "VESPER WAITS", Vector3(0, 2.2, -39.85), 0.0, 22, Color(0.50, 0.06, 0.06))
	ActUtil.wall_label(self, "BAY ACCESS", Vector3(0, 2.6, -39.7), 13, Color(0.7, 0.84, 0.9))

	_room_count += 1
