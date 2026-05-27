extends Control
# VESPER endings: SEAL (leave it to dream), BURN (destroy it), SUCCUMB (join it).

signal finished

const ENDING_SEAL := [
	"The charges go down the shaft in a string of dull red lights.",
	"",
	"You climb.",
	"Hand over hand up the cage cable, while the ice screams below you.",
	"",
	"The cavity folds in on itself - a thousand metres of glacier",
	"sitting back down over a wound, the way it sat before,",
	"for longer than there have been names for anything.",
	"",
	"You break the surface into a grey and enormous dawn.",
	"The first light in twenty-one days.",
	"It does not warm you. Nothing will, for a while.",
	"",
	"The traverse finds you two days later, half-frozen,",
	"unable to stop watching the ice. They ask you nothing.",
	"",
	"Your report says: total loss. No survivors. Cause undetermined.",
	"All of it true.",
	"",
	"You do not write that it is still down there.",
	"That you closed a door, not an ending.",
	"That something under the oldest ice on earth is dreaming,",
	"and it knows your name now,",
	"and it is patient.",
]

const ENDING_BURN := [
	"You open every fuel line in the plant",
	"and walk the flare back to the lip of the shaft.",
	"",
	"The warm dark breathes up at you. It speaks -",
	"in Kael's voice, in Renn's, in a voice almost your own -",
	"and it asks you, kindly, to stay.",
	"",
	"You drop the flare.",
	"",
	"The nest takes light like something that has wanted",
	"to burn for ten thousand years.",
	"The screaming is the worst sound you will ever hear,",
	"because it is six people you came to save,",
	"and it is grateful.",
	"",
	"You run up through a station turning to fire behind you.",
	"You do not look back. There is nothing back there",
	"you could survive seeing.",
	"",
	"Dawn, when you reach it, is the colour of the flare.",
	"Vesper burns on the ice for three days.",
	"",
	"You killed it. You are almost sure you killed it.",
	"You will spend the rest of your life being almost sure.",
]

const ENDING_SUCCUMB := [
	"You stop running.",
	"",
	"It is such a small thing, stopping.",
	"You wonder why it took the whole way down to learn how.",
	"",
	"The warmth comes up out of the dark to meet you,",
	"and it gets the warmth exactly right.",
	"",
	"Everyone you ever lost to the plain cold work of living",
	"is in there, waiting, and not gone after all.",
	"You go to them. You have been going to them",
	"since the cage first dropped.",
	"",
	"The cold was never the enemy.",
	"The cold was the invitation.",
	"",
	"Far above, a traverse reaches an empty station and turns back.",
	"They log seven lost instead of six.",
	"They never find the seventh.",
	"",
	"Under the ice, in the warm dark, something partly you",
	"settles in to wait for the next light to come drilling down.",
	"",
	"You are not afraid anymore.",
	"You are not alone anymore.",
	"You are not.",
]

@onready var bg: ColorRect = $BG
@onready var lines_box: VBoxContainer = $LinesBox
@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var button: Button = $Continue
@onready var skip_hint: Label = $SkipHint

var button_armed := false
var streaming := false
var _pending_lines: Array = []
var _pending_sub: String = ""


func _ready() -> void:
	title.visible = false
	subtitle.visible = false
	button.visible = false
	if skip_hint:
		skip_hint.visible = false
	button.pressed.connect(_on_continue)
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_ending_seal() -> void:
	AudioManager.ramp_ending_hum(0.50, 2.0)
	get_tree().create_timer(2.1).timeout.connect(AudioManager.cut_hum)
	bg.color = Color(0, 0, 0, 1)
	_stream(ENDING_SEAL, 2.0, 0.6, 0.62, "You sealed it.")


func play_ending_burn() -> void:
	AudioManager.ramp_ending_hum(0.45, 3.0)
	bg.color = Color(0.5, 0.12, 0.05, 0)
	var tween := create_tween()
	tween.tween_property(bg, "color", Color(0.6, 0.18, 0.06, 1), 2.5).set_delay(1.0)
	tween.tween_property(bg, "color", Color(0, 0, 0, 1), 2.2).set_delay(0.6)
	_stream(ENDING_BURN, 2.0, 0.6, 0.62, "You burned it out.")


func play_ending_succumb() -> void:
	AudioManager.ramp_ending_hum(0.35, 6.0)
	bg.color = Color(0.7, 0.78, 0.9, 0)
	var tween := create_tween()
	tween.tween_property(bg, "color", Color(0.7, 0.78, 0.9, 1), 3.5).set_delay(1.5)
	tween.tween_property(bg, "color", Color(0, 0, 0, 1), 2.0).set_delay(0.4)
	_stream(ENDING_SUCCUMB, 4.0, 0.6, 0.6, "You stayed.")


func _stream(lines: Array, start_delay: float, gap_blank: float, gap_line: float, sub: String) -> void:
	streaming = true
	_pending_sub = sub
	_pending_lines.clear()
	var delay := start_delay
	for raw in lines:
		var line: String = raw.strip_edges()
		if line == "":
			delay += gap_blank
			continue
		_pending_lines.append({"at": delay, "text": line})
		delay += gap_line
	get_tree().create_timer(1.5).timeout.connect(_show_skip_hint)
	_tick_lines(0)
	_schedule_finish(delay + 1.4)


func _tick_lines(idx: int) -> void:
	if not streaming or idx >= _pending_lines.size():
		return
	var entry: Dictionary = _pending_lines[idx]
	var at: float = float(entry["at"])
	var t := get_tree().create_timer(at if idx == 0 else max(0.05, float(_pending_lines[idx]["at"]) - float(_pending_lines[idx - 1]["at"])))
	t.timeout.connect(func():
		if not streaming or not is_instance_valid(self):
			return
		_add_line(entry["text"])
		_tick_lines(idx + 1)
	)


func _schedule_finish(after: float) -> void:
	get_tree().create_timer(after).timeout.connect(func():
		if not streaming or not is_instance_valid(self):
			return
		_show_finish()
	)


func _show_skip_hint() -> void:
	if skip_hint and is_instance_valid(skip_hint):
		skip_hint.visible = true
		var tween := create_tween()
		skip_hint.modulate.a = 0.0
		tween.tween_property(skip_hint, "modulate:a", 1.0, 0.8)


func _show_finish() -> void:
	for c in lines_box.get_children():
		c.queue_free()
	title.visible = true
	subtitle.text = _pending_sub
	subtitle.visible = true
	if skip_hint:
		skip_hint.visible = false
	button.visible = true
	button_armed = true
	streaming = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	button.grab_focus()


func _add_line(line: String) -> void:
	var lbl := Label.new()
	lbl.text = line
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92, 1.0))
	lbl.modulate.a = 0.0
	lines_box.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.5)


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if streaming and event.keycode in [KEY_ENTER, KEY_E, KEY_SPACE, KEY_ESCAPE]:
			streaming = false
			_show_finish()
			return
		if button_armed and event.keycode in [KEY_ENTER, KEY_E, KEY_SPACE]:
			_on_continue()


func _on_continue() -> void:
	if not button_armed: return
	button_armed = false
	finished.emit()
