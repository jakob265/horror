extends Node3D
# VESPER - ACT 5: THE GENERATOR HALL
# Darkness peaks. Restore the main bus in three steps - prime COOLANT (valve
# handle), charge FUEL (diesel can), throw the BREAKER - in a vast pitch-black
# hall while the hunter circles. Lighting the hall draws it straight to you.

const WALL := Color(0.26, 0.28, 0.32)
const FLOOR := Color(0.30, 0.31, 0.35)
const CEIL := Color(0.10, 0.11, 0.13)

var exit_door: Node3D = null
var fuel_light: MeshInstance3D = null
var coolant_light: MeshInstance3D = null
var breaker_light: MeshInstance3D = null
var fuel_ok := false
var coolant_ok := false
var powered := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.07, 0.024)
	_build_hall()
	_build_fuel_bay()

	var stalker := HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, 0, -6.0), 0.0)
	stalker.set_stalk([
		Vector3(-6, 0, 5),
		Vector3(6, 0, 5),
		Vector3(6, 0, -5),
		Vector3(14, 0, -4),
		Vector3(6, 0, -5),
		Vector3(-6, 0, -5),
	], 1.3, 4.2)
	add_child(stalker)
	ShapeTracker.register(stalker)

	ActUtil.haunt(self, {"intensity": 0.55, "flicker": true, "flicker_rate": 1.6})

	# Two dead intercoms catch carrier from a station that isn't here anymore.
	ActUtil.register_note_echo(self, Vector3(-7.0, 1.8, -8.85), 0.0, "note_6")
	ActUtil.register_note_echo(self, Vector3(4.0, 1.8, 8.85), 180.0, "note_17")

	# Renn left the warning about the hall. Renn doesn't leave warnings anymore.
	ActUtil.enable_lure(self, {
		"voice": "Renn",
		"calls": [
			{"call": "i got the hall lit too, in the end. stand in it with me. just for a second.",
			 "answer": "good. don't move. let me find you."},
			{"call": "the breaker's the easy part. the easy part is wanting to throw it.",
			 "answer": "ah. there. i hear your breathing now."},
			{"call": "ninety seconds is plenty. plenty of time. plenty of warm.",
			 "answer": "good. stay in the light. stay where i can see you."},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 7.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if powered and GameState.player and GameState.player.global_position.z < -8.6:
		SceneRouter.transition_to("act6")


func _build_hall() -> void:
	# East wall now has a doorway at z=-4 into the fuel storage bay.
	Chamber.add_room(self, 20, 18, 5.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": -9.0, "gap": 0.0}, {"axis": "z", "fixed": 9.0, "gap": 0.0},
		 {"axis": "x", "fixed": 10.0, "gap": -4.0}])
	exit_door = Chamber.add_door(self, "z", -9 + 0.05, 0, "MAIN DOOR", Color(0.24, 0.26, 0.32), Callable(), "", true)
	Chamber.invis_wall(self, "z", 9, 0)
	# Faint failing emergency strip so the hall isn't a total void.
	ActUtil.emergency_strip(self, Vector3(-9, 4.6, -8), Vector3(-9, 4.6, 8), Color(0.7, 0.2, 0.15), 0.6)
	ActUtil.add_ceiling_pipes(self, 20, 18, 5.0, Vector3(0, 0, 0))

	# The generator block (west) - turbine, tanks, manifolds.
	Chamber.make_prop_box(self, Vector3(4.0, 2.4, 5.0), Vector3(-6.5, 1.2, 0), Color(0.30, 0.32, 0.36))
	Chamber.make_prop_box(self, Vector3(1.2, 3.2, 1.2), Vector3(-8.4, 1.6, 3.0), Color(0.34, 0.30, 0.22))
	Chamber.make_prop_box(self, Vector3(1.2, 3.2, 1.2), Vector3(-8.4, 1.6, -3.0), Color(0.34, 0.30, 0.22))
	for pz in [-2.0, 0.0, 2.0]:
		Chamber.make_prop_box(self, Vector3(0.3, 0.3, 5.0), Vector3(-4.3, 2.0, pz), Color(0.40, 0.30, 0.18), false)
	# Catwalk overhead (visual verticality).
	Chamber.make_prop_box(self, Vector3(20, 0.12, 1.6), Vector3(0, 3.6, -6.0), Color(0.22, 0.23, 0.26), false)
	for rx in [-6, 0, 6]:
		Chamber.make_prop_box(self, Vector3(0.08, 0.9, 0.08), Vector3(rx, 4.1, -6.6), Color(0.3, 0.3, 0.34), false)

	# Control desk (centre) with the three indicators + breaker lever.
	Chamber.make_prop_box(self, Vector3(2.4, 1.1, 0.8), Vector3(-2.5, 0.55, 0), Color(0.24, 0.25, 0.29))
	fuel_light = _ind(Vector3(-3.2, 1.25, 0.42), "FUEL")
	coolant_light = _ind(Vector3(-2.5, 1.25, 0.42), "COOLANT")
	breaker_light = _ind(Vector3(-1.8, 1.25, 0.42), "BREAKER")
	var lever := Chamber.make_prop_box(self, Vector3(0.2, 0.5, 0.2), Vector3(-2.5, 1.35, 0.0), Color(0.6, 0.15, 0.12))
	Interactable.attach(lever, "Throw the main breaker", "trigger_event", {"callback": Callable(self, "_throw_breaker")})

	# COOLANT valve + FUEL intake on the generator block.
	var valve := Chamber.make_prop_box(self, Vector3(0.4, 0.4, 0.3), Vector3(-4.3, 0.9, -2.6), Color(0.45, 0.30, 0.18))
	Interactable.attach(valve, "Open the coolant valve", "use_item", {
		"required_item": "valve_handle", "consume": false,
		"on_use": Callable(self, "_do_coolant"),
		"locked_text": "The coolant spindle's stripped bare - you need a wheel-handle.",
	})
	var intake := Chamber.make_prop_box(self, Vector3(0.4, 0.5, 0.4), Vector3(-4.3, 0.5, 2.6), Color(0.30, 0.28, 0.20))
	Interactable.attach(intake, "Charge the fuel tank", "use_item", {
		"required_item": "diesel_can", "consume": true,
		"on_use": Callable(self, "_do_fuel"),
		"locked_text": "The fuel rack's empty. Find a diesel can.",
	})

	# The two items, far apart, out in the dark.
	_make_pickup(Vector3(5.0, 0.35, -3.5), Vector3(0.5, 0.16, 0.18), Color(0.7, 0.62, 0.2), "valve_handle", "Take the valve handle")
	Chamber.make_prop_box(self, Vector3(1.6, 0.9, 0.7), Vector3(7.6, 0.45, -6.0), Color(0.30, 0.32, 0.36))
	_make_pickup(Vector3(5.0, 0.35, 3.5), Vector3(0.36, 0.55, 0.28), Color(0.8, 0.2, 0.14), "diesel_can", "Take the diesel can")
	for rz in [4.5, 5.5, 6.5]:
		Chamber.make_prop_box(self, Vector3(0.5, 0.5, 0.5), Vector3(8.8, 0.25, rz), Color(0.30, 0.30, 0.22))

	# Hide spots + dressing + dread.
	ActUtil.hide_locker(self, Vector3(9.5, 0, 0.0), 90.0)
	ActUtil.hide_locker(self, Vector3(-9.4, 0, 6.5), 90.0)
	# Two more spots tucked behind transformers - more cover means more time
	# to wait the patrol out instead of sprinting (which it hears anyway).
	ActUtil.hide_locker(self, Vector3(-9.4, 0, -5.0), 90.0)
	ActUtil.hide_locker(self, Vector3(8.5, 0, 7.5), -90.0)
	# A fuel rack along the north wall: more diesel than Renn was supposed
	# to need. He kept lighting the hall and running.
	for fz in [-8.4, -8.0, -7.6]:
		Chamber.make_prop_box(self, Vector3(0.45, 0.7, 0.35), Vector3(-7.0, 0.35, fz), Color(0.74, 0.16, 0.12))
		Chamber.make_prop_box(self, Vector3(0.45, 0.7, 0.35), Vector3(-6.4, 0.35, fz), Color(0.74, 0.16, 0.12))
	Chamber.make_prop_box(self, Vector3(2.4, 0.1, 1.6), Vector3(-6.7, 0.05, -8.0), Color(0.22, 0.22, 0.20), false)
	# A spilled drum on its side, leaking - the slick trails toward the breaker.
	Chamber.make_prop_box(self, Vector3(0.7, 0.35, 0.4), Vector3(-3.8, 0.18, -7.5), Color(0.50, 0.12, 0.08))
	ActUtil.blood_trail(self, Vector3(-3.8, 0.02, -7.5), Vector3(-2.6, 0.02, -3.0), 6)
	# A second body half-collapsed against a transformer. Renn the fourth time.
	ActUtil.corpse(self, Vector3(7.6, 0, -5.5), -90.0, true, Color(0.24, 0.22, 0.18))
	ActUtil.bloody_smears(self, Vector3(7.9, 1.8, -6.5), 90.0, 4, Color(0.40, 0.06, 0.05))
	# A safety poster nobody is reading anymore.
	ActUtil.wall_poster(self, "x", -10.0 + 0.05, Vector3(-9.95, 1.6, 4.0), Vector2(0.9, 1.2), Color(0.30, 0.42, 0.55))
	Interactable.make_note(self, Vector3(-2.5, 1.12, -0.3), "v_gen", "Read the plant log")
	# A research journal someone left on the desk. Day 34 of contact protocol.
	Interactable.make_note(self, Vector3(-1.5, 1.12, -0.3), "note_2", "Read the research journal")
	ActUtil.corpse(self, Vector3(-7.0, 0, 5.5), 20.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_trail(self, Vector3(-7.0, 0.02, 5.5), Vector3(-2.0, 0.02, 7.5), 7)
	ActUtil.signal_growth(self, Vector3(-9.3, 0, -6.5), 1.6, Color(0.08, 0.13, 0.10))
	ActUtil.wall_scrawl(self, "NINETY SECONDS", Vector3(4.0, 2.2, 8.85), 180.0, 30, Color(0.5, 0.05, 0.06))
	ActUtil.wall_label(self, "GENERATOR HALL", Vector3(0, 3.4, 8.8), 24, Color(0.7, 0.84, 0.9))

	# Fill the hall out: transformers, breaker cabinets, conduit, drums, debris.
	for tx in [6.0, 7.8]:
		Chamber.make_prop_box(self, Vector3(1.3, 2.4, 1.3), Vector3(tx, 1.2, -6.5), Color(0.30, 0.31, 0.34))
		Chamber.make_prop_box(self, Vector3(0.12, 0.6, 0.12), Vector3(tx, 2.7, -6.5), Color(0.42, 0.42, 0.46), false)
	for cz in [-2.0, 0.0, 2.0, 4.0]:
		Chamber.make_prop_box(self, Vector3(0.6, 2.0, 1.0), Vector3(9.3, 1.0, cz), Color(0.26, 0.28, 0.32))
	Chamber.make_prop_box(self, Vector3(0.2, 0.2, 18.0), Vector3(-9.7, 3.4, 0), Color(0.30, 0.32, 0.35), false)
	Chamber.make_prop_box(self, Vector3(0.2, 0.2, 18.0), Vector3(9.7, 3.4, 0), Color(0.30, 0.32, 0.35), false)
	for dz in [6.0, 7.0, 8.0]:
		Chamber.make_prop_box(self, Vector3(0.6, 0.9, 0.6), Vector3(-8.5, 0.45, dz), Color(0.30, 0.34, 0.22))
	Chamber.make_prop_box(self, Vector3(1.6, 0.8, 1.0), Vector3(-7.0, 0.4, 7.5), Color(0.34, 0.30, 0.20))
	ActUtil.add_floor_decals(self, 20, 18, Vector3.ZERO, Color(0.86, 0.66, 0.12, 0.55))
	for db in [Vector3(2, 0, 3), Vector3(-3, 0, -4), Vector3(5, 0, 6)]:
		Chamber.make_prop_box(self, Vector3(0.5, 0.2, 0.4), db + Vector3(0, 0.1, 0), Color(0.24, 0.24, 0.26), false)


# --- Fuel storage bay (east, where the diesel comes from) ----------------
# A small attached room visible from the hall through the new x=10 doorway
# at z=-4. Doesn't change the puzzle - the diesel can still sits on the hall
# floor at (5, 0, 3.5) - but explains where the fuel racks came from and
# extends the hunter's beat away from the desk.

func _build_fuel_bay() -> void:
	# Bay x 10..18 (centre 14, w=8), z -7..-1 (centre -4, d=6), h=4.0.
	Chamber.add_floor_ceiling(self, 8, 6, 4.0, FLOOR, CEIL, Vector3(14, 0, -4))
	# East wall: split around the side-wing portal (z[-6,-2]) by helper.
	RoomGen.add_side_wing(self, {
		"host_axis": "x", "host_fixed": 18.0,
		"host_min": -7.0, "host_max": -1.0, "host_h": 4.0,
		"host_color": WALL,
		"theme": "industrial", "axis": "x",
		"along_min": 18.0, "along_max": 36.0, "perp": -4.0,
		"corridor_w": 4.0, "corridor_h": 3.2,
		"rooms_left": 2, "rooms_right": 2,
		"room_depth": 6.5, "room_w_along": 5.5, "room_h": 3.2,
		"seed": 5500,
	})
	ActUtil.wall_label(self, "FUEL CELLS", Vector3(18.15, 2.8, -4.0), 16, Color(0.78, 0.84, 0.6))
	Chamber.add_wall(self, "z", -7, 10, 18, 4.0, WALL)
	Chamber.add_wall(self, "z", -1, 10, 18, 4.0, WALL)

	# Diesel barrel pallets stacked along the back wall.
	for px in [11.5, 13.5, 15.5]:
		Chamber.make_prop_box(self, Vector3(1.6, 0.1, 1.0), Vector3(px, 0.05, -6.0), Color(0.22, 0.22, 0.20), false)
		for bz in [-6.3, -5.7]:
			Chamber.make_prop_box(self, Vector3(0.5, 0.9, 0.5), Vector3(px - 0.4, 0.5, bz), Color(0.74, 0.16, 0.12))
			Chamber.make_prop_box(self, Vector3(0.5, 0.9, 0.5), Vector3(px + 0.4, 0.5, bz), Color(0.74, 0.16, 0.12))
	# A tall fuel cabinet by the east wall.
	Chamber.make_prop_box(self, Vector3(0.6, 2.8, 1.6), Vector3(17.4, 1.4, -4.0), Color(0.30, 0.32, 0.36))
	# Spilled drum + slick across the floor.
	var slick := Chamber.make_prop_box(self, Vector3(0.7, 0.35, 0.4), Vector3(13.0, 0.18, -2.5), Color(0.50, 0.12, 0.08))
	slick.rotation_degrees = Vector3(0, 30, 0)
	ActUtil.blood_decal(self, Vector3(13.5, 0.02, -2.5), Vector2(2.4, 1.8), "up", Color(0.32, 0.08, 0.04, 0.55))
	# Hide locker in the back corner - the patrol now reaches in here.
	ActUtil.hide_locker(self, Vector3(11.4, 0, -1.5), 0.0)

	# Horror: a body crumpled by the cabinet, growth along the back wall.
	ActUtil.corpse(self, Vector3(16.4, 0, -2.0), -110.0, true, Color(0.24, 0.22, 0.18))
	ActUtil.signal_growth(self, Vector3(17.4, 0, -6.4), 1.1, Color(0.08, 0.13, 0.10))
	ActUtil.wall_scrawl(self, "DON'T LIGHT A MATCH IN HERE", Vector3(14.0, 2.6, -6.85), 0.0, 18, Color(0.5, 0.05, 0.06))
	ActUtil.wall_label(self, "FUEL STORAGE", Vector3(14.0, 3.2, -6.7), 16, Color(0.86, 0.66, 0.30))
	Interactable.make_examine(self, Vector3(17.10, 1.6, -4.0), Vector3(0.05, 0.5, 0.5),
		"Read the inventory clipboard",
		"Inventory clipboard hung on the cabinet. Updated weekly through " +
		"last winter. Final entry, in a different hand: 'twelve drums down, three to go, " +
		"and Renn says one is enough for the hall. one is never enough.'", 6.0)


func _ind(pos: Vector3, label: String) -> MeshInstance3D:
	var m := _emissive(Vector3(0.16, 0.16, 0.06), pos, Color(0.9, 0.12, 0.10), 1.2)
	ActUtil.wall_label(self, label, pos + Vector3(0, 0.22, 0), 9, Color(0.7, 0.74, 0.78))
	return m


func _emissive(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	m.material_override = mat
	add_child(m)
	return m


func _make_pickup(pos: Vector3, size: Vector3, color: Color, item_id: String, prompt: String) -> void:
	ActUtil.pickup(self, pos, size, color, item_id, prompt)


func _green(m: MeshInstance3D) -> void:
	if m == null:
		return
	var mat := m.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.2, 0.9, 0.3)
		mat.emission = Color(0.2, 0.9, 0.3)


func _do_fuel() -> void:
	fuel_ok = true
	_green(fuel_light)
	AudioManager.scrape()
	InteractionManager.show_examine("Fuel charged. FUEL reads green.", 3.0)


func _do_coolant() -> void:
	coolant_ok = true
	_green(coolant_light)
	AudioManager.scrape()
	InteractionManager.show_examine("The valve groans open. COOLANT reads green.", 3.0)


func _throw_breaker() -> void:
	if powered:
		return
	if not (fuel_ok and coolant_ok):
		InteractionManager.show_examine("The breaker won't seat. FUEL and COOLANT have to be green first.", 3.5)
		return
	powered = true
	_green(breaker_light)
	# The hall floods with light - and everything turns to look.
	for lp in [Vector3(-5, 4.6, 0), Vector3(5, 4.6, 0), Vector3(0, 4.6, -5), Vector3(0, 4.6, 5)]:
		ActUtil.add_omni(self, lp, Color(0.85, 0.92, 1.0), 3.0, 13.0, false)
	var t := exit_door.create_tween()
	t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	t.tween_callback(func() -> void:
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	AudioManager.door()
	InteractionManager.show_examine("The main bus catches. Light everywhere. The log said ninety seconds. Run.", 4.5)
