extends Node
# Global horror director. Emits ambient dread (whispers, breath, distant
# booms, heartbeats) on a randomized cadence and broadcasts flicker / blackout
# cues that Flicker components react to. Intensity is set per-act by
# ActUtil.haunt() and scales both frequency and severity.

signal flicker_pulse(strength: float)
signal blackout(duration: float)

const JumpscareOverlay := preload("res://scripts/ui/jumpscare.gd")

var intensity := 0.0          # 0..1
var enabled := false
var _t := 0.0
var _next := 8.0
var _hb_t := 0.0


func reset() -> void:
	intensity = 0.0
	enabled = false
	_t = 0.0
	_hb_t = 0.0
	_next = randf_range(6.0, 10.0)
	AudioManager.stop_music()


func set_intensity(v: float) -> void:
	intensity = clamp(v, 0.0, 1.0)
	enabled = true
	_next = randf_range(lerp(20.0, 6.0, intensity), lerp(34.0, 13.0, intensity))


# Live threat from the nearest visible stalking shape (0..1).
func _threat_level() -> float:
	if ShapeTracker.shapes.is_empty():
		return 0.0
	return clampf(ShapeTracker._proximity_volume / 0.07, 0.0, 1.0)


func _process(dt: float) -> void:
	if not enabled or GameState.player == null:
		return
	# Dynamic-dread music: a floor from the room's intensity plus a live swell
	# whenever a shape is closing in. Keeps playing through note/modal reading.
	var threat := _threat_level()
	AudioManager.set_dread(clampf(intensity * 0.55 + threat * 0.65, 0.0, 1.0))
	if GameState.modal_count > 0:
		return
	# Heartbeat quickens as something gets close.
	if threat > 0.33:
		_hb_t += dt
		if _hb_t >= lerpf(1.5, 0.55, threat):
			_hb_t = 0.0
			AudioManager.heartbeat()
	else:
		_hb_t = 0.0
	# Ambient scare cadence.
	_t += dt
	if _t < _next:
		return
	_t = 0.0
	_next = randf_range(lerp(20.0, 6.0, intensity), lerp(34.0, 13.0, intensity))
	_emit_scare()


func _emit_scare() -> void:
	var r := randf()
	if r < 0.28:
		AudioManager.whisper()
		flicker_pulse.emit(0.35)
	elif r < 0.46:
		AudioManager.breath()
	elif r < 0.60:
		AudioManager.knock()
		flicker_pulse.emit(0.3)
	elif r < 0.74:
		AudioManager.scrape()
	elif r < 0.86:
		AudioManager.heartbeat()
	else:
		AudioManager.boom()
		if intensity > 0.70 and randf() < 0.22:
			jump_scare()
		elif intensity > 0.45 and randf() < intensity:
			blackout.emit(randf_range(0.4, 1.0))
		else:
			flicker_pulse.emit(0.85)


# Scripted jump-scare cue (acts call this on key beats).
func sting() -> void:
	AudioManager.shape_sting()
	flicker_pulse.emit(1.0)


func do_blackout(duration: float) -> void:
	AudioManager.power_down()
	blackout.emit(duration)


# Flash the procedural screamer face full-screen with a stinger + blackout.
# The overlay plays its own audio in _ready.
func scare_flash() -> void:
	var ui := _ui_layer()
	if ui == null:
		AudioManager.shape_sting()
		AudioManager.boom()
		blackout.emit(0.5)
		return
	ui.add_child(JumpscareOverlay.new())
	blackout.emit(0.55)
	flicker_pulse.emit(1.0)


# A full jump scare: a beat of build-up, then the face. Non-lethal.
func jump_scare() -> void:
	if GameState.player == null:
		return
	AudioManager.set_dread(1.0)
	AudioManager.breath()
	get_tree().create_timer(0.7).timeout.connect(scare_flash)


func _ui_layer() -> Node:
	var main := get_tree().root.get_node_or_null("Main")
	return main.get_node_or_null("UILayer") if main else null
