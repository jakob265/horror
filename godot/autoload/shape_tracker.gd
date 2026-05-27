extends Node
# Tracks active Shapes (Felix/Yuna/Hargrove). Drives proximity tone.

var shapes: Array[Node3D] = []
var _proximity_volume: float = 0.0


func register(shape: Node3D) -> void:
	shapes.append(shape)


func clear() -> void:
	shapes.clear()
	_proximity_volume = 0.0
	AudioManager.set_signal_proximity_volume(0.0)


func update(player_pos: Vector3, dt: float) -> void:
	# Prune freed shapes (e.g. peekers that vanished for good).
	for i in range(shapes.size() - 1, -1, -1):
		if not is_instance_valid(shapes[i]):
			shapes.remove_at(i)
	var target: float = 0.0
	var camera: Camera3D = InteractionManager.camera
	for s in shapes:
		if not is_instance_valid(s):
			continue
		if s.has_method("update_behavior"):
			s.update_behavior(player_pos, camera, dt)
		if not s.visible:
			continue
		var d: float = s.global_position.distance_to(player_pos)
		if d < 4.0:
			var v: float = (1.0 - d / 4.0) * 0.07
			if v > target:
				target = v
		if s.has_method("update_stare"):
			s.update_stare()
	_proximity_volume += (target - _proximity_volume) * minf(1.0, dt * 4.0)
	AudioManager.set_signal_proximity_volume(_proximity_volume)
