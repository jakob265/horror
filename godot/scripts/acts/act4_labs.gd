extends Node3D
# VESPER - ACT 4: THE SAMPLE LABS
# The first real hunt. A hunter circles the lab hall while you find the bolt
# cutters in sample storage and cut the chain on the blast door north. The
# breached core ("the seed") spills its dark filament across the storage room.

const WALL := Color(0.28, 0.31, 0.36)
const FLOOR := Color(0.32, 0.34, 0.38)
const CEIL := Color(0.12, 0.13, 0.16)

var exit_door: Node3D = null
var chain: Node3D = null
var cut := false


func _ready() -> void:
	ActUtil.light_rig_dark(self, 0.12, 0.022)
	_build_lab()
	_build_storage()
	_build_prep()

	# An aggressive hunter circuits the lab hall.
	var stalker := HorrorShape.create(HorrorShape.KIND_FELIX, Vector3(0, 0, -4.0), 0.0)
	stalker.set_stalk([Vector3(0, 0, -5.0), Vector3(6, 0, 0.0), Vector3(0, 0, 5.0), Vector3(-6, 0, 0.0)], 1.2, 4.0)
	add_child(stalker)
	ShapeTracker.register(stalker)

	ActUtil.haunt(self, {"intensity": 0.5, "flicker": true, "flicker_rate": 1.4})

	# "It is wearing Sundqvist now."
	ActUtil.enable_lure(self, {
		"voice": "Sundqvist",
		"calls": [
			{"call": "you found my notes. come read the rest with me - it's warmer in here.",
			 "answer": "there you are. i knew your light anywhere."},
			{"call": "the sample's awake. you should see how it leans toward you.",
			 "answer": "good. stay still. let me come to you."},
			{"call": "i kept your seat for you. by the lamp. where i can see your face.",
			 "answer": "thank you. don't move. don't move."},
		],
	})

	if GameState.player:
		GameState.player.global_position = Vector3(-7.0, 0.5, 0.0)
		GameState.player.rotation_degrees.y = -90.0


func _process(_dt: float) -> void:
	if cut and GameState.player and GameState.player.global_position.z < -6.6:
		SceneRouter.transition_to("act4_5")


# --- Lab hall ------------------------------------------------------------

func _build_lab() -> void:
	Chamber.add_room(self, 16, 14, 3.6, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "x", "fixed": -8.0, "gap": 0.0}, {"axis": "x", "fixed": 8.0, "gap": 0.0},
		{"axis": "z", "fixed": -7.0, "gap": 0.0}])
	ActUtil.add_ceiling_pipes(self, 16, 14, 3.6, Vector3(0, 0, 0))
	# Blast door north, chained shut.
	exit_door = Chamber.add_door(self, "z", -7 + 0.05, 0, "BLAST DOOR", Color(0.24, 0.27, 0.33), Callable(), "", true)
	# Invisible wall on the way in - can't back out into the void.
	Chamber.invis_wall(self, "x", -8, 0)
	chain = Node3D.new()
	add_child(chain)
	for cy in [0.8, 1.4, 2.0]:
		var link := Chamber.make_prop_box(chain, Vector3(1.5, 0.12, 0.12), Vector3(0, cy, -6.85), Color(0.18, 0.18, 0.20), false)
		link.name = "chain_link"
	var padlock := Chamber.make_prop_box(chain, Vector3(0.22, 0.3, 0.12), Vector3(0, 1.1, -6.78), Color(0.5, 0.45, 0.15), false)
	Interactable.attach(exit_door, "Cut the chain", "use_item", {
		"required_item": "bolt_cutters", "consume": false,
		"on_use": Callable(self, "_cut_chain"),
		"locked_text": "Chained and padlocked from this side. You need cutters.",
	})
	# Workbenches with dead equipment + microscopes + monitors.
	for wb in [Vector3(-5, 0, 5), Vector3(0, 0, 5.5), Vector3(5, 0, 5)]:
		Chamber.make_prop_box(self, Vector3(2.2, 0.1, 0.9), wb + Vector3(0, 0.85, 0), Color(0.40, 0.42, 0.46))
		for lx in [-0.9, 0.9]:
			Chamber.make_prop_box(self, Vector3(0.08, 0.85, 0.08), wb + Vector3(lx, 0.42, 0.3), Color(0.3, 0.3, 0.34), false)
		Chamber.make_prop_box(self, Vector3(0.4, 0.5, 0.3), wb + Vector3(-0.6, 1.15, 0), Color(0.18, 0.20, 0.24), false)
		Chamber.make_prop_box(self, Vector3(0.25, 0.35, 0.1), wb + Vector3(0.6, 1.1, -0.1), Color(0.1, 0.14, 0.18), false)
	# Supply lockers to hide in when it comes round.
	ActUtil.hide_locker(self, Vector3(-7.4, 0, 5.0), -90.0)
	ActUtil.hide_locker(self, Vector3(-7.4, 0, -5.0), -90.0)
	# A specimen fridge bank along the south.
	for fx in [-3, -1.4, 0.2, 1.8]:
		Chamber.make_prop_box(self, Vector3(1.3, 2.0, 0.8), Vector3(fx, 1.0, 6.2), Color(0.42, 0.46, 0.50))
	ActUtil.wall_label(self, "SAMPLE LAB", Vector3(0, 3.0, 6.8), 24, Color(0.7, 0.84, 0.9))
	ActUtil.wall_scrawl(self, "LEAVE IT IN THE ICE", Vector3(-4.0, 2.1, -6.85), 0.0, 30, Color(0.5, 0.05, 0.06))
	ActUtil.corpse(self, Vector3(4.5, 0, -4.5), 200.0, true, Color(0.24, 0.26, 0.30))
	ActUtil.blood_trail(self, Vector3(4.5, 0.02, -4.5), Vector3(7.0, 0.02, 0.0), 6)


# --- Sample storage (the breached core + the cutters) --------------------

func _build_storage() -> void:
	# South wall now has a doorway at x=15 into the sample-prep room.
	Chamber.add_room(self, 10, 8, 3.4, FLOOR, CEIL, WALL, Vector3(13, 0, 0), {},
		[{"axis": "x", "fixed": 8.0, "gap": 0.0},
		 {"axis": "z", "fixed": 4.0, "gap": 15.0}])
	# The containment cylinder, cracked open, the seed spilling out.
	var base := Chamber.make_prop_box(self, Vector3(1.6, 0.4, 1.6), Vector3(15.0, 0.2, 0.0), Color(0.30, 0.33, 0.38))
	var cyl := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7
	cm.bottom_radius = 0.7
	cm.height = 2.0
	cm.radial_segments = 20
	cyl.mesh = cm
	cyl.position = Vector3(15.0, 1.4, 0.0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.4, 0.55, 0.7, 0.25)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.05
	cyl.material_override = gm
	add_child(cyl)
	ActUtil.signal_growth(self, Vector3(15.0, 0.4, 0.0), 2.0, Color(0.08, 0.13, 0.10))
	ActUtil.signal_growth(self, Vector3(16.2, 0, 1.6), 1.4, Color(0.09, 0.14, 0.10))
	ActUtil.signal_growth(self, Vector3(13.6, 0, -1.8), 1.2, Color(0.09, 0.14, 0.10))
	ActUtil.add_omni(self, Vector3(15.0, 2.8, 0.0), Color(0.4, 0.6, 0.7), 1.2, 6.0, false)
	# The cutters on a shelf by a slumped body.
	_make_pickup(Vector3(16.6, 0.95, -2.6), Vector3(0.55, 0.12, 0.18), Color(0.7, 0.5, 0.12), "bolt_cutters", "Take the bolt cutters")
	Chamber.make_prop_box(self, Vector3(0.8, 1.0, 0.5), Vector3(16.8, 0.5, -2.6), Color(0.30, 0.33, 0.37))
	ActUtil.corpse(self, Vector3(16.5, 0, 2.6), -150.0, true, Color(0.22, 0.20, 0.16))
	ActUtil.viscera(self, Vector3(15.6, 0.02, 2.2))
	Interactable.make_note(self, Vector3(11.0, 0.04, 2.5), "v_labs", "Read the workstation log")
	# A lab notebook in someone else's shorthand. The signal enters through grief.
	Interactable.make_note(self, Vector3(-3.5, 0.83, -1.5), "note_5", "Read the lab notebook")
	# Engineering transcript - a confession addressed to no one here.
	Interactable.make_note(self, Vector3(15.8, 0.04, -2.6), "note_11", "Read the engineering transcript")
	ActUtil.bloody_smears(self, Vector3(17.85, 2.2, 0.0), -90.0, 5)
	ActUtil.wall_label(self, "SAMPLE STORAGE", Vector3(10.5, 2.9, 3.8), 18, Color(0.7, 0.84, 0.9))


# --- Sample prep (south off storage, the analysis bench + a second body) --
# Where the samples got dissected before storage. Hangs off the storage room's
# south wall (z=4) at the new doorway centred on x=15. Shares that wall, so
# we only add three new walls and a floor/ceiling slab.

func _build_prep() -> void:
	# Prep room must reach the storage south wall at z=4 (not z=6) or the strip
	# z[4,6] is open void. Floor spans z[4,12] (d=8, centre 8); side walls span
	# z[4,12]. The storage z=4 wall already has the doorway gap at x=15.
	Chamber.add_floor_ceiling(self, 8, 8, 3.2, FLOOR, CEIL, Vector3(15, 0, 8))
	Chamber.add_wall(self, "x", 11, 4, 12, 3.2, WALL)
	# East wall: split around the side-wing portal (z[6,10]) by helper.
	RoomGen.add_side_wing(self, {
		"host_axis": "x", "host_fixed": 19.0,
		"host_min": 4.0, "host_max": 12.0, "host_h": 3.2,
		"host_color": WALL,
		"theme": "lab", "axis": "x",
		"along_min": 19.0, "along_max": 37.0, "perp": 8.0,
		"corridor_w": 4.0, "corridor_h": 3.0,
		"rooms_left": 2, "rooms_right": 2,
		"room_depth": 6.0, "room_w_along": 5.5, "room_h": 3.0,
		"seed": 4400,
	})
	ActUtil.wall_label(self, "ARCHIVE", Vector3(19.15, 2.6, 8.0), 16, Color(0.78, 0.84, 0.6))
	Chamber.add_wall(self, "z", 12, 11, 19, 3.2, WALL)

	# Analysis bench, autoclave, centrifuge - all dead, all bloodied.
	Chamber.make_prop_box(self, Vector3(5.0, 0.10, 1.0), Vector3(15.0, 0.92, 7.6), Color(0.42, 0.44, 0.48))
	for blx in [12.7, 14.5, 17.2]:
		Chamber.make_prop_box(self, Vector3(0.08, 0.92, 0.08), Vector3(blx, 0.46, 7.3), Color(0.30, 0.32, 0.36), false)
		Chamber.make_prop_box(self, Vector3(0.08, 0.92, 0.08), Vector3(blx, 0.46, 7.9), Color(0.30, 0.32, 0.36), false)
	# Autoclave (drum on the bench).
	Chamber.make_prop_box(self, Vector3(0.7, 0.6, 0.7), Vector3(13.5, 1.30, 7.6), Color(0.62, 0.64, 0.66))
	# Centrifuge.
	Chamber.make_prop_box(self, Vector3(0.6, 0.5, 0.6), Vector3(16.6, 1.25, 7.6), Color(0.46, 0.48, 0.52))
	# Microscope.
	Chamber.make_prop_box(self, Vector3(0.3, 0.5, 0.25), Vector3(15.5, 1.25, 7.7), Color(0.20, 0.22, 0.26))
	# Fume hood along the south wall.
	Chamber.make_prop_box(self, Vector3(3.0, 2.4, 0.5), Vector3(17.0, 1.2, 11.6), Color(0.30, 0.34, 0.38))
	Chamber.make_prop_box(self, Vector3(2.7, 1.4, 0.05), Vector3(17.0, 1.5, 11.32), Color(0.05, 0.07, 0.10), false)
	# Sample shelves along the west wall.
	for sy in [0.6, 1.2, 1.8]:
		Chamber.make_prop_box(self, Vector3(0.06, 0.06, 2.4), Vector3(11.18, sy, 9.0), Color(0.30, 0.32, 0.36), false)
		Chamber.make_prop_box(self, Vector3(0.18, 0.30, 0.18), Vector3(11.25, sy + 0.15, 9.6), Color(0.45, 0.62, 0.70), false)
		Chamber.make_prop_box(self, Vector3(0.18, 0.30, 0.18), Vector3(11.25, sy + 0.15, 8.4), Color(0.55, 0.40, 0.30), false)
	# Hide locker by the door (the lab hunter chases you here through storage).
	ActUtil.hide_locker(self, Vector3(18.4, 0, 6.6), 180.0)

	# Horror dressing.
	ActUtil.corpse(self, Vector3(15.0, 0, 10.4), 0.0, true, Color(0.18, 0.20, 0.24))
	ActUtil.viscera(self, Vector3(13.8, 0.02, 10.0))
	ActUtil.blood_wall(self, Vector3(11.15, 1.6, 11.0), Vector2(1.2, 1.6), 90.0)
	ActUtil.signal_growth(self, Vector3(12.8, 0, 11.4), 0.9, Color(0.09, 0.14, 0.10))
	ActUtil.wall_scrawl(self, "DON'T SPIN IT", Vector3(15.5, 2.2, 11.62), 0.0, 22, Color(0.5, 0.05, 0.06))
	ActUtil.wall_label(self, "SAMPLE PREP", Vector3(15, 2.9, 11.7), 16, Color(0.7, 0.84, 0.9))
	Interactable.make_examine(self, Vector3(13.5, 1.85, 7.6), Vector3(0.4, 0.04, 0.5),
		"Read the test sheet",
		"A printed test sheet pinned to the autoclave. Last line, hand-added: " +
		"'spinning it makes more of it. confirmed three times. do not run the centrifuge again.'", 6.0)


func _make_pickup(pos: Vector3, size: Vector3, color: Color, item_id: String, prompt: String) -> void:
	ActUtil.pickup(self, pos, size, color, item_id, prompt)


func _cut_chain() -> void:
	if cut:
		return
	cut = true
	if chain and is_instance_valid(chain):
		chain.queue_free()
	AudioManager.scrape()
	var t := exit_door.create_tween()
	t.tween_property(exit_door, "position:y", Chamber.DOOR_H + Chamber.DOOR_H / 2, 0.5)
	t.tween_callback(func() -> void:
		exit_door.visible = false
		for c in exit_door.get_children():
			if c is CollisionShape3D:
				c.disabled = true
	)
	InteractionManager.show_examine("The chain drops. The blast door grinds up. Go - it heard that.", 4.0)
