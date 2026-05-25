extends Node
# Makes a Light3D flicker / brown out on its own slow cadence and react to
# ScareDirector flicker_pulse / blackout cues (so every light in the room can
# dip together for a synchronized scare).
#
# No class_name on purpose: ActUtil instantiates this via preload().new() so it
# works even on a fresh checkout whose global class-name cache isn't built yet.

var light: Light3D
var base_energy := 1.0
var _t := 0.0
var _next := 4.0
var _restore_at := -1.0
var _blackout_until := -1.0


func setup(p_light: Light3D, rate: float = 1.0) -> void:
	light = p_light
	base_energy = p_light.light_energy
	_next = randf_range(3.0, 8.0) / maxf(0.2, rate)
	ScareDirector.flicker_pulse.connect(_on_pulse)
	ScareDirector.blackout.connect(_on_blackout)


func _process(dt: float) -> void:
	if light == null or not is_instance_valid(light):
		queue_free()
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _blackout_until:
		light.light_energy = base_energy * 0.05
		return
	if _restore_at > 0.0 and now >= _restore_at:
		light.light_energy = base_energy
		_restore_at = -1.0
	_t += dt
	if _t >= _next:
		_t = 0.0
		_next = randf_range(3.5, 9.0)
		_do_flicker(randf_range(0.15, 0.4))


func _do_flicker(strength: float) -> void:
	if light == null or not is_instance_valid(light):
		return
	light.light_energy = base_energy * (1.0 - clampf(strength, 0.0, 0.97))
	_restore_at = Time.get_ticks_msec() / 1000.0 + randf_range(0.04, 0.16)


func _on_pulse(strength: float) -> void:
	_do_flicker(strength)


func _on_blackout(duration: float) -> void:
	_blackout_until = Time.get_ticks_msec() / 1000.0 + duration
