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

	var stalker := HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, 0, -6.0), 0.0)
	stalker.set_stalk([Vector3(-6, 0, 5), Vector3(6, 0, 5), Vector3(6, 0, -5), Vector3(-6, 0, -5)], 1.3, 4.2)
	add_child(stalker)
	ShapeTracker.register(stalker)

	ActUtil.haunt(self, {"intensity": 0.55, "flicker": true, "flicker_rate": 1.6})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 7.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if powered and GameState.player and GameState.player.global_position.z < -8.6:
		SceneRouter.transition_to("act6")


func _build_hall() -> void:
	Chamber.add_room(self, 20, 18, 5.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": -9.0, "gap": 0.0}, {"axis": "z", "fixed": 9.0, "gap": 0.0}])
	exit_door = Chamber.add_door(self, "z", -9 + 0.05, 0, "MAIN DOOR", Color(0.24, 0.26, 0.32), Callable(), "", true)
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
	_make_pickup(Vector3(7.5, 0.95, -6.0), Vector3(0.5, 0.12, 0.16), Color(0.6, 0.55, 0.2), "valve_handle", "Take the valve handle")
	Chamber.make_prop_box(self, Vector3(1.6, 0.9, 0.7), Vector3(7.6, 0.45, -6.0), Color(0.30, 0.32, 0.36))
	_make_pickup(Vector3(7.8, 0.32, 5.5), Vector3(0.34, 0.5, 0.26), Color(0.74, 0.16, 0.12), "diesel_can", "Take the diesel can")
	for rz in [4.5, 5.5, 6.5]:
		Chamber.make_prop_box(self, Vector3(0.5, 0.5, 0.5), Vector3(8.8, 0.25, rz), Color(0.30, 0.30, 0.22))

	# Hide spots + dressing + dread.
	ActUtil.hide_locker(self, Vector3(9.5, 0, 0.0), 90.0)
	ActUtil.hide_locker(self, Vector3(-9.4, 0, 6.5), 90.0)
	Interactable.make_note(self, Vector3(-2.5, 1.12, -0.3), "v_gen", "Read the plant log")
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
	var body := Chamber.make_prop_box(self, size, pos, color, true, "pickup")
	Interactable.attach(body, prompt, "collect_item", {"item_id": item_id})


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
