extends Node3D
# VESPER - ACT 10: THE ARENA
# A boss fight. Grab the bolt gun, then kill the towering thing the nest grew
# into - shoot it (it dims and roars as it dies) while you gun down the crew it
# sends. Killing it is the destroy ending. A console at the entrance lets you
# lay the gun down and succumb instead.

const WALL := Color(0.26, 0.34, 0.44)
const FLOOR := Color(0.32, 0.40, 0.50)
const CEIL := Color(0.08, 0.12, 0.18)
const ICE := Color(0.48, 0.60, 0.74)
const FLESH := Color(0.05, 0.08, 0.07)
const NEST := Color(0.16, 0.55, 0.42)

var chosen := false
var boss_root: Node3D = null
var heart_core: MeshInstance3D = null
var boss_hp := 160
var boss_max := 160
var gun_node: Node = null
var _phase := 0
var _hunter_pts := [Vector3(-7, 0, 3), Vector3(7, 0, 3), Vector3(7, 0, -3), Vector3(-7, 0, -3)]


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_arena()
	_build_boss()
	_spawn_hunter(Vector3(-6, 0, -2))
	_spawn_hunter(Vector3(6, 0, -2))
	ActUtil.haunt(self, {"intensity": 1.0, "flicker": true, "flicker_rate": 0.8})
	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 10.5)
		GameState.player.rotation_degrees.y = 0.0


# --- Arena ----------------------------------------------------------------

func _build_arena() -> void:
	Chamber.add_room(self, 28, 26, 11.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 13.0, "gap": 0.0}])
	# Ring of cover columns to break the hunters' sightlines.
	for a in 8:
		var ang: float = a * TAU / 8.0
		Chamber.make_prop_box(self, Vector3(1.2, 11.0, 1.2), Vector3(cos(ang) * 8.0, 5.5, sin(ang) * 7.0), ICE, true, "ice")
	# Gun pickup at the entrance.
	Chamber.make_prop_box(self, Vector3(1.0, 0.8, 0.8), Vector3(0, 0.4, 11.0), Color(0.30, 0.32, 0.36))
	gun_node = StaticBody3D.new()
	gun_node.position = Vector3(0, 0.95, 11.0)
	gun_node.add_child(_mesh_box(Vector3(0.46, 0.15, 0.15), Vector3.ZERO, Color(0.2, 0.2, 0.24), Color(0.4, 0.65, 0.95), 0.8))
	var gcol := CollisionShape3D.new()
	var gcs := BoxShape3D.new()
	gcs.size = Vector3(0.46, 0.15, 0.15)
	gcol.shape = gcs
	gun_node.add_child(gcol)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.5, 0.7, 0.95)
	gl.light_energy = 1.2
	gl.omni_range = 2.8
	gl.shadow_enabled = false
	gun_node.add_child(gl)
	add_child(gun_node)
	Interactable.attach(gun_node, "Take the bolt gun", "trigger_event", {"callback": Callable(self, "_give_gun")})
	# Succumb console at the entrance corner.
	var give := Chamber.make_prop_box(self, Vector3(0.9, 1.0, 0.7), Vector3(-6, 0.5, 11.5), Color(0.06, 0.10, 0.09))
	Interactable.attach(give, "Lay the gun down. Stay.", "trigger_event", {"callback": Callable(self, "_succumb")})
	ActUtil.wall_label(self, "SUCCUMB", Vector3(-6, 1.9, 11.5), 14, Color(0.6, 0.85, 0.7))
	ActUtil.corpse(self, Vector3(-9, 0, 8), 200.0, true, Color(0.32, 0.40, 0.48))
	ActUtil.corpse(self, Vector3(9, 0, 9), 30.0, true, Color(0.30, 0.36, 0.44))
	ActUtil.wall_scrawl(self, "KILL IT", Vector3(0, 3.6, 12.85), 180.0, 40, Color(0.5, 0.05, 0.06))
	ActUtil.add_dust_motes(self, Vector3(0, 3, 0), Vector3(14, 4, 13), 110, Color(0.7, 0.84, 0.95, 0.14))


# --- The boss -------------------------------------------------------------

func _build_boss() -> void:
	boss_root = Node3D.new()
	boss_root.position = Vector3(0, 0, -9.0)
	add_child(boss_root)
	_blob(Vector3(4.4, 3.6, 4.0), Vector3(0, 1.8, 0))
	_blob(Vector3(3.6, 3.2, 3.2), Vector3(0, 4.2, 0.3))
	_blob(Vector3(2.6, 2.4, 2.4), Vector3(0, 6.3, 0.5))
	heart_core = _emit_box(Vector3(1.3, 1.8, 0.7), Vector3(0, 3.8, 1.9), Color(0.12, 0.6, 0.45), NEST, 2.6)
	_emit_box(Vector3(1.3, 1.1, 0.5), Vector3(0, 6.0, 1.7), Color(0.04, 0, 0), Color(0.7, 0.06, 0.05), 1.8)
	for ep in [Vector3(-0.65, 6.7, 1.4), Vector3(0.65, 6.7, 1.4), Vector3(0, 7.2, 1.2), Vector3(-0.32, 6.3, 1.6), Vector3(0.38, 6.35, 1.6), Vector3(0, 6.0, 1.5)]:
		_emit_sphere(0.13, ep, Color(0.95, 0.12, 0.07), 5.5)
	_limb(Vector3(-2.1, 3.4, 1.0), 5.0, -55, -22)
	_limb(Vector3(2.1, 3.4, 1.0), 5.0, -55, 22)
	_limb(Vector3(-2.7, 1.8, 0.4), 4.4, -80, -32)
	_limb(Vector3(2.7, 1.8, 0.4), 4.4, -80, 32)
	for sp in [Vector3(-1.3, 5.2, -1.2), Vector3(1.3, 5.4, -1.2), Vector3(0, 7.0, -0.8), Vector3(-2.0, 3.6, -1.4), Vector3(2.0, 3.7, -1.4)]:
		_big_shard(sp)
	ActUtil.signal_growth(self, Vector3(0, 0, -9.0), 4.0, Color(0.07, 0.13, 0.11))
	ActUtil.add_omni(self, Vector3(0, 4.0, -7.0), Color(0.2, 0.7, 0.55), 1.8, 14.0, false)
	var br := boss_root.create_tween().set_loops()
	br.tween_property(boss_root, "scale", Vector3.ONE * 1.03, 1.4).set_trans(Tween.TRANS_SINE)
	br.tween_property(boss_root, "scale", Vector3.ONE * 0.98, 1.6).set_trans(Tween.TRANS_SINE)
	var boss := StaticBody3D.new()
	boss.position = Vector3(0, 3.8, 0.8)
	var bc := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.8, 7.4, 3.6)
	bc.shape = bs
	boss.add_child(bc)
	boss.set_meta("on_shot", Callable(self, "_boss_hit"))
	boss_root.add_child(boss)


func _blob(size: Vector3, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 20
	sm.rings = 12
	mi.mesh = sm
	mi.scale = size
	mi.position = pos
	mi.material_override = _flesh_mat()
	boss_root.add_child(mi)


func _emit_box(size: Vector3, pos: Vector3, color: Color, emit: Color, e: float) -> MeshInstance3D:
	var m := _mesh_box(size, pos, color, emit, e)
	boss_root.add_child(m)
	return m


func _emit_sphere(radius: float, pos: Vector3, color: Color, e: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = e
	mi.material_override = mat
	boss_root.add_child(mi)


func _limb(base: Vector3, length: float, pitch: float, yaw: float) -> void:
	var piv := Node3D.new()
	piv.position = base
	piv.rotation_degrees = Vector3(pitch, yaw, 0)
	boss_root.add_child(piv)
	var seg := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = length
	cap.radial_segments = 8
	seg.mesh = cap
	seg.position = Vector3(0, -length / 2.0, 0)
	seg.material_override = _flesh_mat()
	piv.add_child(seg)
	var claw := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.01
	cm.bottom_radius = 0.18
	cm.height = 0.8
	cm.radial_segments = 6
	claw.mesh = cm
	claw.position = Vector3(0, -length, 0)
	var clm := StandardMaterial3D.new()
	clm.albedo_color = Color(0.05, 0.08, 0.11)
	clm.emission_enabled = true
	clm.emission = Color(0.28, 0.5, 0.66)
	clm.emission_energy_multiplier = 0.3
	claw.material_override = clm
	piv.add_child(claw)
	var sw := piv.create_tween().set_loops()
	sw.tween_property(piv, "rotation_degrees", Vector3(pitch + 8, yaw + 7, 0), randf_range(2.2, 3.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sw.tween_property(piv, "rotation_degrees", Vector3(pitch - 7, yaw - 7, 0), randf_range(2.2, 3.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _big_shard(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.02
	c.bottom_radius = 0.35
	c.height = 2.5
	c.radial_segments = 6
	mi.mesh = c
	mi.position = pos
	mi.rotation_degrees = Vector3(randf_range(-30, -10), randf_range(0, 360), randf_range(-20, 20))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.09, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.28, 0.5, 0.66)
	mat.emission_energy_multiplier = 0.25
	mi.material_override = mat
	boss_root.add_child(mi)


func _flesh_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = FLESH
	m.roughness = 0.7
	m.emission_enabled = true
	m.emission = NEST
	m.emission_energy_multiplier = 0.06
	return m


func _mesh_box(size: Vector3, pos: Vector3, color: Color, emit: Color, emit_e: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = color
	if emit_e > 0.0:
		mat.emission_enabled = true
		mat.emission = emit
		mat.emission_energy_multiplier = emit_e
	m.material_override = mat
	return m


# --- Fight logic ----------------------------------------------------------

func _spawn_hunter(pos: Vector3) -> void:
	var kinds := [HorrorShape.KIND_HARGROVE, HorrorShape.KIND_FELIX, HorrorShape.KIND_YUNA]
	var s := HorrorShape.create(kinds[randi() % 3], pos, 0.0)
	s.set_stalk(_hunter_pts, 1.2, 3.6)
	add_child(s)
	ShapeTracker.register(s)


func _boss_hit() -> void:
	if chosen:
		return
	boss_hp -= 8
	_flash_heart()
	AudioManager.whisper()
	var frac := float(boss_hp) / float(boss_max)
	if _phase == 0 and frac <= 0.66:
		_phase = 1
		_roar()
	elif _phase == 1 and frac <= 0.33:
		_phase = 2
		_roar()
	if boss_hp <= 0:
		_strike("burn")


func _roar() -> void:
	AudioManager.shape_sting()
	ScareDirector.scare_flash()
	_spawn_hunter(Vector3(randf_range(-6, 6), 0, -4))


func _flash_heart() -> void:
	if heart_core == null:
		return
	var m := heart_core.material_override as StandardMaterial3D
	if m == null:
		return
	var base := clampf(float(boss_hp) / float(boss_max), 0.15, 1.0)
	m.emission_energy_multiplier = 5.5
	create_tween().tween_property(m, "emission_energy_multiplier", 2.6 * base, 0.18)


func _give_gun() -> void:
	if GameState.player and GameState.player.has_method("equip_gun"):
		GameState.player.equip_gun(80)
	if gun_node and is_instance_valid(gun_node):
		gun_node.queue_free()
		gun_node = null
	InteractionManager.show_examine("A bolt gun, eighty rounds. Put them in the thing. [Left click] to fire.", 4.5)


func _succumb() -> void:
	if chosen:
		return
	chosen = true
	_go("succumb")


func _strike(which: String) -> void:
	if chosen:
		return
	chosen = true
	GameState.push_modal()
	ScareDirector.scare_flash()
	AudioManager.shape_sting()
	if heart_core:
		var m := heart_core.material_override as StandardMaterial3D
		if m:
			var t := create_tween()
			t.tween_property(m, "emission_energy_multiplier", 8.0, 0.2)
			t.tween_property(m, "emission_energy_multiplier", 0.0, 1.1)
	get_tree().create_timer(1.6).timeout.connect(_go.bind(which))


func _go(which: String) -> void:
	GameState.modal_count = 0
	var main := get_tree().root.get_node_or_null("Main")
	if main and main.has_method("start_ending"):
		main.start_ending(which)
