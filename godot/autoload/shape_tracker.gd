extends Node
# Tracks active Shapes (Felix/Yuna/Hargrove). Drives proximity tone.

var shapes: Array = []
var _proximity_volume := 0.0


func register(shape: Node) -> void:
	shapes.append(shape)


func clear() -> void:
	shapes.clear()
	_proximity_volume = 0.0
	AudioManager.set_signal_proximity_volume(0.0)


func update(player_pos: Vector3, dt: float) -> void:
	var target := 0.0
	for s in shapes:
		if not is_instance_valid(s) or not s.visible:
			continue
		var d := s.global_position.distance_to(player_pos)
		if d < 4.0:
			var v := (1.0 - d / 4.0) * 0.07
			if v > target:
				target = v
		if s.has_method("update_stare"):
			s.update_stare()
	_proximity_volume += (target - _proximity_volume) * min(1.0, dt * 4.0)
	AudioManager.set_signal_proximity_volume(_proximity_volume)
