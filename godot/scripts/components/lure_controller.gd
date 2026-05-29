extends Node
class_name LureController

# "The Voice" - the entity, wearing a dead crewmate, calls to you from the dark.
# Answering reveals your position to the nearest hunter. Ignoring costs nothing
# but dread. Cashes the promise in note `v_mess`:
#   "DO NOT ANSWER IF HE CALLS YOU BY YOUR FIRST NAME."

const _PROMPT_TEXT := "[E] answer"

# Config (set by ActUtil.enable_lure).
var voice_name: String = ""
var calls: Array = []           # call/answer pairs: [{call: "...", answer: "..."}, ...]
var gap_min: float = 30.0       # idle gap range (seconds)
var gap_max: float = 70.0
var first_delay: float = 18.0   # never speak in the opening of an act
var window: float = 4.0         # how long the [E] prompt stays answerable
var cooldown: float = 12.0      # after a call resolves, before the next idle gap

# State machine.
enum State { IDLE, CALLING, COOLDOWN }
var _state: int = State.IDLE
var _t: float = 0.0
var _wait: float = 0.0
var _current: Dictionary = {}

# UI.
var _layer: CanvasLayer = null
var _voice_label: Label = null
var _prompt_label: Label = null
var _voice_tween: Tween = null
var _prompt_tween: Tween = null


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_voice_label = _make_label(Color(0.78, 0.84, 0.92, 0.0), 17, true)
	_voice_label.anchor_left = 0.18
	_voice_label.anchor_right = 0.82
	_voice_label.anchor_top = 0.62
	_voice_label.anchor_bottom = 0.72
	_voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_voice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_layer.add_child(_voice_label)
	_prompt_label = _make_label(Color(0.70, 0.78, 0.86, 0.0), 14, false)
	_prompt_label.anchor_left = 0.40
	_prompt_label.anchor_right = 0.60
	_prompt_label.anchor_top = 0.74
	_prompt_label.anchor_bottom = 0.78
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_layer.add_child(_prompt_label)
	_wait = first_delay


func _make_label(color: Color, size: int, italic: bool) -> Label:
	var lbl := Label.new()
	lbl.modulate = color
	lbl.modulate.a = 0.0
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 1.0))
	if italic:
		# A subtle shadow stands in for italics under the default font and reads as
		# "voice in your head" rather than UI text.
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl


func _process(dt: float) -> void:
	_t += dt
	match _state:
		State.IDLE:
			if _t >= _wait and _can_fire():
				_begin_call()
		State.CALLING:
			if _t >= window:
				_timeout()
		State.COOLDOWN:
			if _t >= cooldown:
				_state = State.IDLE
				_t = 0.0
				_wait = randf_range(gap_min, gap_max)


func _can_fire() -> bool:
	if calls.is_empty():
		return false
	if GameState == null or GameState.player == null:
		return false
	if GameState.modal_count > 0:
		return false
	# Don't talk over a world prompt - the player is reading something.
	if InteractionManager != null and InteractionManager.prompt_label != null \
			and InteractionManager.prompt_label.visible:
		return false
	# Find a non-hunting stalker. If every hunter is already on the player,
	# the moment is already loud - wait.
	var has_idle := false
	for s in ShapeTracker.shapes:
		if s == null or not is_instance_valid(s):
			continue
		if s.has_method("is_hunting") and not s.is_hunting():
			has_idle = true
			break
	return has_idle


func _begin_call() -> void:
	_current = calls[randi() % calls.size()]
	_state = State.CALLING
	_t = 0.0
	var line: String = _current.get("call", "")
	if voice_name != "":
		_voice_label.text = "%s: \"%s\"" % [voice_name, line]
	else:
		_voice_label.text = "\"%s\"" % line
	_prompt_label.text = _PROMPT_TEXT
	_fade(_voice_label, 1.0, 0.6, true)
	_fade(_prompt_label, 0.85, 0.6, false)
	AudioManager.whisper_long()


func _input(event: InputEvent) -> void:
	if _state != State.CALLING:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_E:
		_answer()
		get_viewport().set_input_as_handled()


func _answer() -> void:
	var payoff: String = _current.get("answer", "")
	if voice_name != "":
		_voice_label.text = "%s: \"%s\"" % [voice_name, payoff]
	else:
		_voice_label.text = "\"%s\"" % payoff
	_fade(_prompt_label, 0.0, 0.2, false)
	_fade(_voice_label, 1.0, 0.0, true)
	_fade(_voice_label, 0.0, 1.2, true, 2.0)
	AudioManager.shape_sting()
	ScareDirector.sting()
	var target := _nearest_stalker()
	if target != null and GameState.player != null:
		target.alert_to(GameState.player.global_position)
	_state = State.COOLDOWN
	_t = 0.0


func _timeout() -> void:
	_fade(_voice_label, 0.0, 1.0, true)
	_fade(_prompt_label, 0.0, 0.3, false)
	AudioManager.breath()
	_state = State.COOLDOWN
	_t = 0.0


func _nearest_stalker() -> Node:
	var player_pos: Vector3 = GameState.player.global_position
	var best: Node = null
	var best_d := INF
	for s in ShapeTracker.shapes:
		if s == null or not is_instance_valid(s):
			continue
		if not s.has_method("alert_to"):
			continue
		var d: float = (s.global_position - player_pos).length()
		if d < best_d:
			best_d = d
			best = s
	return best


func _fade(lbl: Label, target_a: float, dur: float, is_voice: bool, delay: float = 0.0) -> void:
	var tw: Tween = create_tween()
	if is_voice:
		if _voice_tween != null and _voice_tween.is_valid():
			_voice_tween.kill()
		_voice_tween = tw
	else:
		if _prompt_tween != null and _prompt_tween.is_valid():
			_prompt_tween.kill()
		_prompt_tween = tw
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(lbl, "modulate:a", target_a, dur)
