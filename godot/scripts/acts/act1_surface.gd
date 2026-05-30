extends Node3D
# VESPER - ACT 1: THE SURFACE
# You arrive at the dark, dead loading bay of Vesper Station. The aux generator
# is out of fuel. Find the diesel, fuel it, and hit the starter to release the
# inner door. Teaches the lamp + battery (R to reload), pickups, inventory (I),
# and the use_item puzzle pattern. No hunter yet - just a glimpse in the dark.

var exit_door: Node3D = null
var status_light: MeshInstance3D = null
var fueled := false
var started := false
var powered := false
var wing_door_open := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.14, 0.019)
	ActUtil.add_dust_motes(self, Vector3(0, 1.8, 0), Vector3(9, 2.2, 10), 70,
		Color(0.80, 0.86, 0.98, 0.16))

	# Loading bay: 18 x 20 x 4.5, single room.
	var wall := Color(0.34, 0.36, 0.40)
	Chamber.add_floor_ceiling(self, 18, 20, 4.5, Color(0.46, 0.49, 0.55), Color(0.16, 0.17, 0.20))
	Chamber.add_wall(self, "x", -9, -10, 10, 4.5, wall)
	Chamber.add_wall(self, "x", 9, -10, 10, 4.5, wall)
	Chamber.add_wall(self, "z", 10, -9, 9, 4.5, wall)
	Chamber.add_wall(self, "z", -10, -9, 9, 4.5, wall, 0.0)

	# Inner door (north) - sealed until power is restored.
	exit_door = Chamber.add_door(self, "z", -10 + 0.05, 0, "INNER DOOR",
		Color(0.26, 0.30, 0.36), Callable(), "", true)

	_build_generator()
	_build_clutter()
	_build_detail()
	_build_north_wing()

	# Pickups.
	_make_pickup(Vector3(6.6, 0.32, 3.2), Vector3(0.34, 0.5, 0.26), Color(0.74, 0.16, 0.12),
		"diesel_can", "Take the diesel can")
	_make_pickup(Vector3(7.2, 1.0, -1.2), Vector3(0.2, 0.1, 0.34), Color(0.45, 0.78, 0.5),
		"spare_battery", "Take the spare cell")

	# Notes.
	Interactable.make_note(self, Vector3(0.9, 0.04, 7.0), "v_arrival", "Read the dispatch")
	Interactable.make_note(self, Vector3(-5.6, 0.04, -1.4), "v_bay", "Read the scrawl")
	# Recovered tablet + wall printout from somewhere called Crestfall-9. They
	# don't belong here. Someone (you?) carried them down.
	Interactable.make_note(self, Vector3(8.4, 0.18, 5.0), "note_1", "Recovered tablet")
	Interactable.make_note(self, Vector3(-2.4, 1.6, -9.85), "note_8", "Read the wall printout")

	# The dead and their blood.
	ActUtil.corpse(self, Vector3(-7.6, 0, 1.4), 64.0, true, Color(0.20, 0.22, 0.16))
	ActUtil.blood_decal(self, Vector3(-6.4, 0.02, 0.2), Vector2(1.6, 1.1))
	ActUtil.blood_wall(self, Vector3(-8.88, 1.4, 2.2), Vector2(1.3, 1.7), 90.0)
	ActUtil.corpse(self, Vector3(7.0, 0, 6.6), -120.0, true, Color(0.16, 0.18, 0.22))

	# Dread: something stands in the far dark and is gone when you look.
	ActUtil.haunt(self, {
		"intensity": 0.18, "flicker": true, "flicker_rate": 0.8,
		"peekers": [{"pos": Vector3(7.6, 0, -8.4), "kind": HorrorShape.KIND_HARGROVE, "rot": 205.0}],
	})

	# Spawn near the south doors, facing into the bay.
	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 8.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	# The inner door (z=-10) opens on power and leads into the north wing;
	# the act ends at the far station door past the muster checkpoint.
	if wing_door_open and GameState.player and GameState.player.global_position.z < -32.6:
		SceneRouter.transition_to("act2")


func _open_wing() -> void:
	wing_door_open = true


# --- Build helpers --------------------------------------------------------

func _build_generator() -> void:
	var metal := Color(0.28, 0.30, 0.33)
	var dark := Color(0.14, 0.15, 0.17)
	Chamber.make_prop_box(self, Vector3(2.4, 0.5, 1.4), Vector3(-6.2, 0.25, -3.0), dark)
	Chamber.make_prop_box(self, Vector3(2.1, 1.05, 1.1), Vector3(-6.2, 0.95, -3.0), metal)
	Chamber.make_prop_box(self, Vector3(0.18, 1.4, 0.18), Vector3(-7.0, 1.6, -3.4), dark, false)
	Chamber.make_prop_box(self, Vector3(0.18, 0.18, 0.9), Vector3(-7.0, 2.25, -3.0), dark, false)
	Chamber.make_prop_box(self, Vector3(0.12, 0.7, 0.9), Vector3(-5.12, 1.0, -3.0), Color(0.20, 0.21, 0.24), false)
	# Status light (red = dead).
	status_light = _emissive_box(self, Vector3(0.12, 0.12, 0.05), Vector3(-5.05, 1.32, -3.35), Color(0.90, 0.12, 0.10), 1.2)
	# Fuel port (needs the diesel can).
	var port := Chamber.make_prop_box(self, Vector3(0.34, 0.34, 0.40), Vector3(-5.0, 0.6, -3.5), Color(0.32, 0.30, 0.22))
	Interactable.attach(port, "Pour in the diesel", "use_item", {
		"required_item": "diesel_can", "consume": true,
		"on_use": Callable(self, "_fuel_generator"),
		"locked_text": "The tank's bone dry. It runs on diesel - find a can.",
	})
	# Starter.
	var starter := Chamber.make_prop_box(self, Vector3(0.26, 0.40, 0.18), Vector3(-5.0, 1.25, -2.5), Color(0.50, 0.42, 0.12))
	Interactable.attach(starter, "Hit the starter", "trigger_event", {"callback": Callable(self, "_start_generator")})


func _build_clutter() -> void:
	var crate := Color(0.30, 0.26, 0.18)
	Chamber.make_prop_box(self, Vector3(1.1, 1.0, 1.1), Vector3(7.4, 0.5, 4.0), crate)
	Chamber.make_prop_box(self, Vector3(1.0, 0.9, 1.0), Vector3(6.0, 0.45, 4.2), crate)
	Chamber.make_prop_box(self, Vector3(1.1, 0.6, 1.1), Vector3(7.4, 1.3, 4.0), crate)
	# Workbench (east) - the spare cell sits on it.
	Chamber.make_prop_box(self, Vector3(2.0, 0.10, 0.8), Vector3(7.4, 0.9, -1.2), Color(0.30, 0.27, 0.22))
	for lx in [6.5, 8.3]:
		for lz in [-1.5, -0.9]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.9, 0.08), Vector3(lx, 0.45, lz), Color(0.20, 0.18, 0.15), false)
	# Shelving (south wall).
	Chamber.make_prop_box(self, Vector3(3.0, 0.08, 0.5), Vector3(-5.0, 1.4, 9.5), Color(0.26, 0.24, 0.20), false)
	Chamber.make_prop_box(self, Vector3(3.0, 0.08, 0.5), Vector3(-5.0, 0.8, 9.5), Color(0.26, 0.24, 0.20), false)
	# Hanging chains.
	for cx in [-2.0, 2.5]:
		Chamber.make_prop_box(self, Vector3(0.06, 1.6, 0.06), Vector3(cx, 3.4, -6.0), Color(0.14, 0.14, 0.16), false)
	# Snow blown in under the south doors + frost glaze by the inner door.
	Chamber.make_prop_box(self, Vector3(3.0, 0.2, 1.2), Vector3(3.0, 0.1, 9.2), Color(0.80, 0.84, 0.90), false)
	ActUtil.blood_decal(self, Vector3(0, 0.02, -8.5), Vector2(3.0, 2.0), "up", Color(0.70, 0.78, 0.90, 0.25))


func _make_pickup(pos: Vector3, size: Vector3, color: Color, item_id: String, prompt: String) -> void:
	ActUtil.pickup(self, pos, size, color, item_id, prompt)


func _emissive_box(parent: Node, size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
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
	parent.add_child(m)
	return m


# --- North wing: decon corridor + muster checkpoint -----------------------
# Past the inner door (which the generator unseals). The bay's z=-10 wall is
# already built with a centre opening, so we only add the new geometry north
# of it. Corridor is low and narrow (claustrophobic) and opens into a taller
# muster hall; the act now ends at the far STATION ACCESS door.

func _build_north_wing() -> void:
	var wall := Color(0.30, 0.32, 0.37)
	var floor_c := Color(0.40, 0.43, 0.49)
	var ceil_c := Color(0.14, 0.15, 0.18)

	# Decon corridor: x -3..3, z -10..-21, low 3.0 ceiling.
	Chamber.add_floor_ceiling(self, 6, 11, 3.0, floor_c, ceil_c, Vector3(0, 0, -15.5))
	Chamber.add_wall(self, "x", -3, -21, -10, 3.0, wall)
	Chamber.add_wall(self, "x", 3, -21, -10, 3.0, wall)

	# Muster checkpoint: x -7..7, z -21..-33, taller 4.0 ceiling.
	Chamber.add_floor_ceiling(self, 14, 12, 4.0, floor_c, ceil_c, Vector3(0, 0, -27))
	Chamber.add_wall(self, "x", -7, -33, -21, 4.0, wall)
	Chamber.add_wall(self, "x", 7, -33, -21, 4.0, wall)
	# Divider between corridor and muster (doorway at centre).
	Chamber.add_wall(self, "z", -21, -7, 7, 4.0, wall, 0.0)
	# Far wall + the act-end door.
	Chamber.add_wall(self, "z", -33, -7, 7, 4.0, wall, 0.0)
	Chamber.add_door(self, "z", -33 + 0.05, 0, "STATION ACCESS",
		Color(0.26, 0.30, 0.36), Callable(self, "_open_wing"), "Force the access door")

	# Decon dressing: shower heads, a chem cabinet, hosed-down floor.
	for sx in [-2.2, 0.0, 2.2]:
		Chamber.make_prop_box(self, Vector3(0.16, 0.16, 0.5), Vector3(sx, 2.7, -13.0), Color(0.55, 0.58, 0.62), false)
		Chamber.make_prop_box(self, Vector3(0.08, 0.4, 0.08), Vector3(sx, 2.45, -13.0), Color(0.45, 0.47, 0.50), false)
	Chamber.make_prop_box(self, Vector3(0.7, 1.4, 0.4), Vector3(-2.6, 0.7, -18.5), Color(0.24, 0.34, 0.30))
	ActUtil.wall_label(self, "DECONTAMINATION", Vector3(0, 2.7, -20.85), 15, Color(0.62, 0.80, 0.86))
	ActUtil.blood_decal(self, Vector3(0.6, 0.02, -17.5), Vector2(1.2, 2.4), "up", Color(0.16, 0.03, 0.03, 0.6))

	# Muster hall: benches, a roll-board, lockers (foreshadow hiding), bodies.
	for bz in [-24.5, -29.5]:
		Chamber.make_prop_box(self, Vector3(4.0, 0.45, 0.5), Vector3(-4.4, 0.22, bz), Color(0.32, 0.28, 0.20))
	Chamber.make_prop_box(self, Vector3(0.5, 0.5, 4.0), Vector3(4.6, 0.25, -27.0), Color(0.32, 0.28, 0.20))
	ActUtil.hide_locker(self, Vector3(-6.4, 0, -25.0), 90.0)
	ActUtil.hide_locker(self, Vector3(-6.4, 0, -26.7), 90.0)
	Chamber.make_prop_box(self, Vector3(2.2, 1.3, 0.1), Vector3(5.4, 1.5, -27.0), Color(0.16, 0.18, 0.20), false)
	ActUtil.wall_label(self, "MUSTER - ALL HANDS", Vector3(0, 3.0, -32.8), 20, Color(0.86, 0.84, 0.58))
	ActUtil.wall_label(self, "STATION ACCESS", Vector3(0, 2.55, -32.9), 13, Color(0.80, 0.50, 0.40))
	ActUtil.corpse(self, Vector3(-4.4, 0, -24.5), -10.0, true, Color(0.18, 0.20, 0.24))
	ActUtil.corpse(self, Vector3(3.0, 0, -30.6), 120.0, true, Color(0.16, 0.18, 0.22))
	ActUtil.blood_wall(self, Vector3(-6.9, 1.5, -29.0), Vector2(1.6, 1.9), 90.0)
	ActUtil.add_dust_motes(self, Vector3(0, 1.8, -27), Vector3(6, 2.0, 5), 50,
		Color(0.78, 0.84, 0.96, 0.14))

	# A printed roster you can read, and the dread of being watched from the dark.
	Interactable.make_examine(self, Vector3(5.36, 1.5, -27.0), Vector3(0.05, 0.7, 1.6),
		"Read the muster roster",
		"MUSTER ROSTER - 14 names. Eleven are crossed out in the same hand. " +
		"The last three share one scrawled bracket, and beside it: 'went down to bring them up.'", 6.0)
	ActUtil.add_peeker(self, Vector3(6.2, 0, -31.0), HorrorShape.KIND_HARGROVE, 215.0)


# --- Generator puzzle -----------------------------------------------------

func _fuel_generator() -> void:
	fueled = true
	AudioManager.scrape()
	InteractionManager.show_examine("Diesel glugs into the tank. Now the starter.", 3.5)


func _start_generator() -> void:
	if started:
		return
	if not fueled:
		InteractionManager.show_examine("It just coughs and dies. The tank's empty - find diesel.", 3.5)
		return
	_power_on()


func _power_on() -> void:
	started = true
	powered = true
	AudioManager.door()
	if status_light:
		var m := status_light.material_override as StandardMaterial3D
		if m:
			m.albedo_color = Color(0.20, 0.90, 0.30)
			m.emission = Color(0.20, 0.90, 0.30)
	# A work light kicks on over the generator.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.85, 0.90, 1.0)
	lamp.light_energy = 3.0
	lamp.omni_range = 10.0
	lamp.position = Vector3(-4.0, 3.2, -2.0)
	add_child(lamp)
	# Release the inner door.
	if exit_door:
		var t := exit_door.create_tween()
		t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.6)
		t.tween_callback(func() -> void:
			exit_door.visible = false
			for c in exit_door.get_children():
				if c is CollisionShape3D:
					c.disabled = true
		)
	InteractionManager.show_examine("The generator catches. Somewhere a lock thunks back. The inner door is open.", 4.5)


# --- Set dressing: fill the bay so it reads as a real, abandoned space ----

func _build_detail() -> void:
	var pipe := Color(0.30, 0.33, 0.36)
	var pipe2 := Color(0.40, 0.30, 0.18)
	var steel := Color(0.30, 0.31, 0.34)
	var crate := Color(0.30, 0.26, 0.18)

	# Ceiling: duct runs, side cable trays, dead hanging lamps + chains.
	Chamber.make_prop_box(self, Vector3(0.7, 0.6, 19.0), Vector3(5.0, 4.0, 0), steel, false)
	Chamber.make_prop_box(self, Vector3(11.0, 0.5, 0.6), Vector3(0, 4.0, -6.5), steel, false)
	for tx in [-8.4, 8.4]:
		Chamber.make_prop_box(self, Vector3(0.4, 0.12, 18.0), Vector3(tx, 4.05, 0), Color(0.18, 0.18, 0.20), false)
	for lp in [Vector3(-4, 3.6, -4), Vector3(4, 3.6, -4), Vector3(-4, 3.6, 4), Vector3(4, 3.6, 4)]:
		Chamber.make_prop_box(self, Vector3(0.6, 0.25, 0.6), lp, Color(0.16, 0.16, 0.18), false)
		Chamber.make_prop_box(self, Vector3(0.04, 0.6, 0.04), lp + Vector3(0, 0.45, 0), Color(0.10, 0.10, 0.12), false)
	for cc in [Vector3(-1.5, 3.3, -7.5), Vector3(2.0, 3.0, -2.0), Vector3(-5.5, 3.4, 6.5), Vector3(6.5, 3.2, 1.0)]:
		Chamber.make_prop_box(self, Vector3(0.05, randf_range(1.0, 1.9), 0.05), cc, Color(0.12, 0.12, 0.14), false)

	# West wall: pipe runs, locker bank (foreshadows hiding), shelving rack.
	for wz in [-8.0, -3.0, 3.0, 8.0]:
		Chamber.make_prop_box(self, Vector3(0.16, 3.8, 0.16), Vector3(-8.78, 1.9, wz), pipe, false)
	Chamber.make_prop_box(self, Vector3(0.18, 0.18, 18.0), Vector3(-8.7, 2.9, 0), pipe2, false)
	Chamber.make_prop_box(self, Vector3(0.18, 0.18, 18.0), Vector3(-8.7, 0.7, 0), pipe, false)
	for i in 4:
		var lz: float = 2.2 + i * 0.86
		Chamber.make_prop_box(self, Vector3(0.55, 1.9, 0.82), Vector3(-8.4, 0.95, lz), Color(0.22, 0.30, 0.34))
		Chamber.make_prop_box(self, Vector3(0.02, 0.5, 0.5), Vector3(-8.10, 1.45, lz), Color(0.05, 0.07, 0.08), false)
	_shelf_rack(Vector3(-8.0, 0, -6.5), 0.0)

	# East wall: pipes, fire point, faint first-aid cross.
	for wz2 in [-7.0, -2.0, 5.0]:
		Chamber.make_prop_box(self, Vector3(0.16, 3.8, 0.16), Vector3(8.78, 1.9, wz2), pipe, false)
	Chamber.make_prop_box(self, Vector3(0.18, 0.18, 18.0), Vector3(8.7, 3.0, 0), pipe, false)
	Chamber.make_prop_box(self, Vector3(0.2, 0.5, 0.2), Vector3(8.6, 1.2, 0.5), Color(0.70, 0.12, 0.10))
	Chamber.make_prop_box(self, Vector3(0.1, 0.4, 0.4), Vector3(8.78, 1.6, -3.0), Color(0.86, 0.88, 0.90), false)
	_emissive_box(self, Vector3(0.06, 0.18, 0.06), Vector3(8.70, 1.6, -3.0), Color(0.20, 0.85, 0.30), 0.5)
	_emissive_box(self, Vector3(0.18, 0.06, 0.06), Vector3(8.70, 1.6, -3.0), Color(0.20, 0.85, 0.30), 0.5)

	# North wall around the inner door: dim EXIT, dead panel, pipe.
	_emissive_box(self, Vector3(0.7, 0.22, 0.05), Vector3(0, 2.7, -9.78), Color(0.50, 0.06, 0.04), 0.8)
	ActUtil.wall_label(self, "EXIT", Vector3(0, 2.7, -9.6), 16, Color(0.90, 0.40, 0.35))
	Chamber.make_prop_box(self, Vector3(0.7, 0.9, 0.08), Vector3(-2.0, 1.4, -9.85), Color(0.16, 0.18, 0.22), false)
	Chamber.make_prop_box(self, Vector3(0.16, 3.6, 0.16), Vector3(1.6, 1.8, -9.78), pipe, false)

	# South wall (the way you came in): roller door, coats, dispatch desk.
	for i2 in 8:
		Chamber.make_prop_box(self, Vector3(5.2, 0.34, 0.12), Vector3(0, 0.35 + i2 * 0.36, 9.85), Color(0.33, 0.34, 0.37), false)
	Chamber.make_prop_box(self, Vector3(2.6, 0.06, 0.06), Vector3(-6.0, 1.95, 9.4), Color(0.20, 0.20, 0.22), false)
	var parkas := [Color(0.50, 0.20, 0.15), Color(0.20, 0.30, 0.45), Color(0.35, 0.36, 0.20), Color(0.15, 0.15, 0.18)]
	for pi in parkas.size():
		Chamber.make_prop_box(self, Vector3(0.5, 1.05, 0.26), Vector3(-7.0 + pi * 0.62, 1.4, 9.45), parkas[pi], false)
	Chamber.make_prop_box(self, Vector3(1.8, 0.10, 0.9), Vector3(4.6, 0.92, 9.1), Color(0.30, 0.27, 0.22))
	for dlx in [3.85, 5.35]:
		for dlz in [8.75, 9.45]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.9, 0.08), Vector3(dlx, 0.45, dlz), Color(0.20, 0.18, 0.15), false)
	for k in 3:
		Chamber.make_prop_box(self, Vector3(0.28, 0.01, 0.36), Vector3(4.2 + k * 0.25, 0.98, 9.1), Color(0.85, 0.85, 0.82), false)

	# Centre floor: snowcat, structural column, pallet, spools, tools, chair.
	_snowcat(Vector3(-1.5, 0, 3.4), 24.0)
	_column(2.6, -0.5)
	Chamber.make_prop_box(self, Vector3(1.2, 0.12, 1.0), Vector3(-2.8, 0.06, -0.5), pipe2, false)
	for sx in [-3.1, -2.5]:
		Chamber.make_prop_box(self, Vector3(0.5, 0.4, 0.8), Vector3(sx, 0.32, -0.5), Color(0.40, 0.38, 0.30))
	_spool(Vector3(2.0, 0.55, 1.6), Color(0.30, 0.22, 0.12))
	_spool(Vector3(2.9, 0.55, 1.9), Color(0.30, 0.22, 0.12))
	Chamber.make_prop_box(self, Vector3(0.6, 0.35, 0.32), Vector3(0.8, 0.18, 5.2), Color(0.70, 0.18, 0.12))
	for tl in [Vector3(1.3, 0.04, 5.0), Vector3(0.4, 0.04, 5.6), Vector3(1.0, 0.04, 4.6)]:
		Chamber.make_prop_box(self, Vector3(0.28, 0.05, 0.06), tl, Color(0.50, 0.50, 0.55), false)
	var ch := Chamber.make_chair(self, Vector3(-3.4, 0.45, 6.4), Color(0.30, 0.31, 0.34), 20.0)
	ch.rotation_degrees = Vector3(86, 20, 0)

	# NE quadrant: pallet/crates, drum row, pallet jack, tarp-covered body.
	Chamber.make_prop_box(self, Vector3(1.2, 0.12, 1.0), Vector3(5.0, 0.06, -6.0), pipe2, false)
	Chamber.make_prop_box(self, Vector3(1.0, 0.9, 0.9), Vector3(5.0, 0.5, -6.0), crate)
	Chamber.make_prop_box(self, Vector3(0.9, 0.7, 0.9), Vector3(4.6, 1.35, -6.0), crate)
	for dz in [-5.5, -6.4, -7.3]:
		_drum(Vector3(8.0, 0.45, dz), Color(0.30, 0.34, 0.22))
	_drum(Vector3(3.6, 0.28, -7.6), Color(0.50, 0.28, 0.10), true)
	Chamber.make_prop_box(self, Vector3(0.5, 0.18, 1.4), Vector3(4.4, 0.10, -4.6), Color(0.70, 0.50, 0.10))
	Chamber.make_prop_box(self, Vector3(0.12, 0.9, 0.12), Vector3(4.4, 0.55, -4.0), Color(0.20, 0.20, 0.22), false)
	ActUtil.corpse(self, Vector3(6.2, 0, -4.2), 150.0, true, Color(0.15, 0.16, 0.20))
	Chamber.make_prop_box(self, Vector3(1.0, 0.2, 2.0), Vector3(6.2, 0.2, -4.2), Color(0.18, 0.20, 0.24), false)

	# NW quadrant near the generator: drums + crate stack.
	for dz2 in [-8.0, -8.7]:
		_drum(Vector3(-4.6, 0.45, dz2), Color(0.30, 0.34, 0.22))
	Chamber.make_prop_box(self, Vector3(0.9, 0.8, 0.9), Vector3(-7.5, 0.4, -7.5), crate)
	Chamber.make_prop_box(self, Vector3(0.8, 0.6, 0.8), Vector3(-7.7, 1.1, -7.5), crate)

	# Storytelling: a drag-mark of blood from the centre into the NE dark.
	for i3 in 7:
		var t: float = i3 / 6.0
		var p := Vector3(lerpf(0.5, 6.8, t), 0.02, lerpf(-1.0, -7.8, t))
		ActUtil.blood_decal(self, p, Vector2(0.5, 0.9), "up", Color(0.18, 0.03, 0.03, 0.7))
	for fp in [Vector3(-7, 0.02, -9), Vector3(7.5, 0.02, 8), Vector3(-8, 0.02, 7)]:
		ActUtil.blood_decal(self, fp, Vector2(1.6, 1.4), "up", Color(0.70, 0.78, 0.90, 0.18))

	# Signage (billboards toward the player).
	ActUtil.wall_label(self, "BAY 02", Vector3(-8.5, 3.2, 5.0), 26, Color(0.86, 0.88, 0.60))
	ActUtil.wall_label(self, "MUSTER POINT", Vector3(8.5, 3.0, -4.5), 18, Color(0.70, 0.86, 0.90))
	ActUtil.wall_label(self, "NO OPEN FLAME", Vector3(-5.0, 2.4, -3.0), 16, Color(0.90, 0.55, 0.30))


func _shelf_rack(base: Vector3, facing: float) -> void:
	var root := Node3D.new()
	root.position = base
	root.rotation_degrees = Vector3(0, facing, 0)
	add_child(root)
	var frame := Color(0.28, 0.24, 0.16)
	for sy in [0.5, 1.2, 1.9, 2.5]:
		Chamber.make_prop_box(root, Vector3(1.6, 0.06, 0.8), Vector3(0, sy, 0), frame, false)
	for ux in [-0.74, 0.74]:
		for uz in [-0.36, 0.36]:
			Chamber.make_prop_box(root, Vector3(0.08, 2.6, 0.08), Vector3(ux, 1.3, uz), frame, false)
	Chamber.make_prop_box(root, Vector3(0.4, 0.4, 0.5), Vector3(-0.4, 0.78, 0), Color(0.40, 0.36, 0.28), false)
	Chamber.make_prop_box(root, Vector3(0.3, 0.5, 0.4), Vector3(0.4, 1.52, 0), Color(0.30, 0.40, 0.45), false)
	Chamber.make_prop_box(root, Vector3(0.5, 0.3, 0.5), Vector3(0.1, 2.2, 0), Color(0.45, 0.30, 0.20), false)


func _drum(pos: Vector3, color: Color, tipped: bool = false) -> void:
	var b := StaticBody3D.new()
	b.position = pos
	if tipped:
		b.rotation_degrees = Vector3(90, randf_range(0, 360), 0)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 0.9
	cm.radial_segments = 14
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.4
	mat.roughness = 0.55
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.56, 0.9, 0.56)
	cs.shape = sh
	b.add_child(cs)
	add_child(b)


func _spool(pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.55
	cm.bottom_radius = 0.55
	cm.height = 0.5
	cm.radial_segments = 18
	mi.mesh = cm
	mi.rotation_degrees = Vector3(0, 0, 90)
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mi.material_override = mat
	add_child(mi)


func _column(x: float, z: float) -> void:
	Chamber.make_prop_box(self, Vector3(0.35, 4.5, 0.35), Vector3(x, 2.25, z), Color(0.30, 0.31, 0.34))
	Chamber.make_prop_box(self, Vector3(0.5, 4.5, 0.12), Vector3(x, 2.25, z - 0.18), Color(0.26, 0.27, 0.30), false)
	Chamber.make_prop_box(self, Vector3(0.5, 4.5, 0.12), Vector3(x, 2.25, z + 0.18), Color(0.26, 0.27, 0.30), false)


func _snowcat(base: Vector3, facing: float) -> void:
	var root := Node3D.new()
	root.position = base
	root.rotation_degrees = Vector3(0, facing, 0)
	add_child(root)
	var body := Color(0.60, 0.45, 0.10)
	var dark := Color(0.12, 0.12, 0.14)
	var glass := Color(0.05, 0.07, 0.10)
	for sx in [-0.95, 0.95]:
		Chamber.make_prop_box(root, Vector3(0.55, 0.5, 3.1), Vector3(sx, 0.28, 0), dark, false, "tread")
	Chamber.make_prop_box(root, Vector3(2.2, 0.7, 2.7), Vector3(0, 0.85, 0.1), body, true, "chassis")
	Chamber.make_prop_box(root, Vector3(1.7, 1.05, 1.5), Vector3(0, 1.65, -0.45), body, true, "cab")
	Chamber.make_prop_box(root, Vector3(1.5, 0.7, 0.05), Vector3(0, 1.75, -1.18), glass, false)
	for gx in [-0.86, 0.86]:
		Chamber.make_prop_box(root, Vector3(0.05, 0.7, 1.2), Vector3(gx, 1.75, -0.45), glass, false)
	Chamber.make_prop_box(root, Vector3(0.08, 0.9, 0.08), Vector3(-0.8, 2.2, 0.3), dark, false)
	Chamber.make_prop_box(root, Vector3(0.08, 0.9, 0.08), Vector3(0.8, 2.2, 0.3), dark, false)
	Chamber.make_prop_box(root, Vector3(1.7, 0.08, 0.08), Vector3(0, 2.6, 0.3), dark, false)
	Chamber.make_prop_box(root, Vector3(2.4, 0.6, 0.18), Vector3(0, 0.45, -1.7), Color(0.40, 0.32, 0.10), true, "plow")
	for hx in [-0.6, 0.6]:
		_emissive_box(root, Vector3(0.18, 0.14, 0.05), Vector3(hx, 0.95, -1.42), Color(0.50, 0.45, 0.30), 0.15)
