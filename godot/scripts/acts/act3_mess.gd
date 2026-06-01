extends Node3D
# VESPER - ACT 3: THE MESS & INFIRMARY
# Mess hall (west) opens east into the infirmary. The lab door is dead: get the
# meds-cabinet code from the mess (0317), open the cabinet for a ceramic fuse,
# seat it in the breaker to power the door. A lurker creeps the infirmary.

const WALL := Color(0.30, 0.33, 0.37)
const FLOOR := Color(0.33, 0.35, 0.39)
const CEIL := Color(0.13, 0.14, 0.17)

var exit_door: Node3D = null
var powered := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.13, 0.020)
	_build_mess()
	_build_pantry()
	_build_infirmary()

	ActUtil.haunt(self, {
		"intensity": 0.40, "flicker": true, "flicker_rate": 1.2,
		"peekers": [{"pos": Vector3(5.6, 0, -6.0), "kind": HorrorShape.KIND_FELIX, "rot": 135.0}],
		"lurkers": [
			{"points": [Vector3(17, 0, 4), Vector3(9, 0, 4), Vector3(17, 0, -4), Vector3(9, 0, -4)],
				"kind": HorrorShape.KIND_YUNA, "creep": 0.6},
			{"points": [Vector3(-1, 0, -10), Vector3(-4, 0, -12), Vector3(2, 0, -12), Vector3(-1, 0, -8), Vector3(-3, 0, 4)],
				"kind": HorrorShape.KIND_YUNA, "creep": 0.5},
		],
	})

	# A dead wall intercom in the infirmary still has charge for one transmission.
	ActUtil.register_note_echo(self, Vector3(18.85, 1.8, 1.0), -90.0, "note_4")

	if GameState.player:
		GameState.player.global_position = Vector3(-5.0, 0.5, 0.0)
		GameState.player.rotation_degrees.y = -90.0


func _process(_dt: float) -> void:
	if powered and GameState.player and GameState.player.global_position.x > 18.5:
		SceneRouter.transition_to("act3_5")


# --- Mess hall (west, entry) ---------------------------------------------

func _build_mess() -> void:
	# North wall has a doorway into the galley pantry at x=-1 (behind the
	# serving counter); east wall has the existing infirmary door at z=0.
	Chamber.add_room(self, 14, 14, 3.4, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "x", "fixed": 7.0, "gap": 0.0},
		 {"axis": "z", "fixed": -7.0, "gap": -1.0}])
	ActUtil.add_ceiling_pipes(self, 14, 14, 3.4, Vector3(0, 0, 0))
	# Long dining tables + benches.
	for tz in [-3.5, 0.0, 3.5]:
		Chamber.make_prop_box(self, Vector3(1.2, 0.1, 4.5), Vector3(-2.5, 0.75, tz), Color(0.34, 0.30, 0.24))
		for bx in [-3.3, -1.7]:
			Chamber.make_prop_box(self, Vector3(0.4, 0.45, 4.3), Vector3(bx, 0.22, tz), Color(0.28, 0.25, 0.20))
		# spilled trays
		Chamber.make_prop_box(self, Vector3(0.4, 0.04, 0.3), Vector3(-2.4, 0.82, tz + randf_range(-1, 1)), Color(0.55, 0.55, 0.6), false)
	# Serving counter, split around the pantry doorway at x=-1.
	for cseg in [[-3.5, 3.0], [1.5, 3.0]]:
		Chamber.make_prop_box(self, Vector3(cseg[1], 1.0, 0.7), Vector3(cseg[0], 0.5, -6.0), Color(0.40, 0.42, 0.45))
		Chamber.make_prop_box(self, Vector3(cseg[1], 0.1, 0.9), Vector3(cseg[0], 1.05, -6.0), Color(0.55, 0.57, 0.60))
	# Kitchen units flank the pantry doorway (which is centred at x=-1).
	for kx in [-4.0, 2.0]:
		Chamber.make_prop_box(self, Vector3(1.4, 1.5, 0.8), Vector3(kx, 0.75, -6.4), Color(0.32, 0.34, 0.37))
	ActUtil.wall_label(self, "MESS", Vector3(-3.0, 2.8, 6.8), 26, Color(0.78, 0.84, 0.6))
	# The roster note on the counter (left segment).
	Interactable.make_note(self, Vector3(-3.5, 1.12, -5.7), "v_mess", "Read the roster")
	# Folded under a plate at the long table - not Vesper handwriting.
	Interactable.make_note(self, Vector3(-2.5, 0.83, 0.0), "note_16", "Read the folded note")
	# Overturned chairs, a body, blood.
	var c := Chamber.make_chair(self, Vector3(1.0, 0.45, 2.0), Color(0.30, 0.31, 0.34), 30.0)
	c.rotation_degrees = Vector3(84, 30, 0)
	ActUtil.corpse(self, Vector3(2.5, 0, -3.0), 110.0, true, Color(0.22, 0.24, 0.20))
	ActUtil.blood_trail(self, Vector3(2.5, 0.02, -3.0), Vector3(5.5, 0.02, 0.5), 7)
	ActUtil.add_floor_decals(self, 14, 14, Vector3.ZERO, Color(0.80, 0.66, 0.16, 0.6))


# --- Galley pantry (north off the kitchen, the cabinet code is in here) --
# A back-of-house dry-storage room. Branches off the mess north wall at the
# gap we cut at x=-1. Holds the keypad code on a wall poster - currently the
# code (0317) is a leap of faith; finding it scribbled here makes the puzzle
# land. Three walls + shared mess wall: keep it tight.

func _build_pantry() -> void:
	var floor_c := Color(0.32, 0.34, 0.38)
	var ceil_c := Color(0.12, 0.13, 0.16)
	# Pantry x -5..3 (centre -1, w=8), z -13..-7 (centre -10, d=6), h=3.0.
	Chamber.add_floor_ceiling(self, 8, 6, 3.0, floor_c, ceil_c, Vector3(-1, 0, -10))
	Chamber.add_wall(self, "x", -5, -13, -7, 3.0, WALL)
	# East wall: split around the side-wing portal (z=-10, c_w=4) by helper.
	RoomGen.add_side_wing(self, {
		"host_axis": "x", "host_fixed": 3.0,
		"host_min": -13.0, "host_max": -7.0, "host_h": 3.0,
		"host_color": WALL,
		"theme": "industrial", "axis": "x",
		"along_min": 3.0, "along_max": 27.0, "perp": -10.0,
		"corridor_w": 4.0, "corridor_h": 3.0,
		"rooms_left": 3, "rooms_right": 0,
		"room_depth": 5.5, "room_w_along": 5.0, "room_h": 2.9,
		"seed": 3300,
	})
	ActUtil.wall_label(self, "PREP", Vector3(3.15, 2.6, -10.0), 16, Color(0.78, 0.84, 0.6))
	Chamber.add_wall(self, "z", -13, -5, 3, 3.0, WALL)

	# Shelves along three walls, food crates and ration boxes.
	for sz in [-12.5, -7.5]:
		Chamber.make_prop_box(self, Vector3(6.0, 0.06, 0.5), Vector3(-1.0, 1.4, sz), Color(0.30, 0.27, 0.20), false)
		Chamber.make_prop_box(self, Vector3(6.0, 0.06, 0.5), Vector3(-1.0, 0.8, sz), Color(0.30, 0.27, 0.20), false)
	for bx in [-3.5, -2.0, 0.0, 1.8]:
		Chamber.make_prop_box(self, Vector3(0.5, 0.5, 0.5), Vector3(bx, 0.25, -12.4), Color(0.45, 0.36, 0.20))
	Chamber.make_prop_box(self, Vector3(0.9, 1.7, 0.6), Vector3(-4.4, 0.85, -10.0), Color(0.30, 0.32, 0.36))
	Chamber.make_prop_box(self, Vector3(0.9, 1.7, 0.6), Vector3(2.4, 0.85, -10.0), Color(0.30, 0.32, 0.36))

	# The code, half-torn off a posted log. This is where 0317 comes from.
	Interactable.make_examine(self, Vector3(-4.55, 1.7, -10.0), Vector3(0.05, 0.5, 0.4),
		"Read the torn shift log",
		"Half a duty roster pinned to the wall. The bottom edge survived: " +
		"'meds cabinet code reset 03/17 - everyone gets the same one this rotation.'", 6.0)
	# A body in the back; the cook didn't make it out.
	ActUtil.corpse(self, Vector3(0.0, 0, -12.0), 180.0, true, Color(0.30, 0.26, 0.18))
	ActUtil.blood_decal(self, Vector3(0.0, 0.02, -11.4), Vector2(1.6, 1.0), "up")
	ActUtil.blood_wall(self, Vector3(-1.0, 1.5, -12.85), Vector2(1.6, 1.7), 0.0)
	ActUtil.wall_label(self, "PANTRY", Vector3(-1.0, 2.6, -12.7), 16, Color(0.78, 0.84, 0.6))
	ActUtil.add_dust_motes(self, Vector3(-1, 1.6, -10), Vector3(7, 1.8, 4), 35,
		Color(0.78, 0.80, 0.86, 0.12))


# --- Infirmary (east, the puzzle + exit) ---------------------------------

func _build_infirmary() -> void:
	Chamber.add_room(self, 12, 10, 3.4, FLOOR, CEIL, WALL, Vector3(13, 0, 0), {},
		[{"axis": "x", "fixed": 7.0, "gap": 0.0}, {"axis": "x", "fixed": 19.0, "gap": 0.0}])
	exit_door = Chamber.add_door(self, "x", 19 - 0.05, 0, "LAB DOOR", Color(0.26, 0.30, 0.36), Callable(), "", true)

	# Patient beds with IV stands + privacy rails.
	for bz in [-3.2, 0.0, 3.2]:
		Chamber.make_prop_box(self, Vector3(2.0, 0.6, 0.95), Vector3(10.5, 0.4, bz), Color(0.46, 0.48, 0.52))
		Chamber.make_prop_box(self, Vector3(2.0, 0.12, 0.9), Vector3(10.5, 0.72, bz), Color(0.70, 0.70, 0.74), false)
		Chamber.make_prop_box(self, Vector3(0.06, 1.7, 0.06), Vector3(11.4, 0.85, bz - 0.4), Color(0.6, 0.6, 0.64), false)
		Chamber.make_prop_box(self, Vector3(0.2, 0.25, 0.12), Vector3(11.4, 1.6, bz - 0.4), Color(0.5, 0.7, 0.6), false)
	# A surgical table with what's left on it.
	Chamber.make_prop_box(self, Vector3(1.0, 0.1, 2.0), Vector3(15.5, 0.9, 2.5), Color(0.55, 0.57, 0.62))
	for slx in [15.1, 15.9]:
		for slz in [1.7, 3.3]:
			Chamber.make_prop_box(self, Vector3(0.07, 0.9, 0.07), Vector3(slx, 0.45, slz), Color(0.5, 0.5, 0.55), false)
	ActUtil.viscera(self, Vector3(15.5, 0.97, 2.5))
	ActUtil.blood_decal(self, Vector3(15.5, 0.02, 3.6), Vector2(1.6, 1.3))
	# Supply shelves + the locked drug cabinet (keypad 0317).
	Chamber.make_prop_box(self, Vector3(0.6, 1.8, 2.4), Vector3(8.4, 0.9, -3.5), Color(0.30, 0.36, 0.40))
	var cab := Chamber.make_prop_box(self, Vector3(0.5, 1.1, 0.9), Vector3(8.5, 1.3, 3.5), Color(0.34, 0.40, 0.44))
	Interactable.attach(cab, "Enter cabinet code", "keypad", {"code": "0317", "on_unlock": Callable(self, "_cabinet_unlocked")})
	ActUtil.wall_label(self, "MEDS - LOCKED", Vector3(8.5, 2.1, 3.5), 13, Color(0.8, 0.5, 0.45))
	# Breaker panel beside the lab door (needs the fuse).
	var breaker := Chamber.make_prop_box(self, Vector3(0.18, 0.8, 0.6), Vector3(18.7, 1.4, 1.6), Color(0.26, 0.27, 0.30))
	Interactable.attach(breaker, "Seat the fuse", "use_item", {
		"required_item": "ceramic_fuse", "consume": true,
		"on_use": Callable(self, "_restore_power"),
		"locked_text": "The breaker's dead - it needs a fresh ceramic fuse.",
	})
	# The infirmary log.
	Interactable.make_note(self, Vector3(10.5, 0.80, 0.0), "v_infirm", "Read the log")
	# Medical horror: a hung body, the dark filament growing toward a dead lamp,
	# wall scrawl, smears, a body in a bed.
	ActUtil.hanging_corpse(self, Vector3(16.5, 3.3, -3.0), 1.8, Color(0.55, 0.55, 0.5))
	ActUtil.signal_growth(self, Vector3(18.4, 0, -3.6), 1.3, Color(0.10, 0.16, 0.10))
	ActUtil.wall_scrawl(self, "IT GROWS TOWARD THE LIGHT", Vector3(13.0, 2.0, -4.85), 0.0, 34, Color(0.5, 0.05, 0.06))
	ActUtil.bloody_smears(self, Vector3(7.15, 2.2, 2.0), 90.0, 4)
	Chamber.make_prop_box(self, Vector3(0.7, 0.3, 1.6), Vector3(10.5, 0.78, -3.2), Color(0.30, 0.20, 0.22), false)
	ActUtil.blood_decal(self, Vector3(10.5, 0.74, -2.6), Vector2(0.7, 0.9), "up")
	ActUtil.wall_label(self, "INFIRMARY", Vector3(13.0, 2.9, 4.8), 24, Color(0.78, 0.84, 0.6))


# --- Puzzle callbacks -----------------------------------------------------

func _cabinet_unlocked() -> void:
	InventoryManager.add("ceramic_fuse")
	InteractionManager.show_examine("The cabinet clicks open. Morphine, gauze - and a spare ceramic fuse. You take the fuse.", 4.5)


func _restore_power() -> void:
	if powered:
		return
	powered = true
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.7, 0.85, 1.0)
	lamp.light_energy = 2.6
	lamp.omni_range = 9.0
	lamp.position = Vector3(18.0, 3.0, 0.5)
	add_child(lamp)
	var t := exit_door.create_tween()
	t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	t.tween_callback(func() -> void:
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	AudioManager.door()
	InteractionManager.show_examine("The line hums back and the lab door releases. Beyond it: a service crawl. The note said to kill the lights behind you. You don't.", 5.0)
