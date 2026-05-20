extends Node3D
# ACT 6 - HYDROPONICS BAY.
# 16x16 greenhouse, 5 planter rows, side grow-racks, broken automation arm,
# Note 10 on centre trough, the lemon-tree cutting in a clay pot.

const W := 16.0
const D := 16.0
const H := 3.6


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.55, 0.74, 0.66), Color(0.10, 0.16, 0.16), 0.018, 0.65)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.33, 0.39, 0.33), Color(0.14, 0.20, 0.18))
	var wall := Color(0.24, 0.31, 0.27)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "LAB", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "ENGINEERING", Color(0.28, 0.27, 0.23),
		func(): GameState.hydro_door_open = true, "Open ENGINEERING")

	# Five planter rows
	var row_labels := [
		"tomatoes,  pinch tops 2x/wk",
		"lettuce,  cut outer leaves",
		"beans,  Felix will steal them",
		"herbs,  yes the basil too,  thx",
		"strawberries,  Amara's request",
	]
	var rxs := [-5.0, -2.5, 0.0, 2.5, 5.0]
	for i in rxs.size():
		_build_planter_row(rxs[i], 12.0, 10, row_labels[i])

	# UV grow-lamp strips on ceiling
	for tz in [-6, -3, 0, 3, 6]:
		for tx in [-4, 0, 4]:
			var strip := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(2.6, 0.06, 0.3)
			strip.mesh = sb
			strip.position = Vector3(tx, H - 0.15, tz)
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(0.55, 0.78, 1.0)
			sm.emission_enabled = true
			sm.emission = Color(0.55, 0.78, 1.0)
			sm.emission_energy_multiplier = 1.5
			strip.material_override = sm
			add_child(strip)

	# Side wall grow-racks
	for rz in [-5, 0, 5]:
		_build_grow_rack(-W/2 + 0.30, rz)
		_build_grow_rack(W/2 - 0.30, rz)

	# Sink / wash station (SE corner)
	var sink := Chamber.make_prop_box(self, Vector3(1.8, 0.90, 0.9), Vector3(W/2 - 1.4, 0.45, -D/2 + 1.2), Color(0.55, 0.57, 0.61))
	Chamber.make_prop_box(self, Vector3(1.7, 0.10, 0.80), Vector3(W/2 - 1.4, 0.95, -D/2 + 1.2), Color(0.23, 0.29, 0.37), false)
	Chamber.make_prop_box(self, Vector3(0.08, 0.32, 0.08), Vector3(W/2 - 1.4, 1.16, -D/2 + 1.0), Color(0.70, 0.74, 0.78), false)
	# Watering can
	Chamber.make_prop_box(self, Vector3(0.35, 0.35, 0.30), Vector3(W/2 - 0.9, 1.10, -D/2 + 1.2), Color(0.43, 0.70, 0.43))
	Interactable.attach(sink, "Look at the wash station", "examine_only", {
		"text": "The sink is dry.  The water line above it is intact.  The watering can sits on the counter.  Yuna's handwriting on the lip:  'fill morning AND evening.  the plants drink more than you think.'",
		"duration": 5.0,
	})

	# Propagation table (SW corner)
	var prop_table := Chamber.make_prop_box(self, Vector3(3.0, 0.80, 1.4), Vector3(-W/2 + 2.0, 0.40, -D/2 + 1.6), Color(0.29, 0.25, 0.22))
	for px in [-0.8, 0.0, 0.8]:
		# Pot
		Chamber.make_prop_box(self, Vector3(0.20, 0.18, 0.20), Vector3(-W/2 + 2.0 + px, 0.90, -D/2 + 1.6), Color(0.62, 0.51, 0.39), false)
		# Cutting
		Chamber.make_prop_box(self, Vector3(0.04, 0.40, 0.04), Vector3(-W/2 + 2.0 + px, 1.18, -D/2 + 1.6), Color(0.31, 0.43, 0.29), false)
		# Glass dome
		var dome := MeshInstance3D.new()
		var dm := SphereMesh.new()
		dm.radius = 0.20
		dm.height = 0.55
		dome.mesh = dm
		dome.position = Vector3(-W/2 + 2.0 + px, 1.10, -D/2 + 1.6)
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = Color(0.86, 0.90, 0.94, 0.35)
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dome.material_override = dmat
		add_child(dome)
	Interactable.attach(prop_table, "Look at the cuttings", "examine_only", {
		"text": "Three cuttings under glass domes.  All labeled in Yuna's handwriting.  Left: 'rosemary - for Hargrove who pretends he doesn't like it.'  Centre: 'mint - for Mara's tea.'  Right: 'a flower whose name I keep meaning to ask her - she calls it the orange one.'",
		"duration": 8.0,
	})

	# Broken automation arm
	var arm_base := Chamber.make_prop_box(self, Vector3(0.30, 0.30, 0.30), Vector3(0, H - 0.15, 0), Color(0.31, 0.35, 0.39))
	Interactable.attach(arm_base, "Look at the harvest arm", "examine_only", {
		"text": "Maintenance arm SAF-7.  It hangs slack in the middle of its arc, frozen mid-motion.  A red fault light blinks at its base.  The error code on the wrist screen is 442-K.  Same as the array.",
		"duration": 6.0,
	})
	# Arm links
	var link1 := MeshInstance3D.new()
	var lm1 := BoxMesh.new()
	lm1.size = Vector3(0.15, 1.4, 0.15)
	link1.mesh = lm1
	link1.position = Vector3(0, H - 0.85, 0)
	link1.rotation_degrees = Vector3(0, 0, 35)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.55, 0.59, 0.63)
	link1.material_override = lmat
	add_child(link1)

	# Note 10
	Interactable.make_note(self, Vector3(0, 0.45, -3.0), "note_10", "Read hydroponics journal")

	# Lemon-tree cutting in clay pot
	var pot := Chamber.make_prop_box(self, Vector3(0.32, 0.32, 0.32), Vector3(5.5, 0.55, -6.0), Color(0.62, 0.51, 0.39))
	# Stem
	Chamber.make_prop_box(self, Vector3(0.10, 1.4, 0.10), Vector3(5.5, 1.50, -6.0), Color(0.31, 0.23, 0.20), false)
	# Foliage
	var leaf := MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.30
	ls.height = 0.6
	leaf.mesh = ls
	leaf.position = Vector3(5.5, 2.20, -6.0)
	var leafmat := StandardMaterial3D.new()
	leafmat.albedo_color = Color(0.27, 0.43, 0.27)
	leaf.material_override = leafmat
	add_child(leaf)
	Interactable.attach(pot, "Look at the pot", "examine_only", {
		"text": "A clay pot with a young lemon-tree cutting.  A tag in Yuna's handwriting reads 'home'.  She drew a sun with a face on the tag.",
		"duration": 5.0,
	})

	# Tool wall
	var tool_wall := Chamber.make_prop_box(self, Vector3(0.06, 1.8, 2.4), Vector3(W/2 - 0.10, 1.6, -D/2 + 4.0), Color(0.33, 0.31, 0.27))
	Interactable.attach(tool_wall, "Look at the tool wall", "examine_only", {
		"text": "Yuna's tool wall.  Trowel, shears, gloves still warm from the last time she used them.  Hanging on the nail at the end is a single sneaker, which makes no sense and is unmistakably hers.",
		"duration": 5.0,
	})

	# Bench with logbook (NW corner)
	Chamber.make_prop_box(self, Vector3(2.0, 0.5, 0.6), Vector3(-W/2 + 2.0, 0.25, D/2 - 1.0), Color(0.31, 0.27, 0.23))
	var logbook := Chamber.make_prop_box(self, Vector3(0.30, 0.06, 0.40), Vector3(-W/2 + 2.0, 0.53, D/2 - 1.0), Color(0.39, 0.31, 0.23))
	Interactable.attach(logbook, "Flip through the logbook", "examine_only", {
		"text": "Yuna's logbook.  The most recent entries:\n\n  day 71 -  beans:  yield down 30%.  cause unknown.\n  day 72 -  beans:  yield down 50%.  same.\n  day 73 -  every plant is hearing the\n            same thing i am.  i think we\n            are all the bean now.\n  day 74 -  (no entry)",
		"duration": 10.0,
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _build_planter_row(x: float, length: float, plant_count: int, tag_text: String) -> void:
	var trough := Chamber.make_prop_box(self, Vector3(1.1, 0.40, length), Vector3(x, 0.20, 0), Color(0.16, 0.20, 0.24))
	# Soil
	Chamber.make_prop_box(self, Vector3(0.95, 0.10, length - 0.15), Vector3(x, 0.42, 0), Color(0.14, 0.11, 0.09), false)
	# Plants
	var half: float = (length - 1.0) / 2.0
	var step: float = (length - 1.0) / float(maxi(plant_count - 1, 1))
	for i in plant_count:
		var t: float = -half + i * step
		var stem := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.05, 0.70, 0.05)
		stem.mesh = sm
		stem.position = Vector3(x, 0.75, t)
		var stem_mat := StandardMaterial3D.new()
		stem_mat.albedo_color = Color(0.27, 0.35, 0.24)
		stem.material_override = stem_mat
		add_child(stem)
		# Leaf
		var leaf := MeshInstance3D.new()
		var lsm := SphereMesh.new()
		lsm.radius = 0.12
		lsm.height = 0.20
		leaf.mesh = lsm
		leaf.position = Vector3(x, 1.10, t)
		leaf.scale = Vector3(2.4, 0.7, 1.6)
		if i % 3 == 1:
			leaf.rotation_degrees = Vector3(0, 0, 25)
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.22, 0.35, 0.22)
		leaf.material_override = leaf_mat
		add_child(leaf)
	# Tag
	var tag := Label3D.new()
	tag.text = tag_text
	tag.position = Vector3(x, 0.65, -length / 2 + 0.2)
	tag.font_size = 14
	tag.modulate = Color(0.16, 0.12, 0.09)
	add_child(tag)


func _build_grow_rack(x: float, z: float) -> void:
	var h_levels := 3
	var rack := Chamber.make_prop_box(self, Vector3(0.30, h_levels * 0.70, 2.2), Vector3(x, h_levels * 0.35, z), Color(0.31, 0.35, 0.39))
	for level in h_levels:
		var ty := 0.20 + level * 0.70
		Chamber.make_prop_box(self, Vector3(0.60, 0.06, 1.8), Vector3(x + (0.3 if x < 0 else -0.3), ty, z), Color(0.27, 0.23, 0.20), false)
		# Tiny seedlings
		for sz in [-0.6, -0.2, 0.2, 0.6]:
			var stem := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.05, 0.30, 0.05)
			stem.mesh = sm
			stem.position = Vector3(x + (0.3 if x < 0 else -0.3), ty + 0.15, z + sz)
			var stmat := StandardMaterial3D.new()
			stmat.albedo_color = Color(0.39, 0.51, 0.31)
			stem.material_override = stmat
			add_child(stem)
		# UV strip
		var strip := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.60, 0.04, 1.8)
		strip.mesh = b
		strip.position = Vector3(x + (0.3 if x < 0 else -0.3), ty + 0.30, z)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.55, 0.78, 1.0)
		smat.emission_enabled = true
		smat.emission = Color(0.55, 0.78, 1.0)
		smat.emission_energy_multiplier = 1.0
		strip.material_override = smat
		add_child(strip)


func _process(_dt: float) -> void:
	if GameState.hydro_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act7")
