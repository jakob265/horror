class_name Interactable
extends RefCounted
# Helper to attach interactable metadata to any 3D node with a collider.

static func attach(node: Node3D, label: String, kind: String, data: Dictionary = {}) -> Node3D:
	var meta := {"label": label, "kind": kind}
	for k in data.keys():
		meta[k] = data[k]
	node.set_meta("interact", meta)
	node.set_meta("interact_used", false)
	# Ensure node is on interactable physics layer
	if node is CollisionObject3D:
		var co: CollisionObject3D = node
		co.collision_layer |= 4
	return node


# Note pickup helper - returns the prop node
static func make_note(parent: Node3D, position: Vector3, note_id: String, label: String = "Read note") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.4, 0.5)
	mesh.mesh = quad
	mesh.rotation_degrees = Vector3(-90, 0, 0)
	mesh.material_override = SurfaceFactory.get_material(SurfaceFactory.CAT_PAPER, Color(0.92, 0.88, 0.78))
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 0.05, 0.5)
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	attach(body, label, "collect_note", {"note_id": note_id})
	return body


# Examine prop helper
static func make_examine(parent: Node3D, position: Vector3, size: Vector3, label: String, text: String, duration: float = 5.0, color: Color = Color(0.55, 0.55, 0.60)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SurfaceFactory.get_material(SurfaceFactory.CAT_PROP, color)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	body.add_child(shape)
	parent.add_child(body)
	attach(body, label, "examine_only", {"text": text, "duration": duration})
	return body
