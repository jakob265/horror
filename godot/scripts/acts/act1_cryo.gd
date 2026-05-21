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
	ActUtil.light_rig_act1(self)
	ActUtil.add_dust_motes(self, Vector3(0, 1.6, 0), Vector3(6, 1.8, 8), 90,
		Color(1.0, 0.62, 0.55, 0.18))

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

	# Extra floor clutter to bring the bay alive
	# Pile of medical supplies near east wall
	Chamber.make_prop_box(self, Vector3(0.6, 0.4, 0.5), Vector3(5.0, 0.20, 1.5), Color(0.78, 0.78, 0.82))
	Chamber.make_prop_box(self, Vector3(0.55, 0.06, 0.45), Vector3(5.0, 0.42, 1.5), Color(0.86, 0.16, 0.16), false)
	# Toppled IV stand
	Chamber.make_prop_box(self, Vector3(0.45, 0.08, 1.4), Vector3(2.0, 0.05, 3.5), Color(0.55, 0.55, 0.59), false)
	# Vital monitor cart in the corner
	Chamber.make_prop_box(self, Vector3(0.45, 0.95, 0.45), Vector3(-4.8, 0.47, -1.8), Color(0.20, 0.22, 0.27))
	Chamber.make_prop_box(self, Vector3(0.40, 0.30, 0.06), Vector3(-4.8, 1.10, -2.0), Color(0.04, 0.16, 0.18), false)
	var vitscr := MeshInstance3D.new()
	var vsq := QuadMesh.new()
	vsq.size = Vector2(0.34, 0.24)
	vitscr.mesh = vsq
	vitscr.position = Vector3(-4.8, 1.10, -2.04)
	vitscr.rotation_degrees = Vector3(0, 180, 0)
	var vsmat := StandardMaterial3D.new()
	vsmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	vsmat.albedo_color = Color(0.04, 0.10, 0.16)
	vsmat.emission_enabled = true
	vsmat.emission = Color(0.22, 0.86, 0.32)
	vsmat.emission_energy_multiplier = 0.6
	vitscr.material_override = vsmat
	add_child(vitscr)
	# Scattered cables
	for cz in [-3.5, -0.5, 3.5]:
		Chamber.make_prop_box(self, Vector3(0.06, 0.04, 1.4), Vector3(-3.0, 0.04, cz), Color(0.14, 0.14, 0.16), false)
	# Wall-mounted defibrillator on east wall
	Chamber.make_prop_box(self, Vector3(0.06, 0.40, 0.36), Vector3(5.92, 1.55, -2.0), Color(0.86, 0.55, 0.16), false)
	# Floor decal warning stripe
	for dz in [-6, 6]:
		for dx in [-3, -1, 1, 3]:
			Chamber.make_prop_box(self, Vector3(0.40, 0.02, 0.18), Vector3(dx, 0.02, dz), Color(0.86, 0.70, 0.12, 0.7), false)
	# Hanging cable bundle from ceiling
	Chamber.make_prop_box(self, Vector3(0.10, 1.2, 0.10), Vector3(0, 3.0, 0.5), Color(0.16, 0.16, 0.20), false)

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
	# Base side panel - cabling channel
	Chamber.make_prop_box(self, Vector3(0.86, 0.16, 2.20), pos + Vector3(0, 0.32, 0), Color(0.12, 0.12, 0.14), false)
	# Tubing along both sides
	for sx in [-0.55, 0.55]:
		Chamber.make_prop_box(self, Vector3(0.08, 0.08, 2.20), pos + Vector3(sx, 0.55, 0), Color(0.62, 0.31, 0.22), false)
		Chamber.make_prop_box(self, Vector3(0.08, 0.08, 2.20), pos + Vector3(sx, 0.72, 0), Color(0.31, 0.43, 0.62), false)
	# Frost rim around the lid edge
	for fz in [-1.10, 1.10]:
		Chamber.make_prop_box(self, Vector3(0.90, 0.04, 0.06), pos + Vector3(0, 1.50, fz), Color(0.78, 0.86, 0.94), false)
	# Status LEDs at the head end
	var led_palette: Array[Color] = [Color(0.86, 0.18, 0.18), Color(0.86, 0.62, 0.16), Color(0.18, 0.86, 0.32)]
	for li in 3:
		var led_col: Color = led_palette[li]
		var led := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.06, 0.06, 0.02)
		led.mesh = lb
		led.position = pos + Vector3(-0.30 + li * 0.10, 0.62, -1.21)
		var lm := StandardMaterial3D.new()
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		lm.albedo_color = led_col
		lm.emission_enabled = true
		lm.emission = led_col
		lm.emission_energy_multiplier = 0.9
		led.material_override = lm
		add_child(led)
	# Small head-end readout screen
	var rs := MeshInstance3D.new()
	var rsb := BoxMesh.new()
	rsb.size = Vector3(0.34, 0.18, 0.02)
	rs.mesh = rsb
	rs.position = pos + Vector3(0, 0.90, -1.215)
	var rsm := StandardMaterial3D.new()
	rsm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	rsm.albedo_color = Color(0.04, 0.10, 0.20)
	rsm.emission_enabled = true
	rsm.emission = Color(0.22, 0.45, 0.86)
	rsm.emission_energy_multiplier = 0.6
	rs.material_override = rsm
	add_child(rs)
	# Pod name plate on the side
	ActUtil.wall_label(self, "V-0" + str(int((pos.x + 4.4) / 2.2) + 1), pos + Vector3(0, 1.10, 1.25), 12,
		Color(0.92, 0.95, 1.0), Color(0, 0, 0, 0.7))
	# Lid
	if welded:
		Chamber.make_prop_box(self, Vector3(0.85, 0.10, 2.30), pos + Vector3(0, 1.6, 0), Color(0.16, 0.16, 0.18))
		# Crude weld beads along the lid seam
		for wz in [-0.80, -0.30, 0.20, 0.70]:
			Chamber.make_prop_box(self, Vector3(0.92, 0.04, 0.10), pos + Vector3(0, 1.55, wz), Color(0.31, 0.20, 0.16), false)
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
		# Glass canopy (inside the open lid)
		var glass := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.70, 0.10, 2.10)
		glass.mesh = gb
		glass.position = pos + Vector3(0, 1.52, 0)
		var gmat := StandardMaterial3D.new()
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		gmat.albedo_color = Color(0.55, 0.78, 0.95, 0.35)
		gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gmat.emission_enabled = true
		gmat.emission = Color(0.55, 0.78, 0.95)
		gmat.emission_energy_multiplier = 0.15
		gmat.metallic = 0.0
		gmat.roughness = 0.05
		glass.material_override = gmat
		add_child(glass)
		# Open lid tilted up
		var lid := Chamber.make_prop_box(self, Vector3(0.85, 0.10, 2.30), pos + Vector3(0, 1.8, -0.6), Color(0.23, 0.27, 0.33))
		lid.rotation_degrees = Vector3(-25, 0, 0)
		# Lid hinge mount at the head end
		Chamber.make_prop_box(self, Vector3(0.80, 0.10, 0.10), pos + Vector3(0, 1.55, 1.15), Color(0.16, 0.16, 0.20), false)


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
