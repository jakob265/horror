class_name HorrorShape
extends Node3D
# Featureless humanoid silhouette. Felix / Yuna / Hargrove variants.

const KIND_FELIX := "felix"
const KIND_YUNA := "yuna"
const KIND_HARGROVE := "hargrove"

# Felix's "Amara" trigger fires at most once per session.
static var felix_amara_fired := false

var kind: String = KIND_FELIX
var crouched := false
var head_pivot: Node3D
var head: MeshInstance3D
var right_arm_pivot: Node3D
var right_arm: MeshInstance3D
var torso: MeshInstance3D
var stare_time := 0.0
var farewell_done := false

# --- Lurk / stalk behaviour ---
var peeking := false          # stands and stares; gone for good once looked at
var lurking := false
var lurk_points: Array = []
var _seen_t := 0.0
var _hidden := false
var _respawn_at := -1.0
var _creep_speed := 0.55

# --- Stalker behaviour (the hunter) ---
enum StalkState { PATROL, INVESTIGATE, CHASE, SEARCH }
var stalking := false
var stalk_points: Array = []
var patrol_speed := 1.15
var chase_speed := 3.9        # below a walk (4.5): you can back off, dash past, or hide
var sight_range := 8.0
var hear_range := 8.0
var _stalk_state: StalkState = StalkState.PATROL
var _stalk_target := Vector3.ZERO
var _last_known := Vector3.ZERO
var _patrol_idx := 0
var _state_t := 0.0
var _lost_t := 0.0
var _stung := false
var _agent: NavigationAgent3D = null
var _catch_t := 0.0
var _grace_t := 0.0
var _hp := 3
var _hitbox: Area3D = null


static func reset_session() -> void:
	felix_amara_fired = false


static func create(p_kind: String, position: Vector3, rotation_y: float, crouched: bool = false) -> HorrorShape:
	var s := HorrorShape.new()
	s.kind = p_kind
	s.crouched = crouched
	s.position = position
	s.rotation_degrees = Vector3(0, rotation_y, 0)
	s._build()
	return s


func _ready() -> void:
	_start_idle()
	_schedule_twitch()


func _start_idle() -> void:
	# Subtle breathing so it's never quite still.
	if torso == null or not is_instance_valid(torso):
		return
	var t := create_tween().set_loops()
	t.tween_property(torso, "scale", Vector3(1.05, 0.97, 1.05), randf_range(1.7, 2.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(torso, "scale", Vector3(0.96, 1.04, 0.96), randf_range(1.7, 2.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _schedule_twitch() -> void:
	if not is_inside_tree():
		return
	get_tree().create_timer(randf_range(2.0, 5.5)).timeout.connect(_twitch)


func _twitch() -> void:
	# A sudden, wrong snap of the head - more unsettling than smooth motion.
	if not is_instance_valid(self) or head_pivot == null:
		return
	var base := head_pivot.rotation_degrees
	var t := create_tween()
	t.tween_property(head_pivot, "rotation_degrees", base + Vector3(randf_range(-7, 7), randf_range(-16, 16), randf_range(-6, 6)), 0.05)
	t.tween_property(head_pivot, "rotation_degrees", base, 0.09)
	t.tween_callback(_schedule_twitch)


func _take_shot() -> void:
	if not stalking:
		return
	_hp -= 1
	AudioManager.whisper()
	var pl: Node = GameState.player
	if pl is Node3D:
		var away := global_position - (pl as Node3D).global_position
		away.y = 0.0
		if away.length() > 0.1:
			global_position += away.normalized() * 0.45
	if _hp <= 0:
		_die_shot()


func _die_shot() -> void:
	AudioManager.shape_sting()
	visible = false
	if _hitbox and is_instance_valid(_hitbox):
		_hitbox.queue_free()
		_hitbox = null
	queue_free()


func _build() -> void:
	# A tall, hunched thing wearing a person. Near-black so it reads as one
	# silhouette in the dark; the nest glows sickly through cracks in it and
	# ice-shards erupt from its back. Bright eyes are the only clear feature.
	var skin := Color(0.035, 0.04, 0.05)
	var dark := Color(0.01, 0.01, 0.015)
	var glow := Color(0.10, 0.16, 0.20)
	var glow_e := 0.10
	var nest := Color(0.16, 0.55, 0.42)        # sickly inner glow (the growth)
	var sc := 0.70 if crouched else 1.0
	var eye_col := Color(0.98, 0.13, 0.07)
	if kind == KIND_YUNA:
		eye_col = Color(0.96, 0.46, 0.10)
	elif kind == KIND_FELIX:
		eye_col = Color(0.86, 0.08, 0.18)

	# Legs - long and thin.
	add_child(_capsule(0.06, 1.05, Vector3(-0.13, 0.52 * sc, 0.0), skin, glow, glow_e))
	add_child(_capsule(0.06, 1.05, Vector3(0.13, 0.52 * sc, 0.0), skin, glow, glow_e))
	# Pelvis + a torso leaning forward (predatory). Overlapped so it blends.
	add_child(_capsule(0.13, 0.36, Vector3(0, 1.06 * sc, 0.0), skin, glow, glow_e))
	torso = _capsule(0.15, 0.80, Vector3(0, 1.46 * sc, -0.05), skin, glow, glow_e)
	add_child(torso)
	# Exposed ribcage: a glowing cavity with rib slats across it.
	add_child(_box(Vector3(0.22, 0.46, 0.16), Vector3(0, 1.46 * sc, -0.10), Color(0.02, 0.04, 0.03), nest, 1.0))
	for ri in range(6):
		add_child(_box(Vector3(0.26 - ri * 0.012, 0.028, 0.18), Vector3(0, 1.26 * sc + ri * 0.085, -0.07), skin))
	# Shoulders pushed forward + a craning neck + spine knobs down the back.
	var shoulders := _capsule(0.055, 0.50, Vector3(0, 1.82 * sc, -0.08), skin, glow, glow_e)
	shoulders.rotation_degrees = Vector3(0, 0, 90)
	add_child(shoulders)
	add_child(_capsule(0.04, 0.26, Vector3(0, 1.92 * sc, -0.12), skin, glow, glow_e))
	for si in range(7):
		add_child(_box(Vector3(0.05, 0.05, 0.05), Vector3(0, 1.18 * sc + si * 0.10, 0.10), dark))

	# Ice-shards erupting from the back and shoulders - the silhouette.
	_shard_at(self, Vector3(-0.16, 1.95 * sc, 0.06), 0.60, Vector3(-46, 0, -20))
	_shard_at(self, Vector3(0.17, 1.92 * sc, 0.06), 0.50, Vector3(-50, 0, 18))
	_shard_at(self, Vector3(0.0, 1.82 * sc, 0.12), 0.72, Vector3(-32, 0, 4))
	_shard_at(self, Vector3(-0.10, 1.58 * sc, 0.14), 0.42, Vector3(-22, 0, -12))
	if kind != KIND_YUNA:
		_shard_at(self, Vector3(0.13, 1.62 * sc, 0.13), 0.46, Vector3(-26, 0, 14))

	# Head: a narrow, forward-jutting skull.
	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 2.04 * sc, -0.14)
	add_child(head_pivot)
	head = MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.125
	hs.height = 0.32
	hs.radial_segments = 28
	hs.rings = 16
	head.mesh = hs
	head.scale = Vector3(0.82, 1.22, 1.04)
	head.material_override = _mat(skin, glow, glow_e, 0.55)
	head_pivot.add_child(head)
	# Heavy brow + a vertical face seam glowing with the nest.
	head_pivot.add_child(_box(Vector3(0.24, 0.05, 0.09), Vector3(0, 0.07, -0.10), dark))
	head_pivot.add_child(_box(Vector3(0.02, 0.20, 0.03), Vector3(0, -0.04, -0.135), Color(0.02, 0.04, 0.03), nest, 0.8))
	# Eyes - bright, deep-set in dark sockets.
	for ex in [-0.05, 0.05]:
		var socket := _capsule(0.03, 0.07, Vector3(ex, 0.0, -0.085), dark)
		socket.rotation_degrees = Vector3(90, 0, 0)
		head_pivot.add_child(socket)
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.023
		es.height = 0.046
		eye.mesh = es
		eye.position = Vector3(ex, 0.0, -0.115)
		eye.material_override = _emit_mat(eye_col, 6.0)
		head_pivot.add_child(eye)
	# A few extra eyes, wrong and scattered across the face.
	for ep in [Vector3(-0.095, 0.05, -0.07), Vector3(0.10, 0.04, -0.06), Vector3(0.0, 0.10, -0.10), Vector3(-0.03, -0.10, -0.10)]:
		var xe := MeshInstance3D.new()
		var xs := SphereMesh.new()
		xs.radius = 0.012
		xs.height = 0.024
		xe.mesh = xs
		xe.position = ep
		xe.material_override = _emit_mat(eye_col, 4.5)
		head_pivot.add_child(xe)
	# Sunken cheeks + a long split maw with inner glow.
	for cx in [-0.08, 0.08]:
		head_pivot.add_child(_box(Vector3(0.05, 0.15, 0.05), Vector3(cx, -0.08, -0.05), dark))
	head_pivot.add_child(_capsule(0.045, 0.15, Vector3(0, -0.19, -0.04), skin, glow, glow_e))
	head_pivot.add_child(_box(Vector3(0.10, 0.12, 0.05), Vector3(0, -0.15, -0.11), Color(0.03, 0.0, 0.0), Color(0.55, 0.06, 0.05), 1.5))
	# A small crown of shards.
	_shard_at(head_pivot, Vector3(-0.06, 0.11, 0.02), 0.18, Vector3(-10, 0, -24))
	_shard_at(head_pivot, Vector3(0.06, 0.11, 0.02), 0.18, Vector3(-10, 0, 24))
	_shard_at(head_pivot, Vector3(0.0, 0.13, 0.04), 0.22, Vector3(-4, 0, 0))

	# Long arms reaching near the floor, with splayed talons + a forearm shard.
	add_child(_capsule(0.045, 1.08, Vector3(-0.27, 1.30 * sc, 0.0), skin, glow, glow_e))
	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.27, 1.72 * sc, 0.0)
	add_child(right_arm_pivot)
	right_arm = _capsule(0.045, 1.08, Vector3(0, -0.52, 0), skin, glow, glow_e)
	right_arm_pivot.add_child(right_arm)
	_shard_at(self, Vector3(-0.30, 0.95 * sc, 0.03), 0.30, Vector3(8, 0, -34))
	for hx in [-0.30, 0.30]:
		for fi in 4:
			var tal := _box(Vector3(0.014, 0.22, 0.014), Vector3(hx + (fi - 1.5) * 0.038, 0.66 * sc, 0.04), dark)
			tal.rotation_degrees = Vector3(20 + fi * 5, 0, (fi - 1.5) * 7)
			add_child(tal)
	# Faint filament veins down the torso.
	for vp in [Vector3(-0.25, 1.4 * sc, -0.12), Vector3(0.25, 1.4 * sc, -0.12)]:
		add_child(_box(Vector3(0.018, 0.55, 0.018), vp, Color(0.02, 0.04, 0.03), nest, 0.4))

	head_pivot.rotation_degrees.x = 16.0 if crouched else 8.0
	if crouched:
		right_arm_pivot.rotation_degrees.x = 30
	else:
		scale = Vector3(1.05, 1.22, 1.05)   # taller, looming


# A jagged ice/bone spike with a cold glowing edge. Tapers to a point.
func _shard_at(parent: Node, pos: Vector3, length: float, rot: Vector3) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.003
	c.bottom_radius = 0.05
	c.height = length
	c.radial_segments = 6
	c.rings = 1
	m.mesh = c
	m.position = pos
	m.rotation_degrees = rot
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.08, 0.11)
	mat.metallic = 0.25
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = Color(0.28, 0.50, 0.66)
	mat.emission_energy_multiplier = 0.22
	m.material_override = mat
	parent.add_child(m)


func _box(size: Vector3, pos: Vector3, color: Color, emit_color: Color = Color(0, 0, 0), emit_energy: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emit_color
		mat.emission_energy_multiplier = emit_energy
	m.material_override = mat
	return m


func _capsule(radius: float, height: float, pos: Vector3, color: Color, emit_color: Color = Color(0, 0, 0), emit_energy: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = maxf(height, radius * 2.0)
	c.radial_segments = 16
	c.rings = 8
	m.mesh = c
	m.position = pos
	m.material_override = _mat(color, emit_color, emit_energy, 0.8)
	return m


func _mat(color: Color, emit_color: Color, emit_energy: float, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = 0.0
	if emit_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emit_color
		mat.emission_energy_multiplier = emit_energy
	return mat


func _emit_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


# --- Lurk / stalk behaviour -----------------------------------------------
# A lurking shape creeps toward the player while unobserved, vanishes the
# instant the player looks straight at it, then reappears somewhere behind
# them. Classic "it's gone when you turn back, and closer than before."

func set_lurk(points: Array, creep_speed: float = 0.55) -> void:
	lurk_points = points.duplicate()
	lurking = true
	_hidden = false
	_creep_speed = creep_speed


# Stand and stare at the player; vanish for good the moment they look straight
# at it. The "I saw someone — now there's no one there" beat.
func set_peek() -> void:
	peeking = true
	lurking = false


func update_behavior(player_pos: Vector3, camera: Camera3D, dt: float) -> void:
	if stalking:
		_update_stalk(player_pos, dt)
		return
	if peeking:
		if camera == null:
			return
		var look_pos := Vector3(player_pos.x, global_position.y, player_pos.z)
		if look_pos.distance_to(global_position) > 0.1:
			look_at(look_pos, Vector3.UP)
		if _is_seen(camera):
			_seen_t += dt
			if _seen_t >= 0.18:
				AudioManager.whisper()
				queue_free()
		else:
			_seen_t = 0.0
		return
	if not lurking or camera == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _hidden:
		if now >= _respawn_at:
			_reappear(camera)
		return
	if _is_seen(camera):
		_seen_t += dt
		if _seen_t >= 0.20:
			_vanish()
		return
	_seen_t = maxf(0.0, _seen_t - dt)
	# Creep toward the player while unwatched. If it reaches you, it gets you.
	var to_player := player_pos - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist <= 1.1:
		_contact_scare()
		return
	global_position += to_player.normalized() * minf(dt * _creep_speed, dist - 0.5)
	var look_pos := Vector3(player_pos.x, global_position.y, player_pos.z)
	if look_pos.distance_to(global_position) > 0.1:
		look_at(look_pos, Vector3.UP)


func _is_seen(camera: Camera3D) -> bool:
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var head_pos := global_position + Vector3(0, 1.0, 0)
	var to := head_pos - origin
	var dist := to.length()
	if dist > 22.0 or dist < 0.2:
		return dist <= 0.2
	if fwd.dot(to / dist) < 0.82:
		return false
	# Line-of-sight: the shape has no collider, so a clear ray (no hit) means
	# nothing is between camera and shape.
	var space := camera.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, head_pos)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	return hit.is_empty()


func _vanish() -> void:
	visible = false
	_hidden = true
	_seen_t = 0.0
	_respawn_at = Time.get_ticks_msec() / 1000.0 + randf_range(2.5, 6.0)
	AudioManager.whisper()


# It reached the player: jumpscare, then retreat with a longer cooldown so it
# doesn't immediately maul you again. Non-lethal — just a fright.
func _contact_scare() -> void:
	ScareDirector.scare_flash()
	visible = false
	_hidden = true
	_seen_t = 0.0
	_respawn_at = Time.get_ticks_msec() / 1000.0 + randf_range(5.0, 9.0)


func _reappear(camera: Camera3D) -> void:
	if lurk_points.is_empty():
		visible = true
		_hidden = false
		return
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var best: Vector3 = lurk_points[0]
	var best_dot := 2.0
	for p in lurk_points:
		var d: Vector3 = p - origin
		d.y = 0.0
		if d.length() < 0.5:
			continue
		var dot := fwd.dot(d.normalized())
		if dot < best_dot:
			best_dot = dot
			best = p
	global_position = best
	visible = true
	_hidden = false
	_seen_t = 0.0
	var pl: Node3D = GameState.player
	if pl:
		var look_pos := Vector3(pl.global_position.x, global_position.y, pl.global_position.z)
		if look_pos.distance_to(global_position) > 0.1:
			look_at(look_pos, Vector3.UP)
	AudioManager.breath()


# --- Stalker: the hunter --------------------------------------------------
# Patrols a route, investigates noise, chases on sight, and searches your last
# known spot when it loses you. Catching you triggers a death/respawn.

func set_stalk(points: Array, p_patrol_speed: float = 1.15, p_chase_speed: float = 3.9) -> void:
	stalking = true
	lurking = false
	peeking = false
	stalk_points = points.duplicate()
	patrol_speed = p_patrol_speed
	chase_speed = p_chase_speed
	_stalk_state = StalkState.PATROL
	_patrol_idx = 0
	if not stalk_points.is_empty():
		_stalk_target = stalk_points[0]
	_agent = NavigationAgent3D.new()
	_agent.radius = 0.4
	_agent.height = 1.8
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.6
	_agent.avoidance_enabled = false
	add_child(_agent)
	# A shootable hitbox (an Area so it never blocks the player physically).
	_hp = 3
	_hitbox = Area3D.new()
	var hcol := CollisionShape3D.new()
	var hcap := CapsuleShape3D.new()
	hcap.radius = 0.45
	hcap.height = 2.0
	hcol.shape = hcap
	hcol.position = Vector3(0, 1.1, 0)
	_hitbox.add_child(hcol)
	_hitbox.set_meta("on_shot", Callable(self, "_take_shot"))
	add_child(_hitbox)


func reset_stalk(player_pos: Vector3) -> void:
	# Called on respawn: send it back to patrol, as far from the player as we can.
	if not stalking:
		return
	_stalk_state = StalkState.PATROL
	_state_t = 0.0
	_lost_t = 0.0
	_catch_t = 0.0
	_grace_t = 3.0       # a breath of safety after respawn so it can't re-lock you
	_stung = false
	visible = true
	if not stalk_points.is_empty():
		var best: Vector3 = stalk_points[0]
		var best_d := -1.0
		for p in stalk_points:
			var d: float = _flat(p).distance_to(player_pos)
			if d > best_d:
				best_d = d
				best = p
		global_position = best
		_patrol_idx = stalk_points.find(best)
		_stalk_target = best


func _update_stalk(player_pos: Vector3, dt: float) -> void:
	_state_t += dt
	if _grace_t > 0.0:
		_grace_t -= dt
	var can_see := _can_see_player(player_pos)
	match _stalk_state:
		StalkState.PATROL:
			if not stalk_points.is_empty():
				_move_toward(_stalk_target, patrol_speed, dt)
				if global_position.distance_to(_flat(_stalk_target)) < 0.7:
					_next_patrol()
			if can_see:
				_enter_chase(player_pos)
			elif _can_hear_player(player_pos):
				_enter_investigate(player_pos)
		StalkState.INVESTIGATE:
			_move_toward(_stalk_target, (patrol_speed + chase_speed) * 0.5, dt)
			if can_see:
				_enter_chase(player_pos)
			elif _can_hear_player(player_pos):
				_stalk_target = player_pos
				_state_t = 0.0
			elif global_position.distance_to(_flat(_stalk_target)) < 0.9 and _state_t > 3.0:
				_enter_patrol()
		StalkState.CHASE:
			if can_see:
				_last_known = player_pos
				_lost_t = 0.0
			else:
				_lost_t += dt
			_move_toward(_last_known, chase_speed, dt)
			# Catch requires holding you close for a beat - so you can dash past
			# or juke instead of dying the instant it brushes you.
			if can_see and _flat(player_pos).distance_to(global_position) <= 1.4:
				_catch_t += dt
				if _catch_t >= 0.8:
					_catch_player()
					return
			else:
				_catch_t = maxf(0.0, _catch_t - dt * 2.0)
			if _lost_t > 1.5:
				_enter_search()
		StalkState.SEARCH:
			_move_toward(_last_known, chase_speed * 0.7, dt)
			if can_see:
				_enter_chase(player_pos)
			elif global_position.distance_to(_flat(_last_known)) < 0.9 or _state_t > 6.0:
				_enter_patrol()


func _enter_patrol() -> void:
	_stalk_state = StalkState.PATROL
	_state_t = 0.0
	_pick_nearest_patrol()


func _enter_investigate(pos: Vector3) -> void:
	_stalk_state = StalkState.INVESTIGATE
	_state_t = 0.0
	_stalk_target = pos
	AudioManager.breath()


# Public: anything louder than patrol counts as hunting. Used by the lure
# controller to gate calls (it never speaks while it's already on you).
func is_hunting() -> bool:
	return stalking and _stalk_state != StalkState.PATROL


# Public: you answered the voice. It now knows roughly where you are and moves
# to investigate; if it then gets line of sight it will chase. Skip if already
# chasing - we don't want to soften a chase by bumping it back to investigate.
func alert_to(pos: Vector3) -> void:
	if not stalking or _stalk_state == StalkState.CHASE:
		return
	_last_known = pos
	_enter_investigate(pos)


func _enter_chase(pos: Vector3) -> void:
	_stalk_state = StalkState.CHASE
	_state_t = 0.0
	_lost_t = 0.0
	_last_known = pos
	if not _stung:
		_stung = true
		AudioManager.shape_sting()


func _enter_search() -> void:
	_stalk_state = StalkState.SEARCH
	_state_t = 0.0
	_stung = false


func _next_patrol() -> void:
	if stalk_points.is_empty():
		return
	_patrol_idx = (_patrol_idx + 1) % stalk_points.size()
	_stalk_target = stalk_points[_patrol_idx]


func _pick_nearest_patrol() -> void:
	if stalk_points.is_empty():
		return
	var best := 0
	var best_d := INF
	for i in stalk_points.size():
		var d: float = _flat(stalk_points[i]).distance_to(global_position)
		if d < best_d:
			best_d = d
			best = i
	_patrol_idx = best
	_stalk_target = stalk_points[best]


func _move_toward(target: Vector3, speed: float, dt: float) -> void:
	# Path around obstacles via the navmesh when one's available; fall back to a
	# straight line if not (so it never freezes).
	var dest := _flat(target)
	var step := dest
	if _agent != null and _agent.is_inside_tree():
		_agent.target_position = dest
		var npp := _agent.get_next_path_position()
		var flat_npp := Vector3(npp.x, global_position.y, npp.z)
		if flat_npp.distance_to(global_position) > 0.15:
			step = flat_npp
	var to := step - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.05:
		return
	global_position += to.normalized() * minf(speed * dt, dist)
	_face(step)


func _face(target: Vector3) -> void:
	var lp := Vector3(target.x, global_position.y, target.z)
	if lp.distance_to(global_position) > 0.1:
		look_at(lp, Vector3.UP)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, global_position.y, v.z)


func _can_see_player(player_pos: Vector3) -> bool:
	if _grace_t > 0.0:
		return false
	if GameState.player_hidden:
		return false
	var pl: Node = GameState.player
	if pl == null:
		return false
	var eye := global_position + Vector3(0, 1.7, 0)
	var target := player_pos + Vector3(0, 1.0, 0)
	var to := target - eye
	var dist := to.length()
	var rng := 4.0                     # in the dark it only senses you very close
	if pl.get("flashlight_on"):
		rng = sight_range * 1.4        # the beam gives you away from across the room
	if dist > rng:
		return false
	# Forward cone - it has to actually be facing your way (no eyes in the back).
	var fwd := -global_transform.basis.z
	if dist > 1.4 and fwd.dot(to / dist) < 0.30:
		return false
	# Line of sight: a wall between us blocks it.
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(eye, target)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return true
	var n: Node = hit["collider"]
	while n and n != pl:
		n = n.get_parent()
	return n == pl


func _can_hear_player(player_pos: Vector3) -> bool:
	var pl: Node = GameState.player
	if pl == null:
		return false
	var d := _flat(player_pos).distance_to(global_position)
	var r := hear_range
	var loud := false
	# Only sprinting gives you away by sound - walking, even with the lamp on,
	# is quiet (the lamp gives you away by sight, not noise).
	var vel: Variant = pl.get("velocity")
	if vel is Vector3 and Vector2(vel.x, vel.z).length() > 5.5:
		loud = true
		r = hear_range * 1.4
	return loud and d <= r


func _catch_player() -> void:
	ScareDirector.scare_flash()
	AudioManager.shape_sting()
	_stalk_state = StalkState.PATROL
	_state_t = 0.0
	_catch_t = 0.0
	_grace_t = 1.6                 # back off briefly so it can't grind you down
	var pl: Node = GameState.player
	if pl and pl.has_method("take_damage"):
		pl.call("take_damage", 38.0)
	else:
		GameState.catch_player()


# --- Stare detection (Felix only) ----------------------------------------

func update_stare() -> void:
	if kind != KIND_FELIX or felix_amara_fired:
		return
	var player: Node3D = GameState.player
	if player == null:
		return
	var camera: Camera3D = InteractionManager.camera
	if camera == null:
		return
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var to := origin - camera.global_transform.basis.z * 18.0
	var params := PhysicsRayQueryParameters3D.create(origin, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	var looking := false
	if not hit.is_empty():
		var node: Node = hit["collider"]
		while node and node != self:
			node = node.get_parent()
		looking = node == self
	if looking:
		stare_time += get_process_delta_time()
		if stare_time >= 5.0 and not felix_amara_fired:
			felix_amara_fired = true
			_fire_amara()
	else:
		stare_time = max(0.0, stare_time - get_process_delta_time() * 0.5)


func _fire_amara() -> void:
	AudioManager.shape_sting()
	var tween := head_pivot.create_tween()
	tween.tween_property(head_pivot, "rotation_degrees:y", 80, 2.0)
	tween.tween_interval(2.0)
	tween.tween_property(head_pivot, "rotation_degrees:y", 0, 1.4)


# --- Hargrove farewell ---------------------------------------------------

func farewell(on_complete: Callable = Callable()) -> void:
	if farewell_done:
		return
	farewell_done = true
	AudioManager.shape_sting()
	var t := create_tween()
	t.tween_property(self, "rotation_degrees:y", rotation_degrees.y + 180, 2.0)
	t.tween_interval(0.1)
	t.tween_callback(func(): right_arm_pivot.create_tween().tween_property(right_arm_pivot, "rotation_degrees:x", -110, 1.4))
	t.tween_interval(3.4)
	t.tween_callback(func():
		right_arm_pivot.create_tween().tween_property(right_arm_pivot, "rotation_degrees:x", 0, 1.0)
		var move := create_tween()
		move.tween_property(self, "position", position + Vector3(-7, 0, -9), 4.0)
		var fade := create_tween().set_parallel(true)
		for c in get_children():
			if c is MeshInstance3D:
				fade.tween_property(c.material_override, "albedo_color:a", 0.0, 3.5)
	)
	t.tween_interval(4.2)
	t.tween_callback(func():
		visible = false
		if on_complete.is_valid():
			on_complete.call()
	)
