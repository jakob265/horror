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
	var body_color := Color(0.07, 0.07, 0.085)
	var torso_h := 0.55 if crouched else 0.95
	var torso_y := 0.55 if crouched else 1.05

	torso = _box(Vector3(0.45, torso_h, 0.30), Vector3(0, torso_y, 0), body_color)
	add_child(torso)

	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, torso_y + torso_h * 0.55, 0)
	add_child(head_pivot)
	head = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	head.mesh = sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = body_color
	head.material_override = head_mat
	head_pivot.add_child(head)

	# Left arm
	var left_arm := _box(Vector3(0.10, 0.65, 0.10), Vector3(-0.28, torso_y - 0.05, 0), body_color)
	add_child(left_arm)
	# Right arm with pivot for waving
	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.28, torso_y + 0.30, 0)
	add_child(right_arm_pivot)
	right_arm = _box(Vector3(0.10, 0.65, 0.10), Vector3(0, -0.32, 0), body_color)
	right_arm_pivot.add_child(right_arm)
	# Legs
	add_child(_box(Vector3(0.13, 0.85, 0.18), Vector3(-0.13, 0.42, 0), body_color))
	add_child(_box(Vector3(0.13, 0.85, 0.18), Vector3(0.13, 0.42, 0), body_color))

	if crouched:
		head_pivot.rotation_degrees.x = 20
		right_arm_pivot.rotation_degrees.x = 40


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	return m


# --- Lurk / stalk behaviour -----------------------------------------------
# A lurking shape creeps toward the player while unobserved, vanishes the
# instant the player looks straight at it, then reappears somewhere behind
# them. Classic "it's gone when you turn back, and closer than before."

func set_lurk(points: Array, creep_speed: float = 0.55) -> void:
	lurk_points = points.duplicate()
	lurking = true
	_hidden = false
	_creep_speed = creep_speed


func update_behavior(player_pos: Vector3, camera: Camera3D, dt: float) -> void:
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
	# Creep toward the player while unwatched, keeping a small standoff.
	var to_player := player_pos - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > 2.0:
		global_position += to_player.normalized() * minf(dt * _creep_speed, dist - 2.0)
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
