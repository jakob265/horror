extends Node3D
# ACT 1 - CRYO BAY.
# Mara wakes in a pod. Five pods, one welded shut. Note 1 + keycard under crate.
# OLEN Intercom 1 fires 3s after first move.

const POD_XS := [-4.4, -2.2, 0.0, 2.2, 4.4]
const WELDED_IDX := 2

var keycard_node: StaticBody3D = null
var exit_door: Node3D = null
var crate: StaticBody3D = null


func _ready() -> void:
	# Light rig - red emergency
	_setup_lighting(Color(0.86, 0.43, 0.43), Color(0.18, 0.05, 0.06), 0.020)

	# Room: 12 x 16 x 4
	Chamber.add_floor_ceiling(self, 12, 16, 4, Color(0.42, 0.40, 0.40), Color(0.25, 0.22, 0.25))
	# West/east/south solid; north has exit door gap
	var wall := Color(0.55, 0.45, 0.45)
	Chamber.add_wall(self, "x", -6, -8, 8, 4, wall)
	Chamber.add_wall(self, "x", 6, -8, 8, 4, wall)
	Chamber.add_wall(self, "z", -8, -6, 6, 4, wall)
	Chamber.add_wall(self, "z", 8, -6, 6, 4, wall, 0.0)
	# Exit door (locked until keycard)
	exit_door = Chamber.add_door(self, "z", 8 - 0.05, 0, "EXIT", Color(0.30, 0.35, 0.45),
		_on_exit_opened, "Try door")
	# Override its trigger to gate on keycard
	exit_door.set_meta("interact", {"label": "Try door", "kind": "trigger_event", "callback": Callable(self, "_try_open_exit")})

	# Five cryo pods along back (z=-5)
	for i in POD_XS.size():
		_make_pod(Vector3(POD_XS[i], 0, -5), i == WELDED_IDX)

	# Note 1 on the floor next to Mara's pod (rightmost)
	Interactable.make_note(self, Vector3(4.4, 0.04, -3.0), "note_1", "Read recorder")

	# Crate hiding the keycard
	crate = Chamber.make_prop_box(self, Vector3(0.7, 0.5, 0.9), Vector3(-3.2, 0.25, 2.0), Color(0.27, 0.23, 0.16))
	crate.rotation_degrees = Vector3(0, 25, 60)
	Interactable.attach(crate, "Move crate", "trigger_event", {"callback": Callable(self, "_move_crate")})

	# Keycard (hidden until crate moved)
	keycard_node = StaticBody3D.new()
	keycard_node.position = Vector3(-3.05, 0.05, 2.05)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.22, 0.04, 0.13)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.70, 0.78, 0.94)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	keycard_node.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(0.22, 0.04, 0.13)
	shape.shape = col
	keycard_node.add_child(shape)
	keycard_node.visible = false
	add_child(keycard_node)
	Interactable.attach(keycard_node, "Take keycard", "trigger_event", {"callback": Callable(self, "_take_keycard")})

	# Intercom 1 panel on west wall
	var intercom := IntercomPanel.create(Vector3(-5.85, 1.7, 0), 90)
	add_child(intercom)
	OlenManager.add_proximity_trigger(1, Vector3(0, 1.6, 0), intercom, 12.0, 3.0, true)

	# Spawn the player
	if GameState.player:
		GameState.player.global_position = Vector3(4.4, 0.5, -3.0)
		GameState.player.rotation_degrees.y = 180


func _process(_dt: float) -> void:
	if GameState.cryo_door_open and GameState.player and GameState.player.global_position.z > 8.0:
		SceneRouter.transition_to("act2")


# --- Pod construction ----------------------------------------------------

func _make_pod(pos: Vector3, welded: bool) -> void:
	# Base
	Chamber.make_prop_box(self, Vector3(0.9, 0.4, 2.4), pos + Vector3(0, 0.20, 0), Color(0.20, 0.22, 0.25))
	# Body
	Chamber.make_prop_box(self, Vector3(0.9, 1.0, 2.4), pos + Vector3(0, 0.95, 0), Color(0.27, 0.30, 0.35))
	# Lid
	if welded:
		Chamber.make_prop_box(self, Vector3(0.85, 0.10, 2.30), pos + Vector3(0, 1.6, 0), Color(0.16, 0.16, 0.18))
		# Crayon drawing prop
		var draw := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.55, 0.45)
		draw.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.96, 0.90, 0.71)
		draw.material_override = mat
		draw.position = pos + Vector3(0, 1.10, -1.205)
		add_child(draw)
		Interactable.make_examine(self, pos + Vector3(0, 1.10, -1.20), Vector3(0.55, 0.45, 0.05),
			"Look at the drawing",
			"DADDY and ME, in crayon. Charred at the edges. Felix kept it taped to his pod.",
			5.0, Color(0.7, 0.6, 0.5))
	else:
		# Open lid tilted up
		var lid := Chamber.make_prop_box(self, Vector3(0.85, 0.10, 2.30), pos + Vector3(0, 1.8, -0.6), Color(0.23, 0.27, 0.33))
		lid.rotation_degrees = Vector3(-25, 0, 0)


# --- Callbacks -----------------------------------------------------------

func _move_crate() -> void:
	if crate == null: return
	var tween := crate.create_tween()
	tween.tween_property(crate, "position", crate.position + Vector3(0.9, 0, 0.5), 0.5)
	AudioManager.scrape()
	get_tree().create_timer(0.5).timeout.connect(func():
		if keycard_node:
			keycard_node.visible = true
	)


func _take_keycard() -> void:
	GameState.cryo_keycard = true
	if keycard_node:
		keycard_node.queue_free()
		keycard_node = null
	InteractionManager.show_examine("Keycard registered.  Try the door.", 4.0)


func _try_open_exit() -> void:
	if not GameState.cryo_keycard:
		InteractionManager.show_examine("Door locked.  A keycard slot blinks red.", 3.5)
		return
	if GameState.cryo_door_open: return
	GameState.cryo_door_open = true
	var tween := exit_door.create_tween()
	tween.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	tween.tween_callback(func():
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	AudioManager.door()


func _on_exit_opened() -> void:
	pass


func _setup_lighting(ambient: Color, fog_col: Color, fog_density: float) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient
	e.ambient_light_energy = 0.7
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.03)
	e.fog_enabled = true
	e.fog_light_color = fog_col
	e.fog_density = fog_density
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
