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

	# Pickups.
	_make_pickup(Vector3(6.6, 0.32, 3.2), Vector3(0.34, 0.5, 0.26), Color(0.74, 0.16, 0.12),
		"diesel_can", "Take the diesel can")
	_make_pickup(Vector3(7.2, 1.0, -1.2), Vector3(0.2, 0.1, 0.34), Color(0.45, 0.78, 0.5),
		"spare_battery", "Take the spare cell")

	# Notes.
	Interactable.make_note(self, Vector3(0.9, 0.04, 7.0), "v_arrival", "Read the dispatch")
	Interactable.make_note(self, Vector3(-5.6, 0.04, -1.4), "v_bay", "Read the scrawl")

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
	if powered and GameState.player and GameState.player.global_position.z < -9.5:
		SceneRouter.transition_to("act2")


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
	status_light = _emissive_box(Vector3(0.12, 0.12, 0.05), Vector3(-5.05, 1.32, -3.35), Color(0.90, 0.12, 0.10), 1.2)
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
	var body := Chamber.make_prop_box(self, size, pos, color, true, "pickup")
	Interactable.attach(body, prompt, "collect_item", {"item_id": item_id})


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
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
