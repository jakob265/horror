class_name Chamber
extends RefCounted
# Shared geometry helpers. Mirrors scenes/_chamber.py.
# Materials are routed through SurfaceFactory so every box gets PBR
# (procedural normal + roughness + AO) keyed off the box name / tint.

const DOOR_W := 1.4
const DOOR_H := 2.4

# Set by ActUtil.setup_lighting() so add_floor_ceiling can drop matching
# ceiling fixtures automatically. Defaults to a cool clinical white.
static var current_light_color: Color = Color(0.92, 0.95, 1.0)
static var current_light_energy: float = 4.5
static var current_light_range: float = 14.0


static func _make_box(size: Vector3, position: Vector3, color: Color, name: String = "box", with_collider: bool = true, surface: String = "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var cat: String = surface if surface != "" else SurfaceFactory.infer_category(name, color)
	mesh.material_override = SurfaceFactory.get_material(cat, color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh)
	if with_collider:
		var shape := CollisionShape3D.new()
		var col := BoxShape3D.new()
		col.size = size
		shape.shape = col
		body.add_child(shape)
	return body


static func add_floor_ceiling(parent: Node3D, w: float, d: float, h: float, floor_color: Color, ceiling_color: Color, center: Vector3 = Vector3.ZERO) -> void:
	var floor_body := _make_box(Vector3(w, 0.2, d), center + Vector3(0, -0.1, 0), floor_color, "floor")
	parent.add_child(floor_body)
	var ceil_body := _make_box(Vector3(w, 0.2, d), center + Vector3(0, h, 0), ceiling_color, "ceiling")
	parent.add_child(ceil_body)
	_add_ceiling_fixtures(parent, w, d, h, center)


static func _add_ceiling_fixtures(parent: Node3D, w: float, d: float, h: float, center: Vector3) -> void:
	# Layout 1, 2, or 4 fixtures depending on room size, embedded just below
	# the ceiling so they cast realistic downlight. Each fixture is an emissive
	# panel + an OmniLight3D so the room reads even without the flashlight.
	var positions: Array = []
	var area := w * d
	if area < 24.0:
		positions = [Vector3(0, 0, 0)]
	elif area < 80.0:
		positions = [Vector3(0, 0, -d * 0.22), Vector3(0, 0, d * 0.22)]
	else:
		var hx: float = w * 0.22
		var hz: float = d * 0.22
		positions = [
			Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz),
			Vector3(-hx, 0, hz),  Vector3(hx, 0, hz),
		]
	for p_raw in positions:
		var p: Vector3 = center + p_raw + Vector3(0, h - 0.05, 0)
		_make_ceiling_fixture(parent, p)


static func _make_ceiling_fixture(parent: Node3D, pos: Vector3) -> void:
	# Recessed emissive panel
	var panel := MeshInstance3D.new()
	panel.name = "ceiling_fixture"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.06, 0.5)
	panel.mesh = bm
	var emi := StandardMaterial3D.new()
	emi.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	emi.albedo_color = current_light_color
	emi.emission_enabled = true
	emi.emission = current_light_color
	emi.emission_energy_multiplier = 3.0
	panel.material_override = emi
	panel.position = pos
	parent.add_child(panel)
	# Omni light below it
	var light := OmniLight3D.new()
	light.name = "ceiling_light"
	light.light_color = current_light_color
	light.light_energy = current_light_energy
	light.omni_range = current_light_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	light.position = pos + Vector3(0, -0.25, 0)
	parent.add_child(light)


static func add_wall(parent: Node3D, axis: String, fixed: float, span_min: float, span_max: float, h: float, color: Color, gap_center = null) -> void:
	# axis "x" = wall runs along z at fixed x; "z" = wall runs along x at fixed z
	if gap_center == null:
		var length := span_max - span_min
		var pos: Vector3
		var size: Vector3
		if axis == "x":
			pos = Vector3(fixed, h / 2, (span_min + span_max) / 2)
			size = Vector3(0.2, h, length)
		else:
			pos = Vector3((span_min + span_max) / 2, h / 2, fixed)
			size = Vector3(length, h, 0.2)
		parent.add_child(_make_box(size, pos, color, "wall"))
		return
	# With gap
	var gap_half := DOOR_W / 2
	for seg in [[span_min, gap_center - gap_half], [gap_center + gap_half, span_max]]:
		var s_start: float = seg[0]
		var s_end: float = seg[1]
		if s_end <= s_start: continue
		var length := s_end - s_start
		var mid := (s_start + s_end) / 2
		var pos: Vector3
		var size: Vector3
		if axis == "x":
			pos = Vector3(fixed, h / 2, mid)
			size = Vector3(0.2, h, length)
		else:
			pos = Vector3(mid, h / 2, fixed)
			size = Vector3(length, h, 0.2)
		parent.add_child(_make_box(size, pos, color, "wall_seg"))
	# Header above the opening — skip if the ceiling is below the door height
	var header_h: float = max(0.0, h - DOOR_H)
	if header_h > 0.001:
		var hpos: Vector3
		var hsize: Vector3
		if axis == "x":
			hpos = Vector3(fixed, DOOR_H + header_h / 2, gap_center)
			hsize = Vector3(0.2, header_h, DOOR_W + 0.2)
		else:
			hpos = Vector3(gap_center, DOOR_H + header_h / 2, fixed)
			hsize = Vector3(DOOR_W + 0.2, header_h, 0.2)
		parent.add_child(_make_box(hsize, hpos, color, "header"))


static func add_door(parent: Node3D, axis: String, fixed: float, gap_center: float, label: String, color: Color, on_open: Callable = Callable(), interact_label: String = "", sealed: bool = false) -> Node3D:
	var pos: Vector3
	var size: Vector3
	if axis == "x":
		size = Vector3(0.10, DOOR_H, DOOR_W)
		pos = Vector3(fixed, DOOR_H / 2, gap_center)
	else:
		size = Vector3(DOOR_W, DOOR_H, 0.10)
		pos = Vector3(gap_center, DOOR_H / 2, fixed)
	var door := _make_box(size, pos, color, "door_" + label, true, SurfaceFactory.CAT_WALL_METAL)
	# Doorframe trim — thin emissive surround for instant readability
	_add_doorframe(parent, axis, fixed, gap_center)
	parent.add_child(door)
	if not sealed:
		var lbl := interact_label if interact_label != "" else ("Open " + label)
		Interactable.attach(door, lbl, "trigger_event", {
			"callback": func():
				if door.has_meta("opened") and door.get_meta("opened"):
					return
				door.set_meta("opened", true)
				var tween := door.create_tween()
				tween.tween_property(door, "position:y", DOOR_H + DOOR_H / 2, 0.45)
				tween.tween_callback(func():
					door.visible = false
					for c in door.get_children():
						if c is CollisionShape3D:
							c.disabled = true
				)
				AudioManager.door()
				if on_open.is_valid():
					on_open.call()
		})
	return door


static func _add_doorframe(parent: Node3D, axis: String, fixed: float, gap_center: float) -> void:
	# A thin emissive trim around the door so it reads as a portal even unlit.
	var trim_col := Color(0.18, 0.32, 0.42)
	var trim_emit := Color(0.45, 0.78, 0.95)
	var thickness := 0.03
	var depth := 0.18
	var horiz: Vector3
	var vert: Vector3
	var top_pos: Vector3
	var left_pos: Vector3
	var right_pos: Vector3
	if axis == "x":
		# wall runs along z; door normal is x
		horiz = Vector3(depth, thickness, DOOR_W + 2 * thickness)
		vert = Vector3(depth, DOOR_H, thickness)
		top_pos = Vector3(fixed, DOOR_H + thickness / 2, gap_center)
		left_pos = Vector3(fixed, DOOR_H / 2, gap_center - DOOR_W / 2 - thickness / 2)
		right_pos = Vector3(fixed, DOOR_H / 2, gap_center + DOOR_W / 2 + thickness / 2)
	else:
		horiz = Vector3(DOOR_W + 2 * thickness, thickness, depth)
		vert = Vector3(thickness, DOOR_H, depth)
		top_pos = Vector3(gap_center, DOOR_H + thickness / 2, fixed)
		left_pos = Vector3(gap_center - DOOR_W / 2 - thickness / 2, DOOR_H / 2, fixed)
		right_pos = Vector3(gap_center + DOOR_W / 2 + thickness / 2, DOOR_H / 2, fixed)
	for entry in [[horiz, top_pos], [vert, left_pos], [vert, right_pos]]:
		var bm := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = entry[0]
		bm.mesh = box
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.albedo_color = trim_col
		mat.emission_enabled = true
		mat.emission = trim_emit
		mat.emission_energy_multiplier = 1.4
		mat.metallic = 0.6
		mat.roughness = 0.4
		bm.material_override = mat
		bm.position = entry[1]
		parent.add_child(bm)


static func add_room(parent: Node3D, w: float, d: float, h: float, floor_color: Color, ceiling_color: Color, wall_color: Color, center: Vector3 = Vector3.ZERO, entry: Dictionary = {}, exits: Array = []) -> Dictionary:
	# entry/exits items: {axis: "z"|"x", fixed: float, gap: float}
	add_floor_ceiling(parent, w, d, h, floor_color, ceiling_color, center)
	var cx := center.x
	var cz := center.z
	var x_min := cx - w / 2
	var x_max := cx + w / 2
	var z_min := cz - d / 2
	var z_max := cz + d / 2

	# Helper: collect opening per (axis, fixed)
	var openings := {}
	if entry.has("axis"):
		openings[[entry["axis"], entry["fixed"]]] = entry.get("gap", 0.0)
	for ex in exits:
		openings[[ex["axis"], ex["fixed"]]] = ex.get("gap", 0.0)

	# East/west walls
	for fx in [x_min, x_max]:
		var key := ["x", fx]
		add_wall(parent, "x", fx, z_min, z_max, h, wall_color, openings.get(key, null))
	# North/south walls
	for fz in [z_min, z_max]:
		var key := ["z", fz]
		add_wall(parent, "z", fz, x_min, x_max, h, wall_color, openings.get(key, null))
	return {"x_min": x_min, "x_max": x_max, "z_min": z_min, "z_max": z_max}


# Quick textured-box helper for props
static func make_prop_box(parent: Node3D, size: Vector3, position: Vector3, color: Color, with_collider: bool = true, name: String = "prop", surface: String = "") -> StaticBody3D:
	var b := _make_box(size, position, color, name, with_collider, surface)
	parent.add_child(b)
	return b
