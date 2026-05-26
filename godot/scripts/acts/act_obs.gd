extends Node3D
# ACT - OBSERVATION DECK (between the lounge and the mess).
# A cupola where the crew came to look out at the stars and think of home.
# A wide viewport frames the array tower turning in the dark outside. A memorial
# the crew built — and one name added in Mara's own hand. Now the signal is
# growing in over the glass, and the dead are still watching the window.

const W := 14.0
const D := 12.0
const H := 4.2

var exit_open := false


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.42, 0.50, 0.64), Color(0.04, 0.07, 0.12), 0.013, 0.42,
		Color(0.66, 0.78, 0.98), 3.0, 12.0)
	ActUtil.add_dust_motes(self, Vector3(0, 1.8, 0), Vector3(6, 2.0, 5), 90,
		Color(0.78, 0.84, 0.96, 0.16))

	Chamber.add_floor_ceiling(self, W, D, H, Color(0.20, 0.23, 0.30), Color(0.09, 0.11, 0.17))
	var wall := Color(0.26, 0.30, 0.40)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	# South door back to the lounge (sealed), north door on to the mess.
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "LOUNGE", Color(0.50, 0.40, 0.30), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "MESS", Color(0.50, 0.40, 0.30),
		func(): exit_open = true, "Open MESS")
	ActUtil.wall_label(self, "<-  LOUNGE", Vector3(0, Chamber.DOOR_H + 0.12, -D/2 + 0.18), 15, Color(0.70, 0.80, 0.96))
	ActUtil.wall_label(self, "MESS  ->", Vector3(0, Chamber.DOOR_H + 0.12, D/2 - 0.18), 15, Color(0.70, 0.80, 0.96))
	ActUtil.wall_label(self, "OBSERVATION", Vector3(-W/2 + 0.10, 2.7, 3.0), 18, Color(0.62, 0.74, 0.94))

	_build_window()
	_build_memorial()

	# Two benches facing the viewport.
	for bz in [-2.2, 1.6]:
		Chamber.make_prop_box(self, Vector3(1.8, 0.45, 0.5), Vector3(3.0, 0.22, bz), Color(0.24, 0.22, 0.20))
		Chamber.make_prop_box(self, Vector3(1.8, 0.5, 0.12), Vector3(3.4, 0.55, bz), Color(0.22, 0.20, 0.18))

	# A telescope on a tripod angled up at the glass.
	Chamber.make_prop_box(self, Vector3(0.10, 1.1, 0.10), Vector3(4.6, 0.55, 3.0), Color(0.18, 0.18, 0.22))
	var scope := Chamber.make_prop_box(self, Vector3(0.7, 0.16, 0.16), Vector3(5.1, 1.15, 3.0), Color(0.30, 0.31, 0.36))
	scope.rotation_degrees = Vector3(0, 0, 24)
	Interactable.attach(scope, "Look through the scope", "examine_only", {
		"text": "The observation scope is still trained on the array tower.  Through it the tower fills the view, and the red light at its tip is not light at all — it is an absence, a hole the exact shape of something you miss.  You step back from the eyepiece.",
		"duration": 7.0,
	})

	# Stargazing logbook on the near bench.
	Interactable.make_examine(self, Vector3(3.0, 0.62, -2.2), Vector3(0.3, 0.06, 0.24),
		"Read the logbook",
		"A shared stargazing logbook.  Most entries are Yuna's, naming constellations for the others.  The last entry is not in her hand:  'we came up here to look out.  it was looking back the whole time.'",
		7.0, Color(0.80, 0.82, 0.74))

	# --- Horror dressing -------------------------------------------------
	# The signal is growing in over the glass; a watcher slumped at the window.
	ActUtil.signal_growth(self, Vector3(6.5, 2.4, -2.4), 1.2)
	ActUtil.signal_growth(self, Vector3(-6.4, 0.2, 4.2), 1.0)
	ActUtil.corpse(self, Vector3(4.4, 0, -2.2), 100)
	ActUtil.blood_trail(self, Vector3(1.5, 0, 0.0), Vector3(4.0, 0, -2.0), 6)
	ActUtil.viscera(self, Vector3(-5.6, 0, -3.6))
	ActUtil.bloody_smears(self, Vector3(6.86, 2.4, 1.2), -90, 4)
	ActUtil.wall_scrawl(self, "I CAN SEE\nHOME", Vector3(-6.92, 2.0, 1.5), 90, 38)
	ActUtil.add_peeker(self, Vector3(-5.5, 0, -4.8), HorrorShape.KIND_FELIX, 20)

	# A contemplative space between two louder rooms — dread simmers; one drifts.
	ActUtil.haunt(self, {
		"intensity": 0.30,
		"lurkers": [{"kind": "yuna", "points": [
			Vector3(-5, 0, 3), Vector3(5, 0, 3), Vector3(-5, 0, -3), Vector3(0, 0, 4)]}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


# A wide viewport set into the east wall: a starfield, the array tower turning
# in the dark, faint glass, and a heavy frame.
func _build_window() -> void:
	var face_x := 6.92
	# Deep-space backdrop.
	var sky := MeshInstance3D.new()
	var skyq := QuadMesh.new()
	skyq.size = Vector2(7.4, 2.9)
	sky.mesh = skyq
	sky.position = Vector3(face_x + 0.02, 2.05, 0)
	sky.rotation_degrees = Vector3(0, -90, 0)
	var skym := StandardMaterial3D.new()
	skym.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skym.albedo_color = Color(0.012, 0.018, 0.035)
	skym.emission_enabled = true
	skym.emission = Color(0.02, 0.03, 0.06)
	skym.emission_energy_multiplier = 0.4
	sky.material_override = skym
	add_child(sky)
	# Stars.
	for i in 54:
		var star := MeshInstance3D.new()
		var sq := QuadMesh.new()
		var s := randf_range(0.015, 0.045)
		sq.size = Vector2(s, s)
		star.mesh = sq
		star.position = Vector3(face_x - 0.01, randf_range(0.9, 3.2), randf_range(-3.4, 3.4))
		star.rotation_degrees = Vector3(0, -90, 0)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.emission_enabled = true
		var b := randf_range(0.5, 1.0)
		sm.albedo_color = Color(b, b, b * randf_range(0.9, 1.0))
		sm.emission = sm.albedo_color
		sm.emission_energy_multiplier = randf_range(1.0, 3.0)
		star.material_override = sm
		add_child(star)
	# The array tower, far off but unmistakable, with its one red not-a-star.
	var tower := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.04, 2.5, 0.22)
	tower.mesh = tb
	tower.position = Vector3(face_x - 0.03, 1.6, 1.7)
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_color = Color(0.015, 0.02, 0.03)
	tower.material_override = tm
	add_child(tower)
	var beacon := MeshInstance3D.new()
	var bq := SphereMesh.new()
	bq.radius = 0.06
	bq.height = 0.12
	beacon.mesh = bq
	beacon.position = Vector3(face_x - 0.05, 2.85, 1.7)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.95, 0.10, 0.07)
	bm.emission_enabled = true
	bm.emission = Color(0.95, 0.10, 0.07)
	bm.emission_energy_multiplier = 3.0
	beacon.material_override = bm
	add_child(beacon)
	# Faint glass.
	var glass := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(6.6, 2.6)
	glass.mesh = gq
	glass.position = Vector3(face_x - 0.10, 2.05, 0)
	glass.rotation_degrees = Vector3(0, -90, 0)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	gm.albedo_color = Color(0.40, 0.55, 0.72, 0.10)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.metallic = 0.6
	gm.roughness = 0.05
	glass.material_override = gm
	add_child(glass)
	# Heavy frame around the opening.
	var fm := Color(0.14, 0.15, 0.19)
	Chamber.make_prop_box(self, Vector3(0.22, 0.18, 7.0), Vector3(6.96, 3.45, 0), fm)
	var sill := Chamber.make_prop_box(self, Vector3(0.22, 0.18, 7.0), Vector3(6.96, 0.65, 0), fm)
	Interactable.attach(sill, "Look out the viewport", "examine_only", {
		"text": "You press a hand to the glass.  Out in the dark the array tower turns, slow and patient, the red light at its tip swelling as if it knows you are watching.  For a moment it looks like home is just on the other side.  That is exactly how it gets in.",
		"duration": 8.0,
	})
	for mz in [-3.4, -1.1, 1.1, 3.4]:
		Chamber.make_prop_box(self, Vector3(0.20, 2.95, 0.12), Vector3(6.95, 2.05, mz), fm)


# A small memorial the crew built by the wall — candles, photos, and a plaque
# whose last name is in Mara's own handwriting.
func _build_memorial() -> void:
	var bx := -5.4
	Chamber.make_prop_box(self, Vector3(1.8, 0.8, 0.5), Vector3(bx, 0.40, 0), Color(0.22, 0.20, 0.18))
	# Photo frames.
	for pz in [-0.5, 0.0, 0.5]:
		Chamber.make_prop_box(self, Vector3(0.04, 0.26, 0.20), Vector3(bx + 0.10, 0.95, pz), Color(0.74, 0.70, 0.62), false)
	# LED candles (four lit, one dark — Sato's).
	var lit := [true, true, false, true, true]
	for ci in 5:
		var cz := -0.7 + ci * 0.35
		Chamber.make_prop_box(self, Vector3(0.06, 0.14, 0.06), Vector3(bx + 0.35, 0.88, cz), Color(0.86, 0.84, 0.78), false)
		if lit[ci]:
			var flame := MeshInstance3D.new()
			var fq := SphereMesh.new()
			fq.radius = 0.03
			fq.height = 0.06
			flame.mesh = fq
			flame.position = Vector3(bx + 0.35, 0.97, cz)
			var flm := StandardMaterial3D.new()
			flm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			flm.albedo_color = Color(1.0, 0.78, 0.42)
			flm.emission_enabled = true
			flm.emission = Color(1.0, 0.72, 0.36)
			flm.emission_energy_multiplier = 2.4
			flame.material_override = flm
			add_child(flame)
	ActUtil.add_omni(self, Vector3(bx + 0.4, 1.1, 0), Color(1.0, 0.74, 0.40), 0.9, 3.0, false)
	# The plaque.
	var plaque := Chamber.make_prop_box(self, Vector3(0.05, 0.4, 1.2), Vector3(bx - 0.30, 1.5, 0), Color(0.45, 0.37, 0.22))
	Interactable.attach(plaque, "Read the memorial", "examine_only", {
		"text": "A memorial the crew built by the window.  Five candles; four still lit.  Names etched in the panel:  OKAFOR.  PARK.  HARGROVE.  SATO.  And one more, added later in your own handwriting:  ELI VOSS - my brother - I looked away.  You do not remember writing that line.  Sato's candle keeps going out on its own.",
		"duration": 11.0,
	})


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_mess")
