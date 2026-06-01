extends Node
# Global horror director. Emits ambient dread (whispers, breath, distant
# booms, heartbeats) on a randomized cadence and broadcasts flicker / blackout
# cues that Flicker components react to. Intensity is set per-act by
# ActUtil.haunt() and scales both frequency and severity.

signal flicker_pulse(strength: float)
signal blackout(duration: float)

const JumpscareOverlay := preload("res://scripts/ui/jumpscare.gd")
const ShadowPassOverlay := preload("res://scripts/ui/shadow_pass.gd")

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
	if r < 0.15:
		AudioManager.whisper()
		flicker_pulse.emit(0.35)
	elif r < 0.26:
		AudioManager.breath()
	elif r < 0.37:
		AudioManager.knock()
		flicker_pulse.emit(0.3)
	elif r < 0.47:
		AudioManager.scrape()
	elif r < 0.56:
		AudioManager.heartbeat()
	elif r < 0.66:
		# The hull flexing — or something large shifting in the dark.
		AudioManager.groan()
	elif r < 0.74:
		# A burst of signal static with a light glitch.
		AudioManager.static_burst()
		flicker_pulse.emit(0.4)
	elif r < 0.82:
		# Phantom footsteps closing in from behind, harder the more haunted.
		if intensity > 0.30:
			footsteps_approach()
		else:
			AudioManager.scrape()
	elif r < 0.90:
		# A far-off cry through the hull — weighted toward the scarier acts.
		if intensity > 0.40:
			AudioManager.distant_scream()
			flicker_pulse.emit(0.5)
		else:
			AudioManager.whisper()
	else:
		AudioManager.boom()
		# Jump-scare odds climb steeply as a room gets more haunted.
		var js_chance := lerpf(0.18, 0.52, clampf((intensity - 0.70) / 0.30, 0.0, 1.0))
		if intensity > 0.70 and randf() < js_chance:
			jump_scare()
		elif intensity > 0.60 and randf() < 0.40:
			creeping_dark()
		elif intensity > 0.55 and randf() < 0.5:
			shadow_pass()
			blackout.emit(randf_range(0.3, 0.7))
		elif intensity > 0.45 and randf() < intensity:
			blackout.emit(randf_range(0.4, 1.0))
		else:
			flicker_pulse.emit(0.85)


# The lights stutter down, a beat of full black, then a breath right at your
# ear — and sometimes a shape sweeps past as they come back.
func creeping_dark() -> void:
	flicker_pulse.emit(0.5)
	get_tree().create_timer(0.45).timeout.connect(func(): flicker_pulse.emit(0.85))
	get_tree().create_timer(0.95).timeout.connect(func(): blackout.emit(randf_range(0.8, 1.6)))
	get_tree().create_timer(1.35).timeout.connect(func():
		AudioManager.breath()
		if intensity > 0.70 and randf() < 0.5:
			shadow_pass())


# A dark figure sweeps across the player's vision (2D overlay) + a whisper.
func shadow_pass() -> void:
	var ui := _ui_layer()
	if ui:
		ui.add_child(ShadowPassOverlay.new())
	AudioManager.whisper()


# Footsteps that approach from behind — getting louder and quicker — then stop
# right at the player's back with a breath and a light stutter. Sometimes a
# shape sweeps past at the end.
func footsteps_approach() -> void:
	_footstep_seq(0, 7)


func _footstep_seq(i: int, total: int) -> void:
	if GameState.player == null:
		return
	if i >= total:
		AudioManager.breath()
		flicker_pulse.emit(0.5)
		if intensity > 0.6 and randf() < 0.4:
			shadow_pass()
		return
	var f := float(i) / float(total - 1)
	AudioManager.footstep(lerpf(-22.0, -7.0, f))
	var gap := lerpf(0.5, 0.17, f)
	get_tree().create_timer(gap).timeout.connect(func(): _footstep_seq(i + 1, total))


# Scripted jump-scare cue (acts call this on key beats).
func sting() -> void:
	AudioManager.shape_sting()
	flicker_pulse.emit(1.0)


func do_blackout(duration: float) -> void:
	AudioManager.power_down()
	blackout.emit(duration)


# Lunge the high-quality 3D entity into the camera, lit, with screen FX on top.
# Virtual, not a photo. Non-lethal — the monster is freed after the flash.
func scare_flash() -> void:
	AudioManager.shape_sting()
	AudioManager.boom()
	blackout.emit(0.7)          # cut the room lights so the lunging face dominates
	flicker_pulse.emit(1.0)
	var ui := _ui_layer()
	if ui:
		ui.add_child(JumpscareOverlay.new())
	var cam: Camera3D = InteractionManager.camera
	var player: Node3D = GameState.player
	if cam == null or player == null or not is_instance_valid(cam):
		return
	var holder: Node = player.get_parent()
	if holder == null:
		return
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3(0, 0, -1)
	fwd = fwd.normalized()
	var kinds := [HorrorShape.KIND_FELIX, HorrorShape.KIND_YUNA, HorrorShape.KIND_HARGROVE]
	var m := HorrorShape.create(kinds[randi() % 3], Vector3.ZERO, 0.0)
	var sv := 2.3
	m.scale = Vector3(sv, sv, sv)
	holder.add_child(m)
	# Put the head right at the camera, just in front of it.
	var base := cam.global_position + fwd * 0.62
	m.global_position = Vector3(base.x, cam.global_position.y - 2.00 * sv + 0.18, base.z)
	m.look_at(Vector3(cam.global_position.x, m.global_position.y, cam.global_position.z), Vector3.UP)
	# Dramatic front light on the face (between face and camera).
	var lt := OmniLight3D.new()
	lt.light_energy = 6.5
	lt.omni_range = 4.5
	lt.light_color = Color(1.0, 0.92, 0.88)
	lt.position = Vector3(0, 2.00, -0.55)
	m.add_child(lt)
	# Lunge in.
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3(sv * 1.25, sv * 1.25, sv * 1.25), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(m):
			m.queue_free())


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
