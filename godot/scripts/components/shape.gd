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


func _build() -> void:
	# A gaunt, too-tall wraith built from smooth capsules with a sculpted head:
	# deep-set glowing eyes under a heavy brow, sunken cheeks, an open maw.
	# Dark skin with a faint cold self-glow so the silhouette reads in the dark.
	var skin := Color(0.06, 0.06, 0.075)
	var dark := Color(0.015, 0.015, 0.02)
	var glow := Color(0.13, 0.16, 0.22)
	var glow_e := 0.26
	var sc := 0.72 if crouched else 1.0      # crouched = shorter, hunched

	# Legs
	add_child(_capsule(0.072, 0.95, Vector3(-0.13, 0.50 * sc, 0), skin, glow, glow_e))
	add_child(_capsule(0.072, 0.95, Vector3(0.13, 0.50 * sc, 0), skin, glow, glow_e))
	# Pelvis + tapered torso + shoulders + neck
	add_child(_capsule(0.15, 0.34, Vector3(0, 1.02 * sc, 0), skin, glow, glow_e))
	torso = _capsule(0.165, 0.72, Vector3(0, 1.42 * sc, 0), skin, glow, glow_e)
	add_child(torso)
	var shoulders := _capsule(0.07, 0.46, Vector3(0, 1.74 * sc, 0), skin, glow, glow_e)
	shoulders.rotation_degrees = Vector3(0, 0, 90)
	add_child(shoulders)
	add_child(_capsule(0.048, 0.20, Vector3(0, 1.88 * sc, 0.01), skin, glow, glow_e))

	# Head
	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 2.00 * sc, 0.01)
	add_child(head_pivot)
	head = MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.135
	hs.height = 0.30
	hs.radial_segments = 32
	hs.rings = 18
	head.mesh = hs
	head.scale = Vector3(0.92, 1.14, 1.0)    # elongated skull
	head.material_override = _mat(skin, glow, glow_e, 0.65)
	head_pivot.add_child(head)
	# Heavy brow ridge shadowing the eyes
	head_pivot.add_child(_box(Vector3(0.22, 0.05, 0.07), Vector3(0, 0.055, -0.095), dark))
	# Deep eye sockets + glowing eyes recessed inside them
	for ex in [-0.052, 0.052]:
		var socket := _capsule(0.033, 0.075, Vector3(ex, -0.005, -0.075), dark)
		socket.rotation_degrees = Vector3(90, 0, 0)
		head_pivot.add_child(socket)
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.021
		es.height = 0.042
		eye.mesh = es
		eye.position = Vector3(ex, -0.005, -0.10)
		eye.material_override = _emit_mat(Color(0.97, 0.13, 0.08), 4.2)
		head_pivot.add_child(eye)
	# Sunken cheeks
	for cx in [-0.085, 0.085]:
		head_pivot.add_child(_box(Vector3(0.05, 0.13, 0.05), Vector3(cx, -0.07, -0.06), dark))
	# Open maw: dark jaw + faint inner glow
	head_pivot.add_child(_capsule(0.055, 0.13, Vector3(0, -0.17, -0.03), skin, glow, glow_e))
	head_pivot.add_child(_box(Vector3(0.10, 0.08, 0.04), Vector3(0, -0.13, -0.10), Color(0.05, 0.0, 0.0), Color(0.42, 0.03, 0.03), 1.3))

	# Long arms hanging past the knees, with claw-hands
	add_child(_capsule(0.052, 0.95, Vector3(-0.27, 1.28 * sc, 0.02), skin, glow, glow_e))
	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.27, 1.66 * sc, 0.02)
	add_child(right_arm_pivot)
	right_arm = _capsule(0.052, 0.95, Vector3(0, -0.45, 0), skin, glow, glow_e)
	right_arm_pivot.add_child(right_arm)
	for hx in [-0.30, 0.30]:
		for fi in 3:
			add_child(_box(Vector3(0.018, 0.14, 0.018), Vector3(hx + (fi - 1) * 0.035, 0.80 * sc, 0.04), dark))

	if crouched:
		head_pivot.rotation_degrees.x = 18
		right_arm_pivot.rotation_degrees.x = 32


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
