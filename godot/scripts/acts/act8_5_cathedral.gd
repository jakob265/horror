extends Node3D
# VESPER - ACT 8.5: THE BONE CATHEDRAL
# Held-breath beat between the caves and the sealed chamber. No enemies, no
# puzzles, no notes - just the moment the player understands the SCALE of
# what they're walking into. Tallest room in the game by design.

const FLOOR := Color(0.06, 0.10, 0.14)
const CEIL := Color(0.04, 0.07, 0.10)
const WALL := Color(0.10, 0.16, 0.18)
const ICE := Color(0.40, 0.54, 0.66)
const NEST := Color(0.14, 0.50, 0.40)

var crossed := false


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_chamber()
	# Lowest haunt setting we use - the air should feel WAITING, not chased.
	ActUtil.haunt(self, {"intensity": 0.45, "flicker": true, "flicker_rate": 0.45})
	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 9.0)
		GameState.player.rotation_degrees.y = 0.0


func _process(_dt: float) -> void:
	if crossed:
		return
	if GameState.player and GameState.player.global_position.z < -9.0:
		crossed = true
		SceneRouter.transition_to("act9")


func _build_chamber() -> void:
	# The tallest room in the game. The player should look up.
	Chamber.add_room(self, 20, 20, 14.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 10.0, "gap": 0.0}, {"axis": "z", "fixed": -10.0, "gap": 0.0}])
	# Block backtracking + falling out the entry doorway.
	Chamber.invis_wall(self, "z", 10, 0)

	# Eight grown-filament columns, arranged in two rows so the player walks
	# between them - a real cathedral nave.
	for px in [-6.0, -2.0, 2.0, 6.0]:
		for pz in [-5.0, 5.0]:
			_grown_pillar(Vector3(px, 0, pz))

	# Six pools of signal_growth on the floor, pulsing in sequence (they share
	# the tween system inside ActUtil.signal_growth - the offset is visual).
	var pool_positions := [
		Vector3(-7.0, 0, 0.0), Vector3(7.0, 0, 0.0),
		Vector3(-4.0, 0, 2.5), Vector3(4.0, 0, -2.5),
		Vector3(0.0, 0, 6.5), Vector3(0.0, 0, -6.5),
	]
	for pp in pool_positions:
		ActUtil.signal_growth(self, pp, 1.6, Color(0.10, 0.42, 0.34))

	# The crew. Six cocooned bodies hanging from the dark ceiling at varying
	# heights. The player should walk under them.
	var hang_positions := [
		[Vector3(-5.5, 12.5, 3.0), 4.2],
		[Vector3(5.5, 12.5, 3.0), 4.6],
		[Vector3(-3.0, 13.0, -3.0), 5.2],
		[Vector3(3.0, 13.0, -3.0), 4.8],
		[Vector3(0.0, 13.5, 0.5), 5.8],
		[Vector3(0.0, 12.5, -6.5), 5.0],
	]
	for entry in hang_positions:
		ActUtil.hanging_corpse(self, entry[0], entry[1])

	# A grown altar at the back, between the pools - the visual sink for the
	# room. The exit doorway frames it.
	Chamber.make_prop_box(self, Vector3(3.0, 1.4, 2.0), Vector3(0, 0.7, -7.5), Color(0.08, 0.16, 0.12))
	ActUtil.signal_growth(self, Vector3(0, 1.4, -7.5), 2.0, Color(0.14, 0.55, 0.42))

	# Two accent omnis low to the floor so the pools glow up onto the cocoons.
	ActUtil.add_omni(self, Vector3(-6, 0.3, 0), Color(0.18, 0.62, 0.50), 1.5, 10.0, false)
	ActUtil.add_omni(self, Vector3(6, 0.3, 0), Color(0.18, 0.62, 0.50), 1.5, 10.0, false)

	# A scrawl over the exit doorway - what Kael saw, what the player is about
	# to face. No yelling, no warning. Just the truth.
	ActUtil.wall_scrawl(self, "WE ARE HERE", Vector3(0, 4.0, -9.85), 0.0, 32, Color(0.40, 0.62, 0.55))

	# A thick haze so the columns disappear into the ceiling.
	ActUtil.add_dust_motes(self, Vector3(0, 6, 0), Vector3(10, 6, 10), 140, Color(0.6, 0.78, 0.86, 0.12))


func _grown_pillar(base: Vector3) -> void:
	# A 12 m vertical column of grown filament: tapered cylinder + cluster
	# of small signal_growth nodes at the base + emissive trim halfway up.
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.25
	cm.bottom_radius = 0.55
	cm.height = 12.0
	cm.radial_segments = 8
	col.mesh = cm
	col.position = base + Vector3(0, 6.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.10, 0.09)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.50, 0.40)
	mat.emission_energy_multiplier = 0.18
	mat.roughness = 0.6
	col.material_override = mat
	add_child(col)
	ActUtil.signal_growth(self, base + Vector3(0, 0, 0), 0.9, Color(0.10, 0.42, 0.34))
