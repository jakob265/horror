extends Node3D
# ACT 9 - APPROACH CORRIDOR.
# Long dark corridor leading to array room. Pressure bulkhead halfway down,
# alcoves with sealed hatch and dead phone, Note 13 scratched in panel,
# Hargrove-Shape at far end that retreats when player approaches.

const W := 5.0
const D := 32.0
const H := 3.2

var hargrove_shape: HorrorShape = null
var retreating := false
var retreat_t := 0.0
var flicker_lights: Array = []


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.31, 0.35, 0.43), Color(0.04, 0.06, 0.08), 0.030, 0.40)
	Chamber.add_floor_ceiling(self, W, D, H, Color(0.16, 0.18, 0.22), Color(0.08, 0.10, 0.12))
	var wall := Color(0.20, 0.22, 0.27)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)

	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "MAINTENANCE", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "ARRAY", Color(0.43, 0.31, 0.23),
		func(): GameState.approach_door_open = true, "Open ARRAY")

	# Pipe bundles along walls
	for fx in [-W/2 + 0.20, W/2 - 0.20]:
		for cfg in [[0.40, Color(0.55, 0.43, 0.23)],
					[1.10, Color(0.23, 0.31, 0.43)]]:
			Chamber.make_prop_box(self, Vector3(0.14, 0.14, D - 2.0), Vector3(fx, cfg[0], 0), cfg[1], false)
		for cz in range(-13, 14, 3):
			Chamber.make_prop_box(self, Vector3(0.20, 0.20, 0.10), Vector3(fx, 0.75, cz), Color(0.23, 0.23, 0.27), false)

	# Periodic floor lights
	for tz in range(-14, 15, 3):
		var stripe := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(2.0, 0.30)
		stripe.mesh = sq
		stripe.rotation_degrees = Vector3(-90, 0, 0)
		stripe.position = Vector3(0, 0.02, tz)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.59, 0.67, 0.78, 0.4)
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.emission_enabled = true
		smat.emission = Color(0.59, 0.67, 0.78)
		smat.emission_energy_multiplier = 0.4
		stripe.material_override = smat
		add_child(stripe)

	# Ceiling flicker lights
	for tz in range(-13, 14, 4):
		var fl := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.6, 0.04, 0.20)
		fl.mesh = fb
		fl.position = Vector3(0, H - 0.10, tz)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.70, 0.78, 0.86)
		fmat.emission_enabled = true
		fmat.emission = Color(0.70, 0.78, 0.86)
		fmat.emission_energy_multiplier = 0.7
		fl.material_override = fmat
		add_child(fl)
		flicker_lights.append({
			"node": fl,
			"timer": randf_range(3.0, 11.0),
			"dim": false,
		})

	# Half-open pressure bulkhead at z=-2
	var bulk_z := -2.0
	for jx in [-W/2 + 0.30, W/2 - 0.30]:
		Chamber.make_prop_box(self, Vector3(0.40, H, 0.40), Vector3(jx, H/2, bulk_z), Color(0.31, 0.27, 0.20))
	# Header
	Chamber.make_prop_box(self, Vector3(W - 0.6, 0.40, 0.40), Vector3(0, H - 0.20, bulk_z), Color(0.31, 0.27, 0.20))
	# Bulkhead door half-open
	var bulk_door := Chamber.make_prop_box(self, Vector3(W - 0.8, 2.0, 0.10), Vector3(0, 2.0, bulk_z), Color(0.43, 0.35, 0.23))
	# Hazard stripes
	for sy in [0.6, -0.6]:
		Chamber.make_prop_box(self, Vector3(W - 1.2, 0.10, 0.20), Vector3(0, 2.0 + sy, bulk_z - 0.06), Color(0.86, 0.70, 0.12), false)
	# Label
	var bulk_lbl := Label3D.new()
	bulk_lbl.text = "ARRAY ACCESS"
	bulk_lbl.position = Vector3(0, H - 0.20, bulk_z - 0.25)
	bulk_lbl.font_size = 20
	bulk_lbl.modulate = Color(0.86, 0.78, 0.62)
	add_child(bulk_lbl)

	# West alcove: sealed maintenance hatch at z=-8
	var alc_z_west := -8.0
	Chamber.make_prop_box(self, Vector3(0.10, 2.2, 1.6), Vector3(-W/2 - 0.05, 1.1, alc_z_west), Color(0.22, 0.24, 0.30))
	var hatch := Chamber.make_prop_box(self, Vector3(0.20, 1.0, 1.0), Vector3(-W/2 + 0.20, 1.10, alc_z_west), Color(0.31, 0.27, 0.20))
	# Hatch wheel
	var wheel := MeshInstance3D.new()
	var wsphere := SphereMesh.new()
	wsphere.radius = 0.15
	wsphere.height = 0.10
	wheel.mesh = wsphere
	wheel.position = Vector3(-W/2 + 0.40, 1.10, alc_z_west)
	wheel.rotation_degrees = Vector3(0, 0, 90)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.55, 0.51, 0.39)
	wheel.material_override = wmat
	add_child(wheel)
	# Red status light
	Chamber.make_prop_box(self, Vector3(0.04, 0.10, 0.10), Vector3(-W/2 + 0.50, 1.45, alc_z_west + 0.30), Color(0.86, 0.23, 0.23), false)
	Interactable.attach(hatch, "Try the maintenance hatch", "examine_only", {
		"text": "A sealed maintenance hatch.  Status light is red.  The wheel won't turn.  In the frost on the porthole someone has written, in the same lowercase hand as everything else now:  'do not open until it is done.'",
		"duration": 6.0,
	})

	# East alcove: dead emergency phone at z=6
	var alc_z_east := 6.0
	Chamber.make_prop_box(self, Vector3(0.10, 2.2, 1.6), Vector3(W/2 + 0.05, 1.1, alc_z_east), Color(0.22, 0.24, 0.30))
	var phone_box := Chamber.make_prop_box(self, Vector3(0.40, 0.70, 0.40), Vector3(W/2 - 0.10, 1.30, alc_z_east), Color(0.86, 0.23, 0.20))
	# Handset
	Chamber.make_prop_box(self, Vector3(0.10, 0.10, 0.40), Vector3(W/2 - 0.40, 1.20, alc_z_east), Color(0.12, 0.12, 0.14), false)
	# Cable
	Chamber.make_prop_box(self, Vector3(0.06, 1.20, 0.06), Vector3(W/2 - 0.40, 0.45, alc_z_east + 0.10), Color(0.12, 0.12, 0.14), false)
	# Receiver on floor
	Chamber.make_prop_box(self, Vector3(0.10, 0.10, 0.30), Vector3(W/2 - 0.40, 0.10, alc_z_east), Color(0.12, 0.12, 0.14), false)
	Interactable.attach(phone_box, "Pick up the emergency phone", "examine_only", {
		"text": "Bright red emergency phone.  Receiver is off the hook, lying on the alcove floor.  You hold it to your ear.  There is no dial tone.  There is breathing, very slow.  You realise after a long moment that it is your own breathing, and that the phone isn't connected to anything.",
		"duration": 8.0,
	})

	# Note 13 - scratched into wall panel
	var n13 := Chamber.make_prop_box(self, Vector3(0.08, 0.4, 0.6), Vector3(-W/2 + 0.10, 1.3, 3.5), Color(0.18, 0.20, 0.25))
	Interactable.attach(n13, "Read scratched panel", "collect_note", {"note_id": "note_13"})

	# Discarded boot in middle of corridor
	var boot := Chamber.make_prop_box(self, Vector3(0.20, 0.18, 0.40), Vector3(0.8, 0.09, -5), Color(0.16, 0.14, 0.12))
	boot.rotation_degrees = Vector3(0, 25, 0)
	Interactable.attach(boot, "Look at the boot", "examine_only", {
		"text": "A single station-issue boot in the middle of the corridor.  Size says HARGROVE.  Why would he have only worn one?",
		"duration": 5.0,
	})

	# Floor smears
	for sz in range(-2, 14, 2):
		var smear := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(0.40, 0.80)
		smear.mesh = sq
		smear.rotation_degrees = Vector3(-90, 0, 0)
		smear.position = Vector3(-0.5 + (sz % 3) * 0.2, 0.02, sz)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.16, 0.12, 0.12, 0.6)
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smear.material_override = smat
		add_child(smear)

	# Hargrove-Shape at far end, facing away
	hargrove_shape = HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(0, 0, D/2 - 3.0), 0)
	add_child(hargrove_shape)
	ShapeTracker.register(hargrove_shape)

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _process(dt: float) -> void:
	# Flicker lights
	for fl in flicker_lights:
		fl["timer"] -= dt
		if fl["timer"] <= 0:
			var mat: StandardMaterial3D = fl["node"].material_override
			if not fl["dim"]:
				fl["dim"] = true
				mat.emission_energy_multiplier = 0.1
				fl["timer"] = randf_range(0.05, 0.20)
			else:
				fl["dim"] = false
				mat.emission_energy_multiplier = 0.7
				fl["timer"] = randf_range(4.0, 14.0)

	# Hargrove retreat
	if hargrove_shape and is_instance_valid(hargrove_shape) and hargrove_shape.visible:
		if not retreating and GameState.player:
			if GameState.player.global_position.distance_to(hargrove_shape.global_position) < 8.0:
				retreating = true
		if retreating:
			retreat_t += dt
			hargrove_shape.position.z += dt * 0.5
			if retreat_t > 8.0:
				hargrove_shape.visible = false

	if GameState.approach_door_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act10")
