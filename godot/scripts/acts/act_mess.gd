extends Node3D
# ACT - CREW MESS HALL.
# Communal table, last shared meal still set, Felix's chair tipped, Notes 15 + 16.

const W := 16.0
const D := 14.0
const H := 3.4


func _ready() -> void:
	ActUtil.light_rig_act2(self)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.55, 0.49, 0.43), Color(0.18, 0.16, 0.14))
	var wall := Color(0.47, 0.39, 0.33)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "LOUNGE", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "LAB", Color(0.28, 0.27, 0.23),
		func(): GameState.mess_door_open = true, "Open LAB")

	# Communal table down the middle — wider + longer than before
	var table_y := 0.82
	# Trestle legs
	for tz in [-4.2, 0.0, 4.2]:
		Chamber.make_prop_box(self, Vector3(2.6, 0.72, 0.12), Vector3(0, 0.36, tz), Color(0.27, 0.20, 0.14))
	# Table top (wider 2.8 x deeper 9.6, no floating)
	Chamber.make_prop_box(self, Vector3(2.8, 0.10, 9.6), Vector3(0, 0.82, 0), Color(0.47, 0.36, 0.27))
	# Table edge trim
	for ex in [-1.42, 1.42]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.06, 9.6), Vector3(ex, 0.85, 0), Color(0.36, 0.27, 0.20), false)

	# 5 place settings alternating sides — wider spacing thanks to bigger table
	_place_setting(-0.80, -3.8, table_y, Color(0.86, 0.84, 0.80), Color(0.70, 0.39, 0.23), Color(0.47, 0.35, 0.27), false, "VOSS")
	_place_setting(0.80, -1.9, table_y, Color(0.86, 0.84, 0.80), Color.TRANSPARENT, Color(0.62, 0.23, 0.20), true, "OKAFOR")
	_place_setting(-0.80, 0.0, table_y, Color(0.86, 0.84, 0.80), Color(0.47, 0.55, 0.31), Color(0.31, 0.43, 0.51), false, "PARK")
	_place_setting(0.80, 1.9, table_y, Color(0.86, 0.84, 0.80), Color(0.70, 0.39, 0.23), Color(0.16, 0.23, 0.31), false, "HARGROVE")
	_place_setting(-0.80, 3.8, table_y, Color(0.86, 0.84, 0.80), Color(0.59, 0.47, 0.27), Color(0.70, 0.59, 0.39), false, "SATO")

	# Centerpiece: bread basket + salt/pepper shakers
	Chamber.make_prop_box(self, Vector3(0.50, 0.16, 0.36), Vector3(0, 0.94, 0), Color(0.55, 0.42, 0.27), false)
	Chamber.make_prop_box(self, Vector3(0.40, 0.10, 0.30), Vector3(0, 1.02, 0), Color(0.86, 0.70, 0.42), false)
	Chamber.make_prop_box(self, Vector3(0.08, 0.16, 0.08), Vector3(0.4, 0.95, 1.0), Color(0.94, 0.92, 0.86), false)
	Chamber.make_prop_box(self, Vector3(0.08, 0.16, 0.08), Vector3(0.5, 0.95, 1.0), Color(0.12, 0.12, 0.14), false)

	# Felix's chair tipped over
	var fell_chair := Chamber.make_prop_box(self, Vector3(0.45, 0.95, 0.45), Vector3(2.0, 0.10, -1.9), Color(0.33, 0.27, 0.23))
	fell_chair.rotation_degrees = Vector3(0, 0, 90)
	Interactable.attach(fell_chair, "Look at the fallen chair", "examine_only", {
		"text": "Felix's chair is tipped over on the floor.  His mug is on its side on the table, brown ring soaked into the wood.  His plate is empty - either he didn't eat or someone cleared it before he got here.  Knowing Felix it was the second one.",
		"duration": 6.0,
	})

	# Upright chairs at the four other settings — match wider seating spacing
	for cfg in [[-1.8, -3.8], [-1.8, 0.0], [1.8, 1.9], [-1.8, 3.8]]:
		var cx: float = cfg[0]
		var cz: float = cfg[1]
		Chamber.make_prop_box(self, Vector3(0.45, 0.85, 0.45), Vector3(cx, 0.42, cz), Color(0.33, 0.27, 0.23))
		var back_z := cz + (-0.55 if cx > 0 else 0.55)
		Chamber.make_prop_box(self, Vector3(0.45, 1.10, 0.10), Vector3(cx, 0.95, back_z), Color(0.33, 0.27, 0.23))

	# Note 16 - Yuna's note under Mara's plate
	Interactable.make_note(self, Vector3(-0.80, table_y + 0.10, -3.6), "note_16", "Slide out the folded note")

	# Galley counter along east wall
	Chamber.make_prop_box(self, Vector3(2.0, 0.95, D - 1.0), Vector3(W/2 - 1.0, 0.47, 0), Color(0.37, 0.39, 0.43))

	# Sink basins + faucets
	for sz in [-3.0, -1.5]:
		Chamber.make_prop_box(self, Vector3(1.2, 0.08, 1.0), Vector3(W/2 - 1.0, 0.95, sz), Color(0.23, 0.27, 0.31))
		Chamber.make_prop_box(self, Vector3(0.06, 0.25, 0.06), Vector3(W/2 - 1.5, 1.12, sz - 0.05), Color(0.70, 0.74, 0.78))

	# Coffee pot
	var coffee_pot := Chamber.make_prop_box(self, Vector3(0.40, 0.55, 0.30), Vector3(W/2 - 1.0, 1.27, 1.0), Color(0.16, 0.18, 0.22))
	Interactable.attach(coffee_pot, "Look at the coffee pot", "examine_only", {
		"text": "The coffee pot is still warm.  Some of it has reduced to a black sludge in the bottom.  OLEN keeps the warmer on a five-day timer for the morning shift.  It has been five days.",
		"duration": 5.0,
	})

	# Note 15 - grocery list on cork board
	var cork := Chamber.make_prop_box(self, Vector3(0.04, 0.50, 0.40), Vector3(W/2 - 0.13, 2.0, 1.0), Color(0.62, 0.51, 0.35))
	Interactable.attach(cork, "Read the pinned list", "collect_note", {"note_id": "note_15"})

	# Microwave on the counter
	Chamber.make_prop_box(self, Vector3(0.7, 0.45, 0.6), Vector3(W/2 - 1.0, 1.22, 3.5), Color(0.31, 0.33, 0.37))

	# Stack of trays
	for ty in range(4):
		Chamber.make_prop_box(self, Vector3(0.55, 0.04, 0.40), Vector3(W/2 - 1.0, 1.00 + ty * 0.05, -5.5), Color(0.90, 0.88, 0.82), false)

	# Potted herb plant
	var pot := Chamber.make_prop_box(self, Vector3(0.20, 0.20, 0.20), Vector3(W/2 - 1.5, 1.10, 0), Color(0.67, 0.51, 0.35))
	Interactable.attach(pot, "Examine the herb pot", "examine_only", {
		"text": "Yuna's basil plant.  A handwritten tag in the soil:  'pinch the tops weekly.  do not let it flower.  ask Mara to water on Tuesdays.'  You don't remember being asked.",
		"duration": 5.0,
	})

	# West wall: mess schedule whiteboard
	var board := Chamber.make_prop_box(self, Vector3(0.10, 1.6, 2.4), Vector3(-W/2 + 0.10, 1.8, 0), Color(0.94, 0.94, 0.96))
	Interactable.attach(board, "Read the mess schedule", "examine_only", {
		"text": "MESS ROTATION - week 8\n  Mon  Park\n  Tue  Okafor\n  Wed  Sato\n  Thu  Hargrove\n  Fri  Voss\n  Sat  Park / Voss (bake-off, !)\n  Sun  free\n\nBelow it in Yuna's handwriting:\n  Mara - I covered Friday for you again.\n  Please come eat with us.  We saved you a seat.  Yuna.",
		"duration": 8.0,
	})

	# Side bench with tablet
	Chamber.make_prop_box(self, Vector3(2.0, 0.40, 0.6), Vector3(W/2 - 3.0, 0.20, -D/2 + 1.0), Color(0.35, 0.27, 0.22))
	var tablet := Chamber.make_prop_box(self, Vector3(0.30, 0.04, 0.20), Vector3(W/2 - 3.0, 0.42, -D/2 + 1.0), Color(0.16, 0.20, 0.24))
	Interactable.attach(tablet, "Wake the tablet", "examine_only", {
		"text": "A station-issue tablet.  The lock screen wallpaper is a photo of Hargrove's dog, a big golden retriever named WALTER.  Below it the message preview reads:\n  'pls call when you can.  miss u.  - L.'",
		"duration": 6.0,
	})

	# Pendant lights over table
	for tz in [-3, 0, 3]:
		Chamber.make_prop_box(self, Vector3(0.12, 0.40, 0.12), Vector3(0, H - 0.4, tz), Color(0.16, 0.16, 0.20))
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.10
		sm.height = 0.20
		bulb.mesh = sm
		bulb.position = Vector3(0, H - 0.75, tz)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(1.0, 0.86, 0.62)
		bm.emission_enabled = true
		bm.emission = Color(1.0, 0.86, 0.62)
		bm.emission_energy_multiplier = 0.6
		bulb.material_override = bm
		add_child(bulb)

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _place_setting(x: float, z: float, table_y: float, plate_color: Color, food_color: Color, mug_color: Color, empty: bool, plate_name: String) -> void:
	# Plate (slightly raised so it sits flush on the table top)
	Chamber.make_prop_box(self, Vector3(0.42, 0.05, 0.42), Vector3(x, table_y + 0.06, z), plate_color)
	if not empty:
		# Food as a flat oval slab rather than a sphere — looks like a meal, not a ball
		var food := MeshInstance3D.new()
		var food_box := BoxMesh.new()
		food_box.size = Vector3(0.30, 0.05, 0.24)
		food.mesh = food_box
		food.position = Vector3(x, table_y + 0.11, z)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		fm.albedo_color = food_color
		fm.roughness = 0.85
		food.material_override = fm
		add_child(food)
		# Small side garnish/sauce smear
		Chamber.make_prop_box(self, Vector3(0.10, 0.02, 0.10), Vector3(x + 0.12, table_y + 0.08, z + 0.08),
			Color(food_color.r * 0.7, food_color.g * 0.6, food_color.b * 0.5), false)
	# Mug (cylinder-shaped so it reads as crockery, not a block)
	var mug := MeshInstance3D.new()
	var mb := CylinderMesh.new()
	mb.top_radius = 0.055
	mb.bottom_radius = 0.045
	mb.height = 0.16
	mug.mesh = mb
	mug.position = Vector3(x + 0.32, table_y + 0.16, z - 0.18)
	var mmat := StandardMaterial3D.new()
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mmat.albedo_color = mug_color
	mmat.roughness = 0.5
	mug.material_override = mmat
	add_child(mug)
	# Cutlery
	Chamber.make_prop_box(self, Vector3(0.03, 0.02, 0.20), Vector3(x - 0.30, table_y + 0.08, z), Color(0.74, 0.76, 0.80), false)
	Chamber.make_prop_box(self, Vector3(0.03, 0.02, 0.20), Vector3(x + 0.30, table_y + 0.08, z + 0.05), Color(0.74, 0.76, 0.80), false)
	# Name plate — laid flat on the table, in front of the place setting
	var nplate := Label3D.new()
	nplate.text = plate_name
	nplate.position = Vector3(x, table_y + 0.10, z + 0.32)
	nplate.rotation_degrees = Vector3(-90, 0, 0)
	nplate.font_size = 20
	nplate.modulate = Color(0.16, 0.12, 0.08)
	nplate.outline_size = 4
	nplate.outline_modulate = Color(0.94, 0.92, 0.86, 0.9)
	add_child(nplate)


func _process(_dt: float) -> void:
	if GameState.mess_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act5")
