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
var flicker_lights: Array[Dictionary] = []


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

	# Half-open pressure bulkhead at z=-2 — jambs + raised door panel (walk under)
	var bulk_z := -2.0
	for jx in [-W/2 + 0.30, W/2 - 0.30]:
		Chamber.make_prop_box(self, Vector3(0.40, H, 0.40), Vector3(jx, H/2, bulk_z), Color(0.31, 0.27, 0.20))
	# Header
	Chamber.make_prop_box(self, Vector3(W - 0.6, 0.40, 0.40), Vector3(0, H - 0.20, bulk_z), Color(0.31, 0.27, 0.20))
	# Bulkhead door raised — sits at the top of the frame, player walks underneath.
	# Marked non-colliding so the door panel itself doesn't block traversal.
	var bulk_door := Chamber.make_prop_box(self, Vector3(W - 0.8, 0.90, 0.10), Vector3(0, H - 0.85, bulk_z), Color(0.43, 0.35, 0.23), false)
	# Hazard stripes on the raised door
	for sy in [0.25, -0.25]:
		Chamber.make_prop_box(self, Vector3(W - 1.2, 0.10, 0.20), Vector3(0, H - 0.85 + sy, bulk_z - 0.06), Color(0.86, 0.70, 0.12), false)
	# Door track / runner so it looks like it slid up
	Chamber.make_prop_box(self, Vector3(W - 0.6, 0.06, 0.18), Vector3(0, H - 0.45, bulk_z - 0.18), Color(0.16, 0.16, 0.20), false)
	# Label
	var bulk_lbl := Label3D.new()
	bulk_lbl.text = "ARRAY ACCESS"
	bulk_lbl.position = Vector3(0, H - 0.20, bulk_z - 0.25)
	bulk_lbl.font_size = 20
	bulk_lbl.modulate = Color(0.86, 0.78, 0.62)
	bulk_lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	bulk_lbl.no_depth_test = false
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

	# Extra corridor clutter so the long walk to the array doesn't feel sterile
	# Discarded clipboard
	Chamber.make_prop_box(self, Vector3(0.22, 0.02, 0.30), Vector3(-1.2, 0.04, -3.0), Color(0.55, 0.43, 0.27))
	Chamber.make_prop_box(self, Vector3(0.20, 0.005, 0.26), Vector3(-1.2, 0.05, -3.0), Color(0.92, 0.88, 0.78), false)
	# Knocked-over barrel
	var barrel := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.28
	bm.bottom_radius = 0.28
	bm.height = 0.80
	barrel.mesh = bm
	barrel.position = Vector3(-1.5, 0.28, 7.0)
	barrel.rotation_degrees = Vector3(0, 0, 90)
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	bmat.albedo_color = Color(0.55, 0.30, 0.22)
	bmat.metallic = 0.6
	bmat.roughness = 0.5
	barrel.material_override = bmat
	add_child(barrel)
	# Hazard bands on barrel
	for hb in [0.20, -0.20]:
		var hbnd := MeshInstance3D.new()
		var hbc := CylinderMesh.new()
		hbc.top_radius = 0.30
		hbc.bottom_radius = 0.30
		hbc.height = 0.10
		hbnd.mesh = hbc
		hbnd.position = Vector3(-1.5 + hb, 0.28, 7.0)
		hbnd.rotation_degrees = Vector3(0, 0, 90)
		var hbmat := StandardMaterial3D.new()
		hbmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		hbmat.albedo_color = Color(0.86, 0.70, 0.16)
		hbmat.emission_enabled = true
		hbmat.emission = Color(0.86, 0.70, 0.16)
		hbmat.emission_energy_multiplier = 0.2
		hbnd.material_override = hbmat
		add_child(hbnd)

	# Cable trough on the floor pulled out of conduit
	Chamber.make_prop_box(self, Vector3(0.08, 0.06, 2.0), Vector3(1.6, 0.05, -10.0), Color(0.20, 0.18, 0.16), false)
	Chamber.make_prop_box(self, Vector3(0.08, 0.06, 2.0), Vector3(1.7, 0.04, -10.5), Color(0.55, 0.40, 0.18), false)

	# Coiled hose against east wall further down
	var hose := MeshInstance3D.new()
	var hc := CylinderMesh.new()
	hc.top_radius = 0.30
	hc.bottom_radius = 0.30
	hc.height = 0.10
	hose.mesh = hc
	hose.position = Vector3(W/2 - 0.5, 0.20, -11.0)
	hose.rotation_degrees = Vector3(90, 0, 0)
	var hmat2 := StandardMaterial3D.new()
	hmat2.albedo_color = Color(0.18, 0.18, 0.20)
	hmat2.metallic = 0.3
	hmat2.roughness = 0.7
	hose.material_override = hmat2
	add_child(hose)

	# Service trolley pushed against the wall just past the bulkhead
	Chamber.make_prop_box(self, Vector3(0.55, 0.75, 0.50), Vector3(W/2 - 0.55, 0.37, 0.0), Color(0.20, 0.22, 0.27))
	Chamber.make_prop_box(self, Vector3(0.50, 0.04, 0.45), Vector3(W/2 - 0.55, 0.78, 0.0), Color(0.16, 0.16, 0.20), false)

	# More wall posters / placards along the corridor
	for ply in [["DANGER\nHIGH ENERGY", Color(0.95, 0.55, 0.20), 5.0],
		["AUTHORIZED\nPERSONNEL", Color(0.78, 0.55, 0.20), 11.0],
		["FAULT", Color(0.55, 0.20, 0.20), 13.5]]:
		ActUtil.wall_poster(self, "x", -W/2 + 0.05, Vector3(-W/2 + 0.06, 1.85, ply[2]), Vector2(0.45, 0.35), Color(0.20, 0.16, 0.12))
		ActUtil.wall_label(self, ply[0], Vector3(-W/2 + 0.04, 1.85, ply[2]), 12,
			ply[1], Color(0, 0, 0, 0.7))

	# Hanging chains from ceiling on the south half
	for cz in [-12.0, -8.0]:
		Chamber.make_prop_box(self, Vector3(0.06, 1.0, 0.06), Vector3(1.0, H - 0.6, cz), Color(0.16, 0.16, 0.20), false)
		# Hook at the bottom
		Chamber.make_prop_box(self, Vector3(0.12, 0.06, 0.06), Vector3(1.0, H - 1.10, cz), Color(0.20, 0.20, 0.24), false)

	# Wall vents
	ActUtil.wall_vent(self, "x", -W/2 + 0.05, -6.0, 2.6, Vector2(0.5, 0.4))
	ActUtil.wall_vent(self, "x", W/2 - 0.05, 4.0, 2.6, Vector2(0.5, 0.4))

	# Dust motes for the gloomy corridor atmosphere
	ActUtil.add_dust_motes(self, Vector3(0, 1.4, 0), Vector3(2.4, 0.8, 14), 100,
		Color(0.72, 0.78, 0.86, 0.2))

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

	# Environmental dread along the approach: scrawls + a long blood smear.
	ActUtil.wall_scrawl(self, "TURN\nBACK", Vector3(-2.42, 1.9, -2.0), 90, 48)
	ActUtil.wall_scrawl(self, "DON'T\nLISTEN", Vector3(2.42, 1.9, 6.0), -90, 44)
	for bz in range(0, 9):
		ActUtil.blood_decal(self, Vector3(0.4 - bz * 0.1, 0.02, -6.0 + bz * 1.6), Vector2(0.6, 1.0))

	# The long dark walk to the array — peak dread, it stalks the whole length.
	ActUtil.haunt(self, {
		"intensity": 0.90,
		"flicker_rate": 1.5,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(0, 0, 14), Vector3(0, 0, 6), Vector3(-1.5, 0, -2), Vector3(1.5, 0, -8)], "creep": 0.9}],
	})

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
