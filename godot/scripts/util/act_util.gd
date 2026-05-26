class_name ActUtil
extends RefCounted
# Common helpers for act scripts.

# Preloaded so the flicker component works even if the global class-name cache
# (.godot/) hasn't been rebuilt yet on a fresh checkout.
const FlickerComponent := preload("res://scripts/components/flicker.gd")

# Per-act lighting setup. Configures Chamber.current_light_* so the
# room-builder can drop matching ceiling fixtures automatically, and configures
# the per-act Environment with Forward+ features.
static func setup_lighting(parent: Node3D, ambient: Color, fog_col: Color, fog_density: float = 0.012, ambient_energy: float = 0.7, fixture_color: Color = Color(0, 0, 0), fixture_energy: float = -1.0, fixture_range: float = -1.0) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient
	e.ambient_light_energy = ambient_energy
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.012, 0.014, 0.022)
	e.fog_enabled = true
	e.fog_light_color = fog_col
	e.fog_light_energy = 0.5
	e.fog_density = fog_density
	e.fog_height = 6.0
	e.fog_height_density = 0.20
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.022 + fog_density * 0.7
	e.volumetric_fog_albedo = ambient.lerp(Color.WHITE, 0.4)
	e.volumetric_fog_anisotropy = 0.3
	e.volumetric_fog_length = 48.0
	e.volumetric_fog_gi_inject = 0.6
	e.volumetric_fog_ambient_inject = 0.9
	e.volumetric_fog_temporal_reprojection_enabled = true
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.35
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 1.2
	e.ssao_intensity = 1.1
	e.ssao_power = 1.4
	e.ssao_light_affect = 0.18
	e.ssil_enabled = false
	e.ssr_enabled = true
	e.ssr_max_steps = 48
	e.sdfgi_enabled = false
	e.glow_enabled = true
	e.glow_intensity = 1.0
	e.glow_strength = 1.0
	e.glow_bloom = 0.20
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.glow_hdr_threshold = 0.95
	e.glow_hdr_scale = 2.0
	e.glow_normalized = true
	# Multi-scale bloom so emissive eyes / signs / screens bloom softly.
	e.set_glow_level(1, 0.30)
	e.set_glow_level(2, 0.60)
	e.set_glow_level(3, 0.85)
	e.set_glow_level(4, 0.45)
	e.set_glow_level(5, 0.25)
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.0
	e.adjustment_contrast = 1.11
	e.adjustment_saturation = 0.80
	env.environment = e
	parent.add_child(env)

	# Update Chamber so ceiling fixtures match this act's mood.
	var fix_col: Color = fixture_color if fixture_color.a > 0.001 else ambient.lerp(Color.WHITE, 0.45)
	Chamber.current_light_color = fix_col
	Chamber.current_light_energy = fixture_energy if fixture_energy > 0.0 else 4.5
	Chamber.current_light_range = fixture_range if fixture_range > 0.0 else 14.0


static func light_rig_act1(parent: Node3D) -> void:
	# Cryo bay — emergency red.
	setup_lighting(parent, Color(0.86, 0.43, 0.43), Color(0.18, 0.05, 0.06), 0.016, 0.55,
		Color(1.0, 0.42, 0.34), 4.2, 13.0)


static func light_rig_act2(parent: Node3D) -> void:
	# Corridors / cabins / decon / med — cool clinical blue-white.
	setup_lighting(parent, Color(0.70, 0.78, 0.86), Color(0.13, 0.16, 0.22), 0.012, 0.7,
		Color(0.92, 0.97, 1.0), 4.8, 14.0)


static func light_rig_act3(parent: Node3D) -> void:
	# Research deck — cold blue-white, brighter task lighting.
	setup_lighting(parent, Color(0.72, 0.84, 0.96), Color(0.11, 0.16, 0.24), 0.010, 0.75,
		Color(0.86, 0.94, 1.0), 5.2, 15.0)


static func light_rig_act4(parent: Node3D) -> void:
	# Array room — dim warm-white, deep dark-blue fog.
	setup_lighting(parent, Color(0.43, 0.39, 0.43), Color(0.03, 0.04, 0.06), 0.020, 0.45,
		Color(0.95, 0.78, 0.55), 2.8, 11.0)


# Place a dust-mote particle field above the player path. Cheap atmosphere.
static func add_dust_motes(parent: Node3D, center: Vector3, extents: Vector3 = Vector3(8, 2.4, 8), amount: int = 80, tint: Color = Color(0.85, 0.87, 0.92, 0.18)) -> GPUParticles3D:
	var ps := GPUParticles3D.new()
	ps.name = "dust_motes"
	ps.amount = amount
	ps.lifetime = 16.0
	ps.preprocess = 5.0
	ps.explosiveness = 0.0
	ps.randomness = 1.0
	ps.fixed_fps = 30
	ps.visibility_aabb = AABB(center - extents, extents * 2.0)
	ps.local_coords = false
	ps.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = extents
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 80.0
	mat.gravity = Vector3(0, -0.02, 0)
	mat.initial_velocity_min = 0.01
	mat.initial_velocity_max = 0.05
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.angular_velocity_min = -8.0
	mat.angular_velocity_max = 8.0
	ps.process_material = mat

	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.012, 0.012)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.albedo_color = tint
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_mat.disable_receive_shadows = true
	dust_mat.no_depth_test = false
	dust_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh.material = dust_mat
	ps.draw_pass_1 = mesh
	ps.position = center
	parent.add_child(ps)
	return ps


# Drop a row of emissive trim along a wall. Reads as service / safety strip.
static func emergency_strip(parent: Node3D, start: Vector3, end: Vector3, color: Color = Color(0.95, 0.32, 0.18), energy: float = 1.5) -> void:
	var diff := end - start
	var length := diff.length()
	if length < 0.01:
		return
	var center := (start + end) * 0.5
	var dir := diff.normalized()
	var size: Vector3
	if abs(dir.x) > abs(dir.z):
		size = Vector3(length, 0.06, 0.04)
	else:
		size = Vector3(0.04, 0.06, length)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.position = center
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mesh.material_override = mat
	parent.add_child(mesh)


# Add a localised omni light. For accent lighting beyond the auto ceiling rig.
static func add_omni(parent: Node3D, pos: Vector3, color: Color, energy: float = 1.5, omni_range: float = 6.0, shadows: bool = true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = omni_range
	l.omni_attenuation = 1.6
	l.shadow_enabled = shadows
	l.shadow_bias = 0.05
	l.shadow_normal_bias = 1.0
	parent.add_child(l)
	return l


# Add a spot light, useful for focused fixtures (autodoc, terminals, intercoms).
static func add_spot(parent: Node3D, pos: Vector3, target_dir: Vector3, color: Color, energy: float = 2.0, spot_range: float = 6.0, angle: float = 35.0) -> SpotLight3D:
	var s := SpotLight3D.new()
	s.position = pos
	s.light_color = color
	s.light_energy = energy
	s.spot_range = spot_range
	s.spot_angle = angle
	s.spot_angle_attenuation = 0.4
	s.shadow_enabled = true
	s.shadow_bias = 0.05
	s.shadow_normal_bias = 1.0
	s.look_at_from_position(pos, pos + target_dir, Vector3.UP if abs(target_dir.y) < 0.9 else Vector3.FORWARD)
	parent.add_child(s)
	return s


# A wall-mounted Label3D that always reads correctly regardless of viewer
# position — billboard around Y keeps the text upright + facing the camera.
static func wall_label(parent: Node3D, text: String, pos: Vector3, font_size: int = 22, color: Color = Color(0.92, 0.94, 1.0), outline: Color = Color(0, 0, 0, 0.7)) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos
	lbl.font_size = font_size
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	lbl.outline_size = 4
	lbl.outline_modulate = outline
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl


# Text that lies FLAT on a screen / console surface. Unlike wall_label this
# does NOT billboard — it keeps a fixed Y rotation so it stays glued to the
# panel and never swings round to clip through the monitor body.
static func screen_label(parent: Node3D, text: String, pos: Vector3, face_y_deg: float, font_size: int = 16, color: Color = Color(0.78, 0.90, 0.98)) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos
	lbl.rotation_degrees = Vector3(0, face_y_deg, 0)
	lbl.font_size = font_size
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.shaded = false
	lbl.double_sided = false
	lbl.no_depth_test = false
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl


# Drop floor decals (warning stripes, evac arrows) so floors don't look bare.
static func add_floor_decals(parent: Node3D, w: float, d: float, center: Vector3 = Vector3.ZERO, accent: Color = Color(0.86, 0.70, 0.16, 0.7)) -> void:
	# Hazard stripes near the four walls
	for ax in [-w/2 + 0.6, w/2 - 0.6]:
		for az in range(-int(d/2) + 1, int(d/2), 3):
			var stripe := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.30, 0.12)
			stripe.mesh = q
			stripe.rotation_degrees = Vector3(-90, 0, 0)
			stripe.position = center + Vector3(ax, 0.02, az)
			var sm := StandardMaterial3D.new()
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			sm.albedo_color = accent
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm.emission_enabled = true
			sm.emission = accent
			sm.emission_energy_multiplier = 0.15
			stripe.material_override = sm
			parent.add_child(stripe)


# Drop a row of ceiling pipes / conduits across the room. Cheap visual density.
static func add_ceiling_pipes(parent: Node3D, w: float, d: float, h: float, center: Vector3 = Vector3.ZERO) -> void:
	for cz in range(-int(d/2) + 1, int(d/2), 3):
		# Main pipe (industrial dark)
		var p1 := MeshInstance3D.new()
		var b1 := BoxMesh.new()
		b1.size = Vector3(w - 0.6, 0.12, 0.12)
		p1.mesh = b1
		p1.position = center + Vector3(0, h - 0.18, cz)
		var m1 := StandardMaterial3D.new()
		m1.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m1.albedo_color = Color(0.30, 0.27, 0.22)
		m1.metallic = 0.5
		m1.roughness = 0.55
		p1.material_override = m1
		parent.add_child(p1)
		# Secondary smaller pipe (coloured)
		var p2 := MeshInstance3D.new()
		var b2 := BoxMesh.new()
		b2.size = Vector3(w - 0.6, 0.08, 0.08)
		p2.mesh = b2
		p2.position = center + Vector3(0, h - 0.34, cz + 0.30)
		var m2 := StandardMaterial3D.new()
		m2.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m2.albedo_color = Color(0.22, 0.40, 0.55)
		m2.metallic = 0.45
		m2.roughness = 0.50
		p2.material_override = m2
		parent.add_child(p2)


# Mount a vent grille on a wall, oriented so the slats face the room interior.
static func wall_vent(parent: Node3D, axis: String, fixed: float, gap_center: float, y: float = 2.3, size: Vector2 = Vector2(0.7, 0.5)) -> void:
	var thick := 0.04
	var size3: Vector3
	var pos: Vector3
	if axis == "x":
		size3 = Vector3(thick, size.y, size.x)
		pos = Vector3(fixed, y, gap_center)
	else:
		size3 = Vector3(size.x, size.y, thick)
		pos = Vector3(gap_center, y, fixed)
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = size3
	frame.mesh = fb
	frame.position = pos
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	fm.albedo_color = Color(0.16, 0.18, 0.22)
	fm.metallic = 0.55
	fm.roughness = 0.45
	frame.material_override = fm
	parent.add_child(frame)
	# Slats
	for slat in 5:
		var slat_pos := pos
		var slat_size: Vector3
		if axis == "x":
			slat_size = Vector3(thick * 1.4, 0.04, size.x - 0.10)
			slat_pos.y = y - size.y * 0.4 + slat * (size.y * 0.2)
		else:
			slat_size = Vector3(size.x - 0.10, 0.04, thick * 1.4)
			slat_pos.y = y - size.y * 0.4 + slat * (size.y * 0.2)
		var sl := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = slat_size
		sl.mesh = sb
		sl.position = slat_pos
		var sm2 := StandardMaterial3D.new()
		sm2.albedo_color = Color(0.10, 0.10, 0.13)
		sm2.metallic = 0.3
		sl.material_override = sm2
		parent.add_child(sl)


# Drop a small wall poster / placard (paper sign) at a position.
static func wall_poster(parent: Node3D, axis: String, fixed: float, pos: Vector3, size: Vector2, color: Color) -> void:
	var thick := 0.02
	var size3: Vector3
	if axis == "x":
		size3 = Vector3(thick, size.y, size.x)
	else:
		size3 = Vector3(size.x, size.y, thick)
	var ms := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size3
	ms.mesh = bm
	ms.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_color = color
	mat.roughness = 0.85
	ms.material_override = mat
	parent.add_child(ms)


static func spawn_player(pos: Vector3, rotation_y: float = 0.0) -> void:
	if GameState.player:
		GameState.player.global_position = pos
		GameState.player.rotation_degrees = Vector3(0, rotation_y, 0)


# ---------------------------------------------------------------------------
# HORROR
# ---------------------------------------------------------------------------

# One-stop "make this room haunted" call. Sets the ScareDirector intensity for
# ambient dread, makes the room's lights flicker, and spawns stalking shapes.
#   opts = {
#     intensity: float (0..1),
#     flicker: bool (default true), flicker_rate: float,
#     lurkers: [ {kind: String, points: [Vector3,...], creep: float}, ... ],
#   }
static func haunt(act: Node3D, opts: Dictionary = {}) -> void:
	ScareDirector.set_intensity(opts.get("intensity", 0.3))
	if opts.get("flicker", true):
		_flicker_lights(act, opts.get("flicker_rate", 1.0))
	for cfg in opts.get("lurkers", []):
		var pts: Array = cfg.get("points", [])
		if pts.is_empty():
			continue
		var shape := HorrorShape.create(cfg.get("kind", HorrorShape.KIND_FELIX), pts[0], 0.0)
		shape.set_lurk(pts, cfg.get("creep", 0.55))
		act.add_child(shape)
		ShapeTracker.register(shape)


static func _flicker_lights(node: Node, rate: float) -> void:
	for child in node.get_children():
		if child is OmniLight3D or child is SpotLight3D:
			var f: Node = FlickerComponent.new()
			child.add_child(f)
			f.setup(child, rate)
		if child.get_child_count() > 0:
			_flicker_lights(child, rate)


# A dark wet stain on a surface (floor by default). normal = "up"/"x"/"z".
static func blood_decal(parent: Node3D, pos: Vector3, size: Vector2, facing: String = "up", color: Color = Color(0.22, 0.04, 0.05, 0.85)) -> void:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.position = pos
	match facing:
		"up":
			mi.rotation_degrees = Vector3(-90, randf_range(0, 360), 0)
		"x":
			mi.rotation_degrees = Vector3(0, 90, 0)
		"z":
			mi.rotation_degrees = Vector3(0, 0, 0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.3
	m.metallic = 0.2
	mi.material_override = m
	parent.add_child(mi)


# A crumpled crew body — set dressing for "the others didn't make it". Built
# from primitives, lying on the floor, optionally in a pool of blood. Purely
# visual (no collider) so it never blocks a path or trips a shape's sightline.
static func corpse(parent: Node3D, pos: Vector3, rot_y_deg: float = 0.0, blood: bool = true, suit: Color = Color(0.13, 0.14, 0.17)) -> Node3D:
	var body := Node3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, rot_y_deg, 0)
	var skin := Color(0.50, 0.45, 0.41)
	# Torso + pelvis (length runs along local Z).
	body.add_child(_corpse_capsule(0.16, 0.62, Vector3(0, 0.16, 0.0), Vector3(90, 0, 0), suit))
	body.add_child(_corpse_capsule(0.15, 0.20, Vector3(0, 0.15, 0.42), Vector3(90, 0, 0), suit))
	# Head, lolled to one side.
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.115
	hs.height = 0.23
	head.mesh = hs
	head.position = Vector3(0.06, 0.12, -0.46)
	head.material_override = _corpse_mat(skin)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(head)
	# Arms splayed out.
	body.add_child(_corpse_capsule(0.055, 0.50, Vector3(-0.28, 0.11, -0.06), Vector3(80, 0, 32), suit))
	body.add_child(_corpse_capsule(0.055, 0.50, Vector3(0.27, 0.10, 0.04), Vector3(70, 0, -52), suit))
	# Legs, one bent.
	body.add_child(_corpse_capsule(0.075, 0.60, Vector3(-0.10, 0.12, 0.80), Vector3(94, 0, 9), suit))
	body.add_child(_corpse_capsule(0.075, 0.54, Vector3(0.15, 0.11, 0.74), Vector3(78, 0, -20), suit))
	parent.add_child(body)
	if blood:
		blood_decal(parent, pos + Vector3(0, 0.02, -0.30), Vector2(1.4, 1.05), "up")
		blood_decal(parent, pos + Vector3(0.42, 0.02, 0.25), Vector2(0.7, 0.55), "up")
	return body


static func _corpse_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = c
	m.roughness = 0.9
	m.metallic = 0.0
	return m


static func _corpse_capsule(radius: float, height: float, pos: Vector3, rot: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = maxf(height, radius * 2.0)
	cap.radial_segments = 12
	cap.rings = 6
	mi.mesh = cap
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = _corpse_mat(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


# A trail of blood smears on the floor from one point to another — drag marks.
static func blood_trail(parent: Node3D, from: Vector3, to: Vector3, count: int = 6) -> void:
	for i in count:
		var f := float(i) / float(maxi(count - 1, 1))
		var p: Vector3 = from.lerp(to, f)
		var sz := lerpf(0.95, 0.35, f)
		blood_decal(parent, Vector3(p.x, 0.02, p.z), Vector2(sz, sz * randf_range(0.7, 1.15)),
			"up", Color(0.20, 0.03, 0.04, lerpf(0.85, 0.5, f)))


# Red scrawl on a wall — billboard-free so it stays stuck to the wall.
static func wall_scrawl(parent: Node3D, text: String, pos: Vector3, face_y_deg: float, font_size: int = 40, color: Color = Color(0.55, 0.05, 0.06)) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos
	lbl.rotation_degrees = Vector3(0, face_y_deg, 0)
	lbl.font_size = font_size
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.shaded = false
	lbl.double_sided = true
	lbl.outline_size = 2
	lbl.outline_modulate = Color(0.10, 0.0, 0.0, 0.8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl


static func register_intercom(parent: Node3D, intercom_id: int, position: Vector3, rotation_y: float = 0.0, trigger_at: Vector3 = Vector3.INF, radius: float = 3.5, delay: float = 0.0, manual: bool = false) -> IntercomPanel:
	var panel := IntercomPanel.create(position, rotation_y)
	parent.add_child(panel)
	if not manual:
		var trig_pos: Vector3 = position if trigger_at == Vector3.INF else trigger_at
		OlenManager.add_proximity_trigger(intercom_id, trig_pos, panel, radius, delay)
	return panel
