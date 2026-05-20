class_name ActUtil
extends RefCounted
# Common helpers for act scripts.

# Per-act lighting setup. Now also configures Chamber.current_light_* so the
# room-builder can drop matching ceiling fixtures automatically, and seeds
# dust motes near the player so air reads as filthy / lived-in.
static func setup_lighting(parent: Node3D, ambient: Color, fog_col: Color, fog_density: float = 0.018, ambient_energy: float = 0.25, fixture_color: Color = Color(0, 0, 0), fixture_energy: float = -1.0, fixture_range: float = -1.0) -> void:
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
	e.fog_height_density = 0.22
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.012 + fog_density * 0.35
	e.volumetric_fog_albedo = ambient.lerp(Color.WHITE, 0.4)
	e.volumetric_fog_anisotropy = 0.25
	e.volumetric_fog_length = 48.0
	e.volumetric_fog_gi_inject = 0.5
	e.volumetric_fog_ambient_inject = 0.5
	e.volumetric_fog_temporal_reprojection_enabled = true
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.05
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 1.6
	e.ssao_intensity = 2.0
	e.ssao_power = 1.6
	e.ssao_light_affect = 0.25
	e.ssil_enabled = true
	e.ssil_radius = 4.0
	e.ssil_intensity = 1.2
	e.ssr_enabled = true
	e.ssr_max_steps = 48
	e.sdfgi_enabled = true
	e.sdfgi_bounce_feedback = 0.6
	e.sdfgi_min_cell_size = 0.18
	e.sdfgi_energy = 1.1
	e.glow_enabled = true
	e.glow_intensity = 1.0
	e.glow_strength = 1.05
	e.glow_bloom = 0.18
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.glow_hdr_threshold = 0.95
	e.glow_hdr_scale = 2.2
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 0.78
	env.environment = e
	parent.add_child(env)

	# Update Chamber so ceiling fixtures match this act's mood.
	var fix_col: Color = fixture_color if fixture_color.a > 0.001 else ambient.lerp(Color.WHITE, 0.45)
	Chamber.current_light_color = fix_col
	Chamber.current_light_energy = fixture_energy if fixture_energy > 0.0 else 2.2
	Chamber.current_light_range = fixture_range if fixture_range > 0.0 else 11.0


static func light_rig_act1(parent: Node3D) -> void:
	# Cryo bay — emergency red, almost ritualistic.
	setup_lighting(parent, Color(0.86, 0.43, 0.43), Color(0.18, 0.05, 0.06), 0.024, 0.20,
		Color(1.0, 0.32, 0.28), 2.6, 10.5)


static func light_rig_act2(parent: Node3D) -> void:
	# Corridors / cabins / decon / med — cool clinical blue-white.
	setup_lighting(parent, Color(0.70, 0.78, 0.86), Color(0.13, 0.16, 0.22), 0.020, 0.22,
		Color(0.88, 0.95, 1.0), 2.4, 11.0)


static func light_rig_act3(parent: Node3D) -> void:
	# Research deck — cold blue-white, brighter task lighting.
	setup_lighting(parent, Color(0.72, 0.84, 0.96), Color(0.11, 0.16, 0.24), 0.017, 0.25,
		Color(0.82, 0.92, 1.0), 2.7, 12.0)


static func light_rig_act4(parent: Node3D) -> void:
	# Array room — dim warm-white, deep dark-blue fog. Mostly black.
	setup_lighting(parent, Color(0.43, 0.39, 0.43), Color(0.03, 0.04, 0.06), 0.028, 0.18,
		Color(0.95, 0.78, 0.55), 1.2, 8.0)


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


static func spawn_player(pos: Vector3, rotation_y: float = 0.0) -> void:
	if GameState.player:
		GameState.player.global_position = pos
		GameState.player.rotation_degrees = Vector3(0, rotation_y, 0)


static func register_intercom(parent: Node3D, intercom_id: int, position: Vector3, rotation_y: float = 0.0, trigger_at: Vector3 = Vector3.INF, radius: float = 3.5, delay: float = 0.0, manual: bool = false) -> IntercomPanel:
	var panel := IntercomPanel.create(position, rotation_y)
	parent.add_child(panel)
	if not manual:
		var trig_pos: Vector3 = position if trigger_at == Vector3.INF else trigger_at
		OlenManager.add_proximity_trigger(intercom_id, trig_pos, panel, radius, delay)
	return panel
