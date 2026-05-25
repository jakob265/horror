extends Node
# Global horror director. Emits ambient dread (whispers, breath, distant
# booms, heartbeats) on a randomized cadence and broadcasts flicker / blackout
# cues that Flicker components react to. Intensity is set per-act by
# ActUtil.haunt() and scales both frequency and severity.

signal flicker_pulse(strength: float)
signal blackout(duration: float)

var intensity := 0.0          # 0..1
var enabled := false
var _t := 0.0
var _next := 8.0


func reset() -> void:
	intensity = 0.0
	enabled = false
	_t = 0.0
	_next = randf_range(6.0, 10.0)


func set_intensity(v: float) -> void:
	intensity = clamp(v, 0.0, 1.0)
	enabled = true
	_next = randf_range(lerp(20.0, 6.0, intensity), lerp(34.0, 13.0, intensity))


func _process(dt: float) -> void:
	if not enabled or GameState.player == null or GameState.modal_count > 0:
		return
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
		if intensity > 0.45 and randf() < intensity:
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
