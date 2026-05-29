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
# Phase model (driven by % of boss_max):
#   P0 100-75%  patterns: cycle the four base attacks. Learn the tells.
#   P1  75-57%  roots:    + TENDRIL attack, + 1 lurker on the columns.
#   P2  57-39%  chorus:   SWEEPs are pre-marked by a crew voice 2.5s ahead.
#   P3  39-14%  rooted:   boss stops turning to face you;
#                         hits to the back of the heart core deal +50% damage.
#   P4 <=14%    mercy:    boss kneels, asks for sleep in Kael's voice.
#                         3s window: lay the gun down -> MERCY ending.
#                         Ignore -> fight resumes; window doesn't return.
const BOSS_HP_TOTAL := 280
const BOSS_DMG_PER_SHOT := 8
var boss_hp := BOSS_HP_TOTAL
var boss_max := BOSS_HP_TOTAL
var gun_node: Node = null
var _phase := 0
var _atk_index := 0
var _breath_tw: Tween = null
var _hunter_pts := [Vector3(-7, 0, 3), Vector3(7, 0, 3), Vector3(7, 0, -3), Vector3(-7, 0, -3)]
var _attacks_paused := false
var _mercy_panel: IntercomPanel = null
var _mercy_drop: StaticBody3D = null
var _mercy_timer: SceneTreeTimer = null
var _mercy_offered := false


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
	_schedule_attack()


func _process(_dt: float) -> void:
	# The boss slowly turns to face you - it is always looking. Once it roots
	# (P3+) the rotation freezes, so getting behind the heart core is finally
	# a real choice the player can make.
	if chosen or boss_root == null or GameState.player == null:
		return
	if _phase >= 3:
		return
	var pp: Vector3 = GameState.player.global_position
	var to := Vector3(pp.x, boss_root.global_position.y, pp.z) - boss_root.global_position
	if to.length() > 0.5:
		boss_root.rotation.y = lerp_angle(boss_root.rotation.y, atan2(to.x, to.z), _dt * 0.9)


# --- Arena ----------------------------------------------------------------

func _build_arena() -> void:
	Chamber.add_room(self, 28, 26, 11.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 13.0, "gap": 0.0}])
	Chamber.invis_wall(self, "z", 13, 0)
	# Cover columns flanking the arena - none between you and the boss.
	for cp in [Vector3(-9, 0, 5), Vector3(9, 0, 5), Vector3(-9, 0, -1), Vector3(9, 0, -1), Vector3(-6, 0, 9), Vector3(6, 0, 9)]:
		Chamber.make_prop_box(self, Vector3(1.2, 11.0, 1.2), cp + Vector3(0, 5.5, 0), ICE, true, "ice")
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
	_breath_tw = boss_root.create_tween().set_loops()
	_breath_tw.tween_property(boss_root, "scale", Vector3.ONE * 1.03, 1.4).set_trans(Tween.TRANS_SINE)
	_breath_tw.tween_property(boss_root, "scale", Vector3.ONE * 0.98, 1.6).set_trans(Tween.TRANS_SINE)
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
	# P3+ rewards mobility: hits to the back of the heart core deal +50%.
	var dmg := BOSS_DMG_PER_SHOT
	if _phase >= 3 and boss_root and GameState.player:
		var to_player := GameState.player.global_position - boss_root.global_position
		to_player.y = 0.0
		var forward := Vector3(sin(boss_root.rotation.y), 0.0, cos(boss_root.rotation.y))
		if to_player.length() > 0.1 and to_player.normalized().dot(forward) < -0.2:
			dmg = int(round(BOSS_DMG_PER_SHOT * 1.5))
	boss_hp -= dmg
	_flash_heart()
	AudioManager.whisper()
	var frac := float(boss_hp) / float(boss_max)
	# Cascade gates so a single big-damage shot can step through more than one.
	if _phase == 0 and frac <= 0.75:
		_phase = 1
		_enter_phase_1()
	if _phase == 1 and frac <= 0.57:
		_phase = 2
		_enter_phase_2()
	if _phase == 2 and frac <= 0.39:
		_phase = 3
		_enter_phase_3()
	if _phase == 3 and frac <= 0.14:
		_phase = 4
		_enter_mercy()
	if boss_hp <= 0:
		_boss_death()


func _roar() -> void:
	AudioManager.shape_sting()
	ScareDirector.scare_flash()


func _enter_phase_1() -> void:
	# Roots: tendrils enter the attack pool; one lurker creeps the columns.
	_roar()
	ScareDirector.do_blackout(0.3)
	var lurker_pts := [Vector3(-9, 0, 5), Vector3(9, 0, 5), Vector3(-9, 0, -1), Vector3(9, 0, -1)]
	var lurker := HorrorShape.create(HorrorShape.KIND_YUNA, lurker_pts[0], 0.0)
	lurker.set_lurk(lurker_pts, 0.55)
	add_child(lurker)
	ShapeTracker.register(lurker)


func _enter_phase_2() -> void:
	# Chorus: the entity speaks from the spots the SWEEP will land 2.5s later.
	_roar()
	_spawn_hunter(Vector3(-6, 0, -3))
	_spawn_hunter(Vector3(6, 0, -3))


func _enter_phase_3() -> void:
	# Rooted: boss freezes its rotation (handled in _process) and tendrils
	# leave longer-lived slow-zones (handled in _tendril). One more hunter.
	_roar()
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


# --- Telegraphed attacks (rotate through four) ----------------------------

func _schedule_attack() -> void:
	if chosen or _attacks_paused:
		return
	get_tree().create_timer(randf_range(3.2, 4.6)).timeout.connect(_do_attack)


func _do_attack() -> void:
	if chosen or _attacks_paused:
		return
	if GameState.player == null:
		_schedule_attack()
		return
	var pp: Vector3 = GameState.player.global_position
	_boss_tell()
	# P0 cycles the four base attacks; P1+ adds TENDRIL to the rotation.
	var pool := 4 if _phase == 0 else 5
	match _atk_index % pool:
		0:
			_aoe(pp, 2.6, 30.0, 1.3, Color(0.9, 0.1, 0.05))            # SLAM
		1:
			_spit_glob(pp)
			_aoe(pp, 2.1, 22.0, 1.5, Color(0.2, 0.9, 0.4))             # SPIT
		2:
			_aoe(pp, 3.3, 38.0, 0.95, Color(0.95, 0.45, 0.1))          # LUNGE
		3:
			var bp := boss_root.global_position if boss_root else Vector3.ZERO
			var dir := pp - bp
			dir.y = 0.0
			var c := bp + (dir.normalized() * 4.5 if dir.length() > 0.1 else Vector3(0, 0, 4.5))
			# P2+: a crew voice calls from where the sweep will land - audio is
			# now the dodge cue. The label is up for ~2.9s; the AoE windup is
			# 1.2s after a 1.3s pre-mark delay.
			if _phase >= 2:
				ChorusEmitter.speak_at(self, c)
				get_tree().create_timer(1.3).timeout.connect(
					func(): _aoe(c, 4.6, 26.0, 1.2, Color(0.9, 0.2, 0.5))
				)
			else:
				_aoe(c, 4.6, 26.0, 1.2, Color(0.9, 0.2, 0.5))          # SWEEP
		_:
			_tendril(pp)                                               # TENDRIL
	_atk_index += 1


# Telegraphed circular floor-rise around the player. Lower damage than SLAM,
# but the zone PERSISTS as a slow-zone for several seconds afterwards - the
# pressure is positional, not raw damage. P3+ leaves a longer-lived zone.
func _tendril(target: Vector3) -> void:
	var persist: float = (6.0 if _phase >= 3 else 4.0)
	_aoe(target, 1.8, 18.0, 0.9, Color(0.35, 0.85, 0.55))
	# Aftermath slow-zone: a fading decal that ticks if the player loiters in it.
	var zone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.8
	cm.bottom_radius = 1.8
	cm.height = 0.04
	cm.radial_segments = 24
	zone.mesh = cm
	zone.position = Vector3(target.x, 0.04, target.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.55, 0.42, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.70, 0.55)
	mat.emission_energy_multiplier = 0.9
	zone.material_override = mat
	get_tree().create_timer(0.9).timeout.connect(
		func(): _spawn_slow_zone(zone, mat, target, persist)
	)


func _spawn_slow_zone(zone: MeshInstance3D, mat: StandardMaterial3D, center: Vector3, persist: float) -> void:
	if chosen:
		return
	add_child(zone)
	var ticks := int(persist / 0.7)
	for i in ticks:
		get_tree().create_timer(0.7 * (i + 1)).timeout.connect(
			func():
				if chosen or GameState.player == null:
					return
				var pp: Vector3 = GameState.player.global_position
				if Vector2(pp.x - center.x, pp.z - center.z).length() <= 1.8:
					if GameState.player.has_method("take_damage"):
						GameState.player.take_damage(4.0)
		)
	var ft := create_tween()
	ft.tween_property(mat, "emission_energy_multiplier", 0.0, persist)
	ft.parallel().tween_property(mat, "albedo_color:a", 0.0, persist)
	ft.tween_callback(zone.queue_free)


func _boss_tell() -> void:
	AudioManager.groan()
	if heart_core:
		var m := heart_core.material_override as StandardMaterial3D
		if m:
			m.emission_energy_multiplier = 5.0
			create_tween().tween_property(m, "emission_energy_multiplier", 2.6, 0.5)


func _spit_glob(target: Vector3) -> void:
	if boss_root == null:
		return
	var glob := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	glob.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.4)
	mat.emission_energy_multiplier = 2.0
	glob.material_override = mat
	add_child(glob)
	glob.global_position = boss_root.global_position + Vector3(0, 4.0, 1.0)
	var t := create_tween()
	t.tween_property(glob, "global_position", Vector3(target.x, 0.5, target.z), 1.4)
	t.tween_callback(glob.queue_free)


func _aoe(center: Vector3, radius: float, damage: float, windup: float, col: Color) -> void:
	var zone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.06
	cm.radial_segments = 24
	zone.mesh = cm
	zone.position = Vector3(center.x, 0.06, center.z)
	zone.scale = Vector3(0.15, 1, 0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.2
	zone.material_override = mat
	add_child(zone)
	var t := create_tween()
	t.tween_property(zone, "scale", Vector3.ONE, windup).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(mat, "emission_energy_multiplier", 2.8, windup)
	t.tween_callback(_strike_aoe.bind(center, radius, damage, zone, mat))


func _strike_aoe(center: Vector3, radius: float, damage: float, zone: MeshInstance3D, mat: StandardMaterial3D) -> void:
	AudioManager.boom()
	if is_instance_valid(mat):
		mat.emission = Color(1, 1, 0.8)
		mat.emission_energy_multiplier = 6.0
	if is_instance_valid(zone):
		var ft := create_tween()
		ft.tween_interval(0.12)
		ft.tween_callback(zone.queue_free)
	if not chosen and GameState.player:
		var pp: Vector3 = GameState.player.global_position
		if Vector2(pp.x - center.x, pp.z - center.z).length() <= radius + 0.4:
			if GameState.player.has_method("take_damage"):
				GameState.player.take_damage(damage)
	_schedule_attack()


func _boss_death() -> void:
	if chosen:
		return
	chosen = true
	GameState.push_modal()
	ScareDirector.scare_flash()
	AudioManager.boom()
	if _breath_tw and _breath_tw.is_valid():
		_breath_tw.kill()
	if heart_core:
		var m := heart_core.material_override as StandardMaterial3D
		if m:
			var t := create_tween()
			t.tween_property(m, "emission_energy_multiplier", 11.0, 0.4)
			t.tween_property(m, "emission_energy_multiplier", 0.0, 1.8)
	if boss_root:
		var bt := boss_root.create_tween()
		bt.tween_property(boss_root, "scale", Vector3(1.2, 0.35, 1.2), 2.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	get_tree().create_timer(1.7).timeout.connect(AudioManager.groan)
	get_tree().create_timer(3.4).timeout.connect(_go.bind("burn"))


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


# P4: the boss collapses to its knees, exposes its heart core, and asks for
# sleep in Kael's voice. The window is the duration of the line + 3.0s after.
# Dropping the gun via the interactable -> MERCY ending. Ignoring -> fight
# resumes; the window does not return, and BURN is still reachable by killing.
func _enter_mercy() -> void:
	if _mercy_offered:
		return
	_mercy_offered = true
	_attacks_paused = true
	_roar()
	# Kneel: squish vertically and drop the boss a touch.
	if boss_root:
		var kt := boss_root.create_tween()
		kt.tween_property(boss_root, "scale", Vector3(1.05, 0.78, 1.05), 1.6).set_trans(Tween.TRANS_SINE)
	# Hide a panel inside the boss model so the OlenManager has something to
	# light up for set_speaking; the player only ever sees the subtitle bar.
	_mercy_panel = IntercomPanel.create(Vector3(0, 4.0, -8.5), 0.0)
	add_child(_mercy_panel)
	_mercy_panel.visible = false
	# Floor pedestal in front of the boss with a "lay it down" prompt.
	_mercy_drop = Chamber.make_prop_box(self, Vector3(0.8, 0.3, 0.8), Vector3(0, 0.15, -5.0), Color(0.08, 0.12, 0.16))
	Interactable.attach(_mercy_drop, "Lay the gun down.", "trigger_event", {"callback": Callable(self, "_mercy_drop_gun")})
	# Kneel + sting first, then the line - then the 3.0s "do nothing" timer
	# arms only after the line has finished streaming.
	get_tree().create_timer(1.0).timeout.connect(
		func(): OlenManager.play_boss_mercy(_mercy_panel, Callable(self, "_arm_mercy_timeout"))
	)


func _arm_mercy_timeout() -> void:
	_mercy_timer = get_tree().create_timer(3.0)
	_mercy_timer.timeout.connect(_mercy_timeout)


func _mercy_drop_gun() -> void:
	if chosen:
		return
	chosen = true
	if _mercy_drop and is_instance_valid(_mercy_drop):
		_mercy_drop.queue_free()
		_mercy_drop = null
	_go("mercy")


func _mercy_timeout() -> void:
	if chosen:
		return
	# Player didn't lay it down. Tear down the prompt, resume the fight.
	if _mercy_drop and is_instance_valid(_mercy_drop):
		_mercy_drop.queue_free()
		_mercy_drop = null
	_attacks_paused = false
	# Boss un-kneels (still hurt - keeps a slight squish - but back in the fight).
	if boss_root:
		var ut := boss_root.create_tween()
		ut.tween_property(boss_root, "scale", Vector3(1.0, 0.94, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	_schedule_attack()


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
