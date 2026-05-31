extends Node3D
# VESPER - ACT 2: THE DORMITORY WING
# Bunkroom -> corridor -> crew quarters. The hunter patrols the corridor spine;
# kill your lamp and duck into a locker to break its line of sight. Find the
# dorm key in the quarters to unlock the door north. Introduces stalker + hiding.

const WALL := Color(0.30, 0.33, 0.38)
const FLOOR := Color(0.34, 0.36, 0.40)
const CEIL := Color(0.13, 0.14, 0.17)
const FRAME := Color(0.30, 0.32, 0.36)

var exit_door: Node3D = null
var unlocked := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.13, 0.020)

	_build_bunkroom()
	_build_corridor()
	_build_washroom()
	_build_quarters()

	# The hunter patrols the corridor spine and detours into the washroom.
	var stalker := HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, 0, -9.0), 0.0)
	stalker.set_stalk([
		Vector3(0, 0, -3.0),
		Vector3(0, 0, -9.0),
		Vector3(-6.5, 0, -9.0),
		Vector3(0, 0, -9.0),
		Vector3(0, 0, -13.0),
	], 1.0, 3.4)
	add_child(stalker)
	ShapeTracker.register(stalker)

	ActUtil.haunt(self, {"intensity": 0.32, "flicker": true, "flicker_rate": 1.1})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 9.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if unlocked and GameState.player and GameState.player.global_position.z < -22.5:
		SceneRouter.transition_to("act3")


# --- Bunkroom (south, entry) ---------------------------------------------

func _build_bunkroom() -> void:
	Chamber.add_room(self, 12, 10, 3.2, FLOOR, CEIL, WALL, Vector3(0, 0, 6), {},
		[{"axis": "z", "fixed": 1.0, "gap": 0.0}])
	# Bunks along the west wall; one occupied.
	_bunk(Vector3(-5.0, 0, 3.2), 0.0, true)
	_bunk(Vector3(-5.0, 0, 6.4), 0.0, false)
	_bunk(Vector3(-5.0, 0, 9.4), 0.0, false)
	_bunk(Vector3(5.0, 0, 9.2), 0.0, false)
	# Hide lockers (east wall).
	ActUtil.hide_locker(self, Vector3(5.5, 0, 3.0), -90.0)
	ActUtil.hide_locker(self, Vector3(5.5, 0, 4.7), -90.0)
	# Footlockers + a central table with effects.
	for fz in [3.2, 6.4]:
		Chamber.make_prop_box(self, Vector3(0.9, 0.4, 0.5), Vector3(-3.7, 0.2, fz), Color(0.28, 0.25, 0.18))
	Chamber.make_prop_box(self, Vector3(1.6, 0.1, 0.9), Vector3(0.5, 0.75, 5.5), Color(0.30, 0.27, 0.22))
	for tlx in [-0.2, 1.2]:
		for tlz in [5.15, 5.85]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.75, 0.08), Vector3(tlx, 0.37, tlz), Color(0.2, 0.18, 0.15), false)
	Chamber.make_chair(self, Vector3(0.5, 0, 4.4), Color(0.30, 0.31, 0.34), 0.0)
	# Mugs / clutter on the table.
	Chamber.make_prop_box(self, Vector3(0.12, 0.14, 0.12), Vector3(0.2, 0.87, 5.4), Color(0.7, 0.7, 0.72), false)
	Chamber.make_prop_box(self, Vector3(0.3, 0.02, 0.4), Vector3(0.9, 0.81, 5.6), Color(0.85, 0.85, 0.82), false)
	# Wall pipes + sign.
	for wz in [3.0, 7.0]:
		Chamber.make_prop_box(self, Vector3(0.14, 3.0, 0.14), Vector3(-5.85, 1.5, wz), Color(0.30, 0.33, 0.36), false)
	ActUtil.wall_label(self, "BUNKS A-F", Vector3(0, 2.7, 10.8), 22, Color(0.78, 0.84, 0.6))
	# Note + a body + blood.
	Interactable.make_note(self, Vector3(-3.55, 0.62, 3.2), "v_bunk", "Read the diary")
	# Grocery list pinned to a corkboard - not anyone you know. WALTER WALTER WALTER.
	Interactable.make_note(self, Vector3(4.6, 1.5, 1.05), "note_15", "Read the bulletin")
	ActUtil.corpse(self, Vector3(3.4, 0, 5.2), 40.0, true, Color(0.20, 0.24, 0.28))
	ActUtil.blood_decal(self, Vector3(2.6, 0.02, 6.2), Vector2(1.4, 1.0))
	ActUtil.blood_wall(self, Vector3(5.9, 1.4, 7.0), Vector2(1.2, 1.6), -90.0)


func _bunk(pos: Vector3, yaw: float, occupied: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	add_child(root)
	var mat := Color(0.58, 0.58, 0.62)
	for px in [-0.45, 0.45]:
		for pz in [-0.95, 0.95]:
			Chamber.make_prop_box(root, Vector3(0.08, 1.7, 0.08), Vector3(px, 0.85, pz), FRAME, false)
	Chamber.make_prop_box(root, Vector3(1.0, 0.08, 2.0), Vector3(0, 0.5, 0), FRAME, true, "bunk")
	Chamber.make_prop_box(root, Vector3(1.0, 0.08, 2.0), Vector3(0, 1.4, 0), FRAME, true, "bunk")
	Chamber.make_prop_box(root, Vector3(0.92, 0.14, 1.9), Vector3(0, 0.6, 0), mat, false)
	Chamber.make_prop_box(root, Vector3(0.92, 0.14, 1.9), Vector3(0, 1.5, 0), mat, false)
	for my in [0.72, 1.62]:
		Chamber.make_prop_box(root, Vector3(0.5, 0.12, 0.3), Vector3(0, my, -0.75), Color(0.80, 0.80, 0.82), false)
	if occupied:
		Chamber.make_prop_box(root, Vector3(0.72, 0.3, 1.5), Vector3(0, 0.74, 0.12), Color(0.28, 0.20, 0.22), false)
		ActUtil.blood_decal(root, Vector3(0, 0.70, 0.62), Vector2(0.6, 0.8), "up")


# --- Corridor (the hunter's spine) ---------------------------------------

func _build_corridor() -> void:
	Chamber.add_floor_ceiling(self, 4, 16, 3.2, FLOOR, CEIL, Vector3(0, 0, -7))
	# West wall has a doorway at z=-9 into the washroom annex; east wall solid.
	Chamber.add_wall(self, "x", -2, -15, 1, 3.2, WALL, -9.0)
	Chamber.add_wall(self, "x", 2, -15, 1, 3.2, WALL)
	# Hide lockers recessed along the run (kill your lamp, then duck in).
	ActUtil.hide_locker(self, Vector3(1.55, 0, -5.0), -90.0)
	ActUtil.hide_locker(self, Vector3(-1.55, 0, -10.5), 90.0)
	# Vertical conduits + a low pipe run.
	for wz in [-2.5, -6.5, -10.5, -13.5]:
		Chamber.make_prop_box(self, Vector3(0.12, 3.0, 0.12), Vector3(-1.9, 1.5, wz), Color(0.30, 0.33, 0.36), false)
		Chamber.make_prop_box(self, Vector3(0.12, 3.0, 0.12), Vector3(1.9, 1.5, wz), Color(0.30, 0.33, 0.36), false)
	Chamber.make_prop_box(self, Vector3(0.16, 0.16, 15.0), Vector3(-1.86, 2.8, -7), Color(0.42, 0.30, 0.18), false)
	Chamber.make_prop_box(self, Vector3(0.16, 0.16, 15.0), Vector3(1.86, 0.5, -7), Color(0.30, 0.33, 0.36), false)
	# A tipped gurney + a dragged body + the blood that came with it.
	var g := Chamber.make_prop_box(self, Vector3(0.7, 0.1, 1.9), Vector3(0.9, 0.62, -12.0), Color(0.70, 0.72, 0.75))
	g.rotation_degrees = Vector3(8, 0, 0)
	for glx in [0.6, 1.2]:
		Chamber.make_prop_box(self, Vector3(0.05, 0.6, 0.05), Vector3(glx, 0.3, -12.6), Color(0.5, 0.5, 0.55), false)
	ActUtil.corpse(self, Vector3(-0.6, 0, -6.5), 75.0, true, Color(0.18, 0.20, 0.24))
	for i in 6:
		var t: float = i / 5.0
		ActUtil.blood_decal(self, Vector3(lerpf(-0.5, 0.7, t), 0.02, lerpf(-7.0, -11.5, t)),
			Vector2(0.5, 0.9), "up", Color(0.18, 0.03, 0.03, 0.7))
	ActUtil.wall_scrawl(self, "LAMP OFF PAST HERE", Vector3(1.4, 1.9, 0.2), -90.0, 18, Color(0.5, 0.06, 0.07))
	ActUtil.wall_label(self, "<- CABINS", Vector3(0, 2.6, 0.4), 16, Color(0.7, 0.84, 0.9))
	ActUtil.wall_label(self, "QUARTERS ->", Vector3(0, 2.6, -14.4), 16, Color(0.7, 0.84, 0.9))


# --- Washroom annex (west off the corridor, a dead-end pocket) ------------
# Branches west through the corridor's z=-9 doorway. Shares the corridor's
# x=-2 wall (already cut with the gap), so we add only the other three walls.
# A dead end: it deepens the patrol sweep and gives one more place to duck.

func _build_washroom() -> void:
	var floor_c := Color(0.32, 0.34, 0.38)
	var ceil_c := Color(0.12, 0.13, 0.16)
	# Room spans x -9..-2, z -12..-6 (centre -5.5, -9).
	Chamber.add_floor_ceiling(self, 7, 6, 3.0, floor_c, ceil_c, Vector3(-5.5, 0, -9))
	Chamber.add_wall(self, "x", -9, -12, -6, 3.0, WALL)          # far west
	Chamber.add_wall(self, "z", -12, -9, -2, 3.0, WALL)          # south
	Chamber.add_wall(self, "z", -6, -9, -2, 3.0, WALL)           # north

	# Sink trough + mirrors (a row of basins along the west wall).
	Chamber.make_prop_box(self, Vector3(0.5, 0.25, 4.0), Vector3(-8.5, 0.85, -9.0), Color(0.50, 0.52, 0.56))
	for mz in [-10.5, -9.0, -7.5]:
		Chamber.make_prop_box(self, Vector3(0.05, 0.7, 0.6), Vector3(-8.7, 1.6, mz), Color(0.16, 0.18, 0.22), false)
	# Toilet stalls (low dividers) along the south.
	for sx in [-6.6, -4.4]:
		Chamber.make_prop_box(self, Vector3(0.08, 1.4, 1.6), Vector3(sx, 0.7, -11.2), Color(0.40, 0.42, 0.45), false)
		Chamber.make_prop_box(self, Vector3(0.5, 0.5, 0.5), Vector3(sx + 0.7, 0.25, -11.4), Color(0.60, 0.62, 0.64))
	# A hide spot in the far corner; the patrol now reaches in here.
	ActUtil.hide_locker(self, Vector3(-8.4, 0, -6.8), 0.0)
	# Horror: a body slumped at the basins, water-thinned blood, a scrawl.
	ActUtil.corpse(self, Vector3(-6.0, 0, -8.4), 50.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_decal(self, Vector3(-7.0, 0.02, -9.0), Vector2(2.0, 1.4), "up", Color(0.20, 0.04, 0.05, 0.55))
	ActUtil.blood_wall(self, Vector3(-8.85, 1.5, -10.5), Vector2(1.0, 1.4), -90.0)
	ActUtil.wall_scrawl(self, "WASHED MY HANDS RAW", Vector3(-8.8, 2.0, -7.6), -90.0, 16, Color(0.5, 0.06, 0.07))
	ActUtil.wall_label(self, "WASHROOM", Vector3(-5.5, 2.6, -6.2), 15, Color(0.7, 0.84, 0.9))
	Interactable.make_examine(self, Vector3(-8.5, 1.05, -7.5), Vector3(0.3, 0.05, 0.4),
		"Read the smeared note",
		"A page swollen with damp, stuck to the basin: 'it isn't on the skin. " +
		"i scrubbed til it bled and the sound is still under there. under everyone.'", 6.0)


# --- Crew quarters (north, the key + exit) -------------------------------

func _build_quarters() -> void:
	Chamber.add_room(self, 12, 8, 3.2, FLOOR, CEIL, WALL, Vector3(0, 0, -19), {},
		[{"axis": "z", "fixed": -15.0, "gap": 0.0}, {"axis": "z", "fixed": -23.0, "gap": 0.0}])
	exit_door = Chamber.add_door(self, "z", -23 + 0.05, 0, "WING DOOR", Color(0.26, 0.30, 0.36))
	exit_door.set_meta("interact", {
		"label": "Unlock the door", "kind": "use_item", "required_item": "dorm_key", "consume": false,
		"on_use": Callable(self, "_open_exit"),
		"locked_text": "Locked from the far side. A key slot blinks - find the dorm key.",
	})
	# Desk with the key + the lockdown log.
	Chamber.make_prop_box(self, Vector3(1.9, 0.1, 0.95), Vector3(-4.0, 0.9, -20.0), Color(0.30, 0.27, 0.22))
	for dlx in [-4.8, -3.2]:
		for dlz in [-20.4, -19.6]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.9, 0.08), Vector3(dlx, 0.45, dlz), Color(0.2, 0.18, 0.15), false)
	Chamber.make_chair(self, Vector3(-4.0, 0, -19.1), Color(0.30, 0.31, 0.34), 180.0)
	_make_key(Vector3(-4.2, 0.99, -20.0))
	Interactable.make_note(self, Vector3(-3.5, 0.98, -20.2), "v_quarters", "Read the log")
	# A taped note that doesn't belong here. The handwriting isn't Vesper's.
	Interactable.make_note(self, Vector3(5.0, 1.55, -22.85), "note_3", "Read the taped note")
	# Dead radio console along the east wall.
	Chamber.make_prop_box(self, Vector3(1.6, 1.0, 0.7), Vector3(4.6, 0.5, -18.5), Color(0.22, 0.24, 0.28))
	Chamber.make_prop_box(self, Vector3(1.4, 0.5, 0.1), Vector3(4.6, 1.2, -18.2), Color(0.10, 0.12, 0.16), false)
	ActUtil.wall_label(self, "NO CARRIER", Vector3(4.4, 1.55, -18.0), 13, Color(0.45, 0.55, 0.60))
	# Filing cabinets + scattered files.
	for cz in [-21.5, -20.6]:
		Chamber.make_prop_box(self, Vector3(0.7, 1.3, 0.6), Vector3(5.2, 0.65, cz), Color(0.26, 0.28, 0.31))
	for k in 4:
		Chamber.make_prop_box(self, Vector3(0.3, 0.02, 0.4), Vector3(-1.0 + k * 0.4, 0.02, -21.0), Color(0.85, 0.85, 0.8), false)
	# A body slumped against the far wall + spatter.
	ActUtil.corpse(self, Vector3(3.2, 0, -21.6), 200.0, true, Color(0.20, 0.22, 0.26))
	ActUtil.blood_wall(self, Vector3(0.0, 1.4, -22.85), Vector2(2.2, 1.7), 0.0)
	ActUtil.wall_label(self, "COMMS / ADMIN", Vector3(0, 2.7, -22.7), 18, Color(0.78, 0.84, 0.6))


func _make_key(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.05, 0.10)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.78, 0.42)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.6, 0.25)
	mat.emission_energy_multiplier = 0.35
	mat.metallic = 0.7
	mat.roughness = 0.4
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(0.22, 0.05, 0.10)
	shape.shape = col
	body.add_child(shape)
	add_child(body)
	Interactable.attach(body, "Take the dorm key", "collect_item", {"item_id": "dorm_key"})


func _open_exit() -> void:
	if unlocked:
		return
	unlocked = true
	var t := exit_door.create_tween()
	t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	t.tween_callback(func() -> void:
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	AudioManager.door()
	InteractionManager.show_examine("The lock gives. The wing opens onto the mess.", 4.0)
