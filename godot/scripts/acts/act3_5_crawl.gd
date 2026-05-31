extends Node3D
# VESPER - ACT 3.5: THE CRAWL SPACE
# A ventilation crawl between the station habitat (mess) and the research deck
# (labs). No puzzle. No hunter. A passage you walk through while the dark
# breathes overhead. The shortest act in the game by design - it's a beat,
# not a level.

const WALL := Color(0.20, 0.22, 0.24)
const FLOOR := Color(0.24, 0.26, 0.28)
const CEIL := Color(0.08, 0.09, 0.11)


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.07, 0.030)
	_build_entry()
	_build_crawl()
	_build_exit()

	# Low-intensity haunt: this is held-breath, not chased. One peeker at the
	# far end watches you the whole way - gone if you stop and look at it.
	ActUtil.haunt(self, {
		"intensity": 0.40, "flicker": true, "flicker_rate": 0.7,
		"peekers": [{"pos": Vector3(0, 0, -19.5), "kind": HorrorShape.KIND_HARGROVE, "rot": 0.0}],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 4.5)
		GameState.player.rotation_degrees.y = 180.0


func _process(_dt: float) -> void:
	# No puzzle gate - just walk through. The act ends at the north access hatch.
	if GameState.player and GameState.player.global_position.z < -22.4:
		SceneRouter.transition_to("act4")


# --- Entry chamber (south, where you crawl in from the infirmary) --------

func _build_entry() -> void:
	# Small low-ceilinged chamber. x -3..3, z 0..6 (centre 0, 0, 3), h=2.6.
	Chamber.add_floor_ceiling(self, 6, 6, 2.6, FLOOR, CEIL, Vector3(0, 0, 3))
	Chamber.add_wall(self, "x", -3, 0, 6, 2.6, WALL)
	Chamber.add_wall(self, "x", 3, 0, 6, 2.6, WALL)
	Chamber.add_wall(self, "z", 6, -3, 3, 2.6, WALL)
	# North wall has the doorway to the crawl proper.
	Chamber.add_wall(self, "z", 0, -3, 3, 2.6, WALL, 0.0)

	# Dressing: ductwork running the ceiling, a flashlight battery on a shelf,
	# a body the cavity already came for.
	Chamber.make_prop_box(self, Vector3(0.5, 0.4, 5.6), Vector3(-2.4, 2.2, 3.0), Color(0.30, 0.32, 0.34), false)
	Chamber.make_prop_box(self, Vector3(0.5, 0.4, 5.6), Vector3(2.4, 2.2, 3.0), Color(0.30, 0.32, 0.34), false)
	Chamber.make_prop_box(self, Vector3(0.16, 2.4, 0.16), Vector3(-2.7, 1.2, 5.5), Color(0.40, 0.30, 0.18), false)
	Chamber.make_prop_box(self, Vector3(0.16, 2.4, 0.16), Vector3(2.7, 1.2, 5.5), Color(0.40, 0.30, 0.18), false)
	# A maintenance bench with a spare battery on it.
	Chamber.make_prop_box(self, Vector3(1.4, 0.10, 0.6), Vector3(-2.0, 0.90, 5.5), Color(0.30, 0.27, 0.22))
	for blz in [5.2, 5.8]:
		Chamber.make_prop_box(self, Vector3(0.08, 0.9, 0.08), Vector3(-1.4, 0.45, blz), Color(0.20, 0.18, 0.15), false)
	ActUtil.pickup(self, Vector3(-2.0, 0.99, 5.5), Vector3(0.2, 0.1, 0.34), Color(0.45, 0.78, 0.5),
		"spare_battery", "Take the spare cell")
	# Body slumped against the south wall.
	ActUtil.corpse(self, Vector3(1.6, 0, 5.4), -150.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_decal(self, Vector3(0.8, 0.02, 5.4), Vector2(1.2, 1.0), "up")
	ActUtil.wall_label(self, "VENT ACCESS", Vector3(0, 2.3, 5.85), 14, Color(0.78, 0.84, 0.6))
	ActUtil.wall_scrawl(self, "DON'T LOOK UP", Vector3(0, 1.8, 5.85), 0.0, 18, Color(0.50, 0.06, 0.06))


# --- Crawl tunnel (the long narrow run) ----------------------------------

func _build_crawl() -> void:
	# Narrow service tunnel. x -1.5..1.5, z -16..0 (centre 0, 0, -8), h=2.4
	# (the lowest ceiling in the game - DOOR_H, deliberately oppressive).
	Chamber.add_floor_ceiling(self, 3, 16, 2.4, FLOOR, CEIL, Vector3(0, 0, -8))
	Chamber.add_wall(self, "x", -1.5, -16, 0, 2.4, WALL)
	Chamber.add_wall(self, "x", 1.5, -16, 0, 2.4, WALL)
	# North end of the crawl: doorway to the exit chamber.
	Chamber.add_wall(self, "z", -16, -1.5, 1.5, 2.4, WALL, 0.0)

	# A run of pipes and ducts along the ceiling - the whole crawl reads as
	# you walking BENEATH something. Pipes change colour to break monotony.
	for pz in [-2.0, -6.0, -10.0, -14.0]:
		Chamber.make_prop_box(self, Vector3(0.16, 0.16, 3.8), Vector3(-1.3, 2.0, pz), Color(0.40, 0.30, 0.18), false)
		Chamber.make_prop_box(self, Vector3(0.16, 0.16, 3.8), Vector3(1.3, 2.0, pz), Color(0.30, 0.33, 0.36), false)
	for px in [-1.3, 1.3]:
		Chamber.make_prop_box(self, Vector3(0.14, 0.14, 14.5), Vector3(px, 1.6, -8.0), Color(0.30, 0.33, 0.36), false)
	# Three transverse pipes overhead the player has to walk under.
	for tz in [-4.0, -9.0, -13.0]:
		Chamber.make_prop_box(self, Vector3(2.5, 0.18, 0.18), Vector3(0, 1.9, tz), Color(0.40, 0.30, 0.18), false)
	# Conduit bundle running the floor.
	Chamber.make_prop_box(self, Vector3(0.5, 0.10, 14.5), Vector3(-1.0, 0.05, -8.0), Color(0.16, 0.18, 0.22), false)
	Chamber.make_prop_box(self, Vector3(0.5, 0.10, 14.5), Vector3(1.0, 0.05, -8.0), Color(0.16, 0.18, 0.22), false)

	# Three wall vents along the crawl - each one a stalactite of dread.
	for vz in [-4.0, -8.0, -12.0]:
		Chamber.make_prop_box(self, Vector3(0.05, 0.5, 0.7), Vector3(-1.45, 1.5, vz), Color(0.10, 0.12, 0.14), false)
		Chamber.make_prop_box(self, Vector3(0.05, 0.5, 0.7), Vector3(1.45, 1.5, vz), Color(0.10, 0.12, 0.14), false)
	# Faint emergency strip along the floor on one side so the crawl isn't void.
	ActUtil.emergency_strip(self, Vector3(-1.4, 0.04, -1.0), Vector3(-1.4, 0.04, -15.5),
		Color(0.78, 0.20, 0.18), 0.4)

	# Set dressing along the crawl: drag marks (south to north - whatever was
	# dragged came from the cavity's direction), an articulated half-body
	# pushed against the west wall, blood smears on the ceiling pipes.
	ActUtil.blood_trail(self, Vector3(0.6, 0.02, -2.0), Vector3(-0.4, 0.02, -14.0), 10)
	ActUtil.corpse(self, Vector3(-0.8, 0, -10.0), 90.0, true, Color(0.22, 0.20, 0.16))
	ActUtil.blood_wall(self, Vector3(-1.45, 1.5, -7.0), Vector2(0.8, 1.2), 90.0)
	ActUtil.blood_decal(self, Vector3(0, 1.85, -9.0), Vector2(1.8, 0.6), "up", Color(0.20, 0.04, 0.05, 0.7))

	# One critical hide locker tucked in mid-crawl. With the peeker visible at
	# the far end, this gives you somewhere to look away from it.
	ActUtil.hide_locker(self, Vector3(-1.4, 0, -6.0), 90.0)

	# Three examine notes along the crawl - text, no note_id (all existing IDs
	# are placed in other acts).
	Interactable.make_examine(self, Vector3(1.4, 1.05, -3.0), Vector3(0.05, 0.4, 0.4),
		"Read the duct-tape label",
		"Duct-tape strip on the wall, message scrawled in marker: 'ALL CARRIER " +
		"FROM THIS POINT NORTH IS NOT ACTUALLY CARRIER. THE BUFFER IS ONLY THIRTY " +
		"SECONDS. PLEASE DO NOT BELIEVE ANY VOICE YOU HEAR IN HERE.'", 7.0)
	Interactable.make_examine(self, Vector3(-1.4, 1.05, -10.0), Vector3(0.05, 0.4, 0.4),
		"Read the riveted plate",
		"A maintenance plate riveted to the wall. Manufacturer's text and " +
		"date. Hand-scratched into it with something sharp: 'we should not have " +
		"laid the vents through the cavity.'", 7.0)
	Interactable.make_examine(self, Vector3(1.4, 1.05, -14.0), Vector3(0.05, 0.4, 0.4),
		"Read the chalk count",
		"A long string of tally marks in white chalk. Twenty-two scored " +
		"upright. The last four scored sideways across the rest. No name, no " +
		"explanation. Just the tally and the room.", 7.0)


# --- Exit chamber (north, where you crawl out onto the research deck) ----

func _build_exit() -> void:
	# Mirror of the entry: small low room with the access hatch north.
	Chamber.add_floor_ceiling(self, 6, 6, 2.6, FLOOR, CEIL, Vector3(0, 0, -19))
	Chamber.add_wall(self, "x", -3, -22, -16, 2.6, WALL)
	Chamber.add_wall(self, "x", 3, -22, -16, 2.6, WALL)
	Chamber.add_wall(self, "z", -22, -3, 3, 2.6, WALL, 0.0)
	# (South wall is the crawl tunnel's z=-16 wall - already built with a gap.)

	# The hatch out (no door leaf - just an opening; the peeker is right there).
	ActUtil.wall_label(self, "RESEARCH DECK ->", Vector3(0, 2.3, -21.85), 14, Color(0.78, 0.84, 0.6))
	# Dressing: a coil of cable, a discarded toolbelt, a body fused into the
	# wall (the cavity's growth has reached the threshold of the labs).
	Chamber.make_prop_box(self, Vector3(0.6, 0.5, 0.6), Vector3(-2.3, 0.25, -17.5), Color(0.30, 0.32, 0.36))
	Chamber.make_prop_box(self, Vector3(0.5, 0.18, 1.4), Vector3(2.0, 0.10, -18.0), Color(0.70, 0.50, 0.10))
	ActUtil.corpse(self, Vector3(-1.8, 0, -20.6), 15.0, true, Color(0.18, 0.20, 0.24))
	ActUtil.signal_growth(self, Vector3(2.4, 0, -21.0), 1.4, Color(0.07, 0.13, 0.10))
	ActUtil.bloody_smears(self, Vector3(-2.95, 1.7, -20.0), 90.0, 3, Color(0.40, 0.06, 0.05))
	ActUtil.wall_scrawl(self, "IT KNOWS YOU'RE COMING", Vector3(0, 1.7, -21.85), 0.0, 16, Color(0.50, 0.06, 0.06))
	ActUtil.add_dust_motes(self, Vector3(0, 1.5, -19), Vector3(2.5, 1.8, 2.5), 25,
		Color(0.78, 0.82, 0.92, 0.16))
