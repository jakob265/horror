extends Node3D
# VESPER - ACT 6: COLD STORAGE / THE MORGUE
# Evasion-heavy. A dark maze of meat-locker racks. The crew - what's left of
# them - lurk the aisles (gone when you look, nearer when you turn back). A
# hunter guards the iced exit; burn a flare to thaw it. The drawers are open.

const WALL := Color(0.30, 0.34, 0.40)
const FLOOR := Color(0.34, 0.38, 0.44)
const CEIL := Color(0.12, 0.14, 0.17)
const RACK := Color(0.40, 0.44, 0.49)

var exit_door: Node3D = null
var ice: Node3D = null
var thawed := false


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_store()

	# A hunter prowls the open north strip in front of the exit.
	var stalker := HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, 0, -6.0), 0.0)
	stalker.set_stalk([Vector3(-4, 0, -6), Vector3(4, 0, -6), Vector3(4, 0, -3.5), Vector3(-4, 0, -3.5)], 1.1, 4.0)
	add_child(stalker)
	ShapeTracker.register(stalker)

	# The crew, lurking the rack maze.
	ActUtil.haunt(self, {
		"intensity": 0.5, "flicker": true, "flicker_rate": 0.7,
		"lurkers": [
			{"points": [Vector3(-6, 0, 5), Vector3(-3, 0, 2), Vector3(6, 0, 5), Vector3(3, 0, 2)], "kind": HorrorShape.KIND_YUNA, "creep": 0.55},
			{"points": [Vector3(6, 0, 6), Vector3(0, 0, 6), Vector3(-6, 0, 6), Vector3(3, 0, 4)], "kind": HorrorShape.KIND_FELIX, "creep": 0.5},
		],
	})

	# Pak's voice from the cold. "Don't trust a kind face down here."
	ActUtil.enable_lure(self, {
		"voice": "Pak",
		"calls": [
			{"call": "i can't find the others in the cold. say something so i know where you are.",
			 "answer": "oh. it's you. stay there. you're so cold."},
			{"call": "the drawers won't stay shut. help me close them. i can't do it alone.",
			 "answer": "i hear you breathing. good. keep breathing."},
			{"call": "your hands are shaking. it's just the cold. come closer to the light.",
			 "answer": "there. i see your lamp. i'm coming."},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 8.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if thawed and GameState.player and GameState.player.global_position.z < -8.6:
		SceneRouter.transition_to("act7")


func _build_store() -> void:
	Chamber.add_room(self, 18, 18, 3.4, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": -9.0, "gap": 0.0}, {"axis": "z", "fixed": 9.0, "gap": 0.0}])
	exit_door = Chamber.add_door(self, "z", -9 + 0.05, 0, "FREEZER", Color(0.30, 0.36, 0.42), Callable(), "", true)
	Chamber.invis_wall(self, "z", 9, 0)
	# Sheet of ice glazing the exit (burn the flare to thaw it).
	ice = Node3D.new()
	add_child(ice)
	var iceblock := MeshInstance3D.new()
	var ib := BoxMesh.new()
	ib.size = Vector3(1.5, 2.4, 0.25)
	iceblock.mesh = ib
	iceblock.position = Vector3(0, 1.2, -8.75)
	var im := StandardMaterial3D.new()
	im.albedo_color = Color(0.6, 0.78, 0.9, 0.45)
	im.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	im.roughness = 0.1
	im.emission_enabled = true
	im.emission = Color(0.4, 0.6, 0.75)
	im.emission_energy_multiplier = 0.15
	iceblock.material_override = im
	ice.add_child(iceblock)
	Interactable.attach(exit_door, "Thaw the ice", "use_item", {
		"required_item": "signal_flare", "consume": true,
		"on_use": Callable(self, "_thaw"),
		"locked_text": "The door's sealed under a foot of ice. You'd need fire.",
	})

	# Rack maze (south + centre): tall shelving in split rows, blocking sight.
	for rx in [-6.0, -3.0, 3.0, 6.0]:
		for seg in [[0.8, 3.2], [4.4, 7.6]]:
			var length: float = seg[1] - seg[0]
			var mid: float = (seg[0] + seg[1]) / 2.0
			Chamber.make_prop_box(self, Vector3(0.8, 2.1, length), Vector3(rx, 1.05, mid), RACK)
			# shelf contents
			for sy in [0.6, 1.3, 1.9]:
				Chamber.make_prop_box(self, Vector3(0.7, 0.05, length - 0.2), Vector3(rx, sy, mid), Color(0.34, 0.36, 0.40), false)
	# Morgue drawer bank along the west wall.
	for dy in [0.5, 1.1, 1.7]:
		for dz in range(-2, 4):
			var is_open: bool = (float(dy) < 0.6 and dz == 1)
			var dx: float = 0.35 if is_open else 0.0
			Chamber.make_prop_box(self, Vector3(0.25, 0.5, 0.85), Vector3(-8.6 + dx, float(dy), float(dz) - 1.0), Color(0.5, 0.54, 0.58), false)
	ActUtil.wall_label(self, "COLD STORE", Vector3(0, 2.7, 8.8), 24, Color(0.7, 0.86, 0.92))
	ActUtil.wall_label(self, "MORGUE", Vector3(-8.6, 2.4, 0.0), 16, Color(0.7, 0.82, 0.88))

	# Hanging carcasses in the north strip.
	for hx in [-3.0, 2.0, 5.0]:
		ActUtil.hanging_corpse(self, Vector3(hx, 3.3, -5.5), 1.7, Color(0.5, 0.5, 0.46))
	# The flare, mid-maze, on a shelf.
	_make_pickup(Vector3(1.5, 1.45, 5.8), Vector3(0.4, 0.1, 0.12), Color(0.85, 0.2, 0.12), "signal_flare", "Take the signal flare")
	# Hide spots, a body, blood, dread filament, the tally note.
	ActUtil.hide_locker(self, Vector3(8.5, 0, -1.0), 90.0)
	ActUtil.hide_locker(self, Vector3(-8.4, 0, 6.5), 90.0)
	ActUtil.corpse(self, Vector3(-1.5, 0, -7.0), 0.0, true, Color(0.30, 0.34, 0.40))
	ActUtil.blood_decal(self, Vector3(0.5, 0.02, -6.0), Vector2(1.8, 1.4))
	ActUtil.signal_growth(self, Vector3(8.5, 0, 6.5), 1.5, Color(0.08, 0.13, 0.12))
	ActUtil.wall_scrawl(self, "COLD IS WHERE IT'S FROM", Vector3(-4.0, 2.1, 8.85), 180.0, 26, Color(0.45, 0.06, 0.07))
	Interactable.make_note(self, Vector3(-8.2, 0.04, 3.0), "v_morgue", "Read the tally")


func _make_pickup(pos: Vector3, size: Vector3, color: Color, item_id: String, prompt: String) -> void:
	ActUtil.pickup(self, pos, size, color, item_id, prompt)


func _thaw() -> void:
	if thawed:
		return
	thawed = true
	if ice and is_instance_valid(ice):
		ice.queue_free()
	AudioManager.scrape()
	var t := exit_door.create_tween()
	t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	t.tween_callback(func() -> void:
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	InteractionManager.show_examine("The flare roars red. Ice sheets off the door in sheets and the freezer cracks open onto the shaft.", 4.5)
