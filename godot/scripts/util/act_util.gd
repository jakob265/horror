class_name ActUtil
extends RefCounted
# Common helpers for act scripts.


static func setup_lighting(parent: Node3D, ambient: Color, fog_col: Color, fog_density: float = 0.018, ambient_energy: float = 0.7) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient
	e.ambient_light_energy = ambient_energy
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.02, 0.03)
	e.fog_enabled = true
	e.fog_light_color = fog_col
	e.fog_density = fog_density
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.85
	env.environment = e
	parent.add_child(env)


static func light_rig_act1(parent: Node3D) -> void:
	setup_lighting(parent, Color(0.86, 0.43, 0.43), Color(0.18, 0.05, 0.06), 0.020, 0.6)


static func light_rig_act2(parent: Node3D) -> void:
	# corridor / cabins / decon / med - cool blue-grey
	setup_lighting(parent, Color(0.70, 0.78, 0.86), Color(0.16, 0.18, 0.22), 0.018, 0.7)


static func light_rig_act3(parent: Node3D) -> void:
	# research deck - cold blue-white
	setup_lighting(parent, Color(0.70, 0.82, 0.94), Color(0.14, 0.18, 0.24), 0.015, 0.75)


static func light_rig_act4(parent: Node3D) -> void:
	# array room - dim warm-white, deep dark-blue fog
	setup_lighting(parent, Color(0.43, 0.39, 0.43), Color(0.04, 0.05, 0.07), 0.025, 0.45)


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
