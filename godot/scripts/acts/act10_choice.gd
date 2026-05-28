extends Node3D
# VESPER - ACT 10: THE HEART
# The chamber wakes the moment you enter. The crew - fast now - hunt you while
# you cross to one of three stations and strike: SEAL the shaft, BURN the nest,
# or SUCCUMB. SEAL/BURN are the killing blow (a beat, then the ending); SUCCUMB
# is letting it take you. The pulsing heart at the centre is the thing itself.

const WALL := Color(0.28, 0.38, 0.48)
const FLOOR := Color(0.34, 0.42, 0.52)
const CEIL := Color(0.10, 0.14, 0.20)
const ICE := Color(0.50, 0.62, 0.76)

var chosen := false
var heart: Node3D = null
var heart_core: MeshInstance3D = null
var boss_hp := 120
var gun_node: Node = null


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_chamber()

	# The crew wake with the chamber and hunt.
	for cfg in [
		{"pos": Vector3(-5, 0, -5), "kind": HorrorShape.KIND_HARGROVE, "pts": [Vector3(-6, 0, 2), Vector3(6, 0, 2), Vector3(0, 0, -6)]},
		{"pos": Vector3(5, 0, -5), "kind": HorrorShape.KIND_FELIX, "pts": [Vector3(6, 0, -2), Vector3(-6, 0, -2), Vector3(0, 0, 4)]},
	]:
		var s := HorrorShape.create(cfg["kind"], cfg["pos"], 0.0)
		s.set_stalk(cfg["pts"], 1.2, 3.6)
		add_child(s)
		ShapeTracker.register(s)

	ActUtil.haunt(self, {"intensity": 0.95, "flicker": true, "flicker_rate": 0.7})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 6.5)
		GameState.player.rotation_degrees.y = 0.0


func _build_chamber() -> void:
	Chamber.add_room(self, 18, 16, 6.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 8.0, "gap": 0.0}])

	# The heart: a grown pillar with a glowing core, breathing.
	heart = Node3D.new()
	heart.position = Vector3(0, 0, -4.0)
	add_child(heart)
	heart.add_child(_mesh_box(Vector3(2.2, 6.0, 2.2), Vector3(0, 3.0, 0), Color(0.04, 0.08, 0.07), Color(0, 0, 0), 0.0))
	heart_core = _mesh_box(Vector3(0.9, 1.6, 0.9), Vector3(0, 1.8, 0), Color(0.10, 0.5, 0.4), Color(0.16, 0.85, 0.6), 1.6)
	heart.add_child(heart_core)
	ActUtil.signal_growth(self, Vector3(0, 0, -4.0), 3.0, Color(0.07, 0.13, 0.11))
	ActUtil.add_omni(self, Vector3(0, 2.6, -4.0), Color(0.2, 0.7, 0.55), 1.3, 8.0, false)
	var pulse := heart.create_tween().set_loops()
	pulse.tween_property(heart, "scale", Vector3.ONE * 1.07, 1.1).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(heart, "scale", Vector3.ONE * 0.95, 1.3).set_trans(Tween.TRANS_SINE)
	# The heart is the boss: shoot it. A collider carries the on_shot callback.
	var boss := StaticBody3D.new()
	boss.position = Vector3(0, 1.8, -4.0)
	var bcol := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.3, 2.4, 1.3)
	bcol.shape = bs
	boss.add_child(bcol)
	boss.set_meta("on_shot", Callable(self, "_boss_hit"))
	add_child(boss)

	# A bolt gun on a crate by the entrance - take it for the fight.
	Chamber.make_prop_box(self, Vector3(0.9, 0.8, 0.7), Vector3(0, 0.4, 5.6), Color(0.30, 0.32, 0.36))
	gun_node = StaticBody3D.new()
	gun_node.position = Vector3(0, 0.95, 5.6)
	var gmesh := _mesh_box(Vector3(0.42, 0.14, 0.14), Vector3.ZERO, Color(0.20, 0.20, 0.24), Color(0.4, 0.65, 0.95), 0.7)
	gun_node.add_child(gmesh)
	var gcol := CollisionShape3D.new()
	var gcs := BoxShape3D.new()
	gcs.size = Vector3(0.42, 0.14, 0.14)
	gcol.shape = gcs
	gun_node.add_child(gcol)
	var glamp := OmniLight3D.new()
	glamp.light_color = Color(0.5, 0.7, 0.95)
	glamp.light_energy = 1.1
	glamp.omni_range = 2.6
	glamp.shadow_enabled = false
	gun_node.add_child(glamp)
	add_child(gun_node)
	Interactable.attach(gun_node, "Take the bolt gun", "trigger_event", {"callback": Callable(self, "_give_gun")})

	# Cover: ice columns + growth to break the hunters' sightlines.
	for cp in [Vector3(-5, 0, 1), Vector3(5, 0, 1), Vector3(-4, 0, -5), Vector3(4, 0, -5), Vector3(0, 0, 3)]:
		Chamber.make_prop_box(self, Vector3(1.0, 6.0, 1.0), cp + Vector3(0, 3, 0), ICE, true, "ice")
	for gp in [Vector3(-6, 0, -3), Vector3(6, 0, -3), Vector3(-2, 0, 5)]:
		ActUtil.signal_growth(self, gp, randf_range(1.2, 2.0), Color(0.06, 0.12, 0.10))
	for hp in [Vector3(-3, 4.6, -2), Vector3(3, 4.6, -2), Vector3(0, 4.6, -6)]:
		ActUtil.hanging_corpse(self, hp, randf_range(1.8, 2.4), Color(0.30, 0.38, 0.40))

	# SEAL - shaft charges (west): the no-fight way out.
	_station(Vector3(-7.5, 0, -1.0), Color(0.7, 0.18, 0.14), "Bring the shaft down", Callable(self, "_seal"), "SEAL")
	# SUCCUMB - the heart itself.
	var give := Chamber.make_prop_box(self, Vector3(1.0, 1.2, 1.0), Vector3(0, 0.6, -2.2), Color(0.06, 0.10, 0.09))
	Interactable.attach(give, "Put the lamp down. Stay.", "trigger_event", {"callback": Callable(self, "_succumb")})

	ActUtil.corpse(self, Vector3(-5, 0, 4), 200.0, true, Color(0.32, 0.40, 0.48))
	ActUtil.corpse(self, Vector3(4.5, 0, 5), 30.0, true, Color(0.30, 0.36, 0.44))
	ActUtil.wall_scrawl(self, "ONE OF THESE IS A DOOR", Vector3(0, 3.2, 7.85), 180.0, 26, Color(0.45, 0.06, 0.07))
	ActUtil.add_dust_motes(self, Vector3(0, 2.4, 0), Vector3(9, 3.5, 8), 90, Color(0.7, 0.84, 0.95, 0.14))


func _station(pos: Vector3, color: Color, prompt: String, cb: Callable, label: String) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(_mesh_box(Vector3(1.0, 1.2, 0.8), Vector3(0, 0.6, 0), Color(0.26, 0.28, 0.32), Color(0, 0, 0), 0.0))
	var beacon := _mesh_box(Vector3(0.3, 0.4, 0.2), Vector3(0, 1.35, 0), color, color.lightened(0.3), 2.0)
	body.add_child(beacon)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(1.0, 1.2, 0.8)
	shape.shape = col
	shape.position = Vector3(0, 0.6, 0)
	body.add_child(shape)
	var lamp := OmniLight3D.new()
	lamp.light_color = color.lightened(0.3)
	lamp.light_energy = 1.6
	lamp.omni_range = 4.0
	lamp.shadow_enabled = false
	lamp.position = Vector3(0, 1.6, 0)
	body.add_child(lamp)
	add_child(body)
	Interactable.attach(body, prompt, "trigger_event", {"callback": cb})
	ActUtil.wall_label(self, label, pos + Vector3(0, 2.1, 0), 18, color.lightened(0.3))


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


# --- The three resolutions -----------------------------------------------

func _give_gun() -> void:
	if GameState.player and GameState.player.has_method("equip_gun"):
		GameState.player.equip_gun(36)
	if gun_node and is_instance_valid(gun_node):
		gun_node.queue_free()
		gun_node = null
	InteractionManager.show_examine("A bolt gun, thirty-six rounds. Put them in the heart. [Left click] to fire.", 4.5)


func _boss_hit() -> void:
	if chosen:
		return
	boss_hp -= 8
	_flash_heart()
	AudioManager.whisper()
	if boss_hp <= 0:
		_strike("burn")


func _flash_heart() -> void:
	if heart_core == null:
		return
	var m := heart_core.material_override as StandardMaterial3D
	if m == null:
		return
	var base := clampf(float(boss_hp) / 120.0, 0.12, 1.0)
	m.emission_energy_multiplier = 4.5
	create_tween().tween_property(m, "emission_energy_multiplier", 1.6 * base, 0.18)


func _seal() -> void:
	_strike("seal")


func _succumb() -> void:
	if chosen:
		return
	chosen = true
	_go("succumb")


func _strike(which: String) -> void:
	# The killing blow: freeze the world, flash, kill the heart, then the ending.
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
			t.tween_property(m, "emission_energy_multiplier", 6.0, 0.2)
			t.tween_property(m, "emission_energy_multiplier", 0.0, 1.0)
	get_tree().create_timer(1.5).timeout.connect(_go.bind(which))


func _go(which: String) -> void:
	GameState.modal_count = 0
	var main := get_tree().root.get_node_or_null("Main")
	if main and main.has_method("start_ending"):
		main.start_ending(which)
