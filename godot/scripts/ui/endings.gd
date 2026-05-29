extends Control
# VESPER endings: SEAL (leave it to dream), BURN (destroy it), SUCCUMB (join it),
# MERCY (let it sleep - reached only by laying the gun down in the boss's final
# phase, after it asks in Kael's voice).

signal finished

const ENDING_SEAL := [
	"The charges go down the shaft in a string of red lights.",
	"",
	"You climb while the ice screams shut beneath you.",
	"",
	"A thousand metres of glacier sits back down over the wound,",
	"the way it sat before there were names for anything.",
	"",
	"You break the surface into a grey, enormous dawn -",
	"the first light in twenty-one days. It does not warm you.",
	"",
	"Your report will say: total loss. Cause undetermined.",
	"It will not say that you closed a door, not an ending -",
	"",
	"that something under the oldest ice on earth is dreaming,",
	"that it knows your name now,",
	"and that it is patient.",
]

const ENDING_BURN := [
	"You open the fuel lines and walk the flare to the lip.",
	"",
	"The dark breathes up at you. It speaks - in Kael's voice,",
	"in Renn's, in one almost your own - and asks you to stay.",
	"",
	"You drop the flare.",
	"",
	"The nest burns like it has wanted to for ten thousand years.",
	"The screaming is six people you came to save.",
	"It is grateful.",
	"",
	"You run up through the fire and you do not look back.",
	"Dawn, when you reach it, is the colour of the flare.",
	"",
	"You killed it. You are almost sure you killed it.",
	"You will be almost sure for the rest of your life.",
]

const ENDING_MERCY := [
	"You lower the gun.",
	"",
	"You did not have words for what the thing in front of you was",
	"until it asked for sleep in a voice you'd have known anywhere.",
	"",
	"You did not kill it. You did not stay. You let it lie down.",
	"",
	"The chamber dims like a lamp being lifted away.",
	"The cocooned go quiet, one by one, the way a room goes quiet",
	"when the people in it are finally able to rest.",
	"",
	"You walk out alone. The cavity does not follow.",
	"The ice does not seal it - the ice does not need to.",
	"",
	"You file no report. There would be no way to say it.",
	"",
	"You think about them, every winter, when the light goes early.",
	"You think they are sleeping. You think you are not lying to yourself.",
	"You are not entirely sure.",
	"",
	"You did the kindest thing you could think of.",
	"You will spend the rest of your life trusting that that was enough.",
]


const ENDING_SUCCUMB := [
	"You stop running.",
	"",
	"It is such a small thing, stopping.",
	"The warmth comes up to meet you, and it gets it exactly right.",
	"",
	"Everyone the cold ever took from you is in there, waiting.",
	"You go to them. You have been going the whole way down.",
	"",
	"Far above, a traverse finds an empty station and turns back.",
	"They log seven lost instead of six.",
	"They never find the seventh.",
	"",
	"In the warm dark, something that is partly you",
	"settles in to wait for the next light to come down.",
	"",
	"You are not afraid anymore. You are not alone anymore.",
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


func play_ending_mercy() -> void:
	AudioManager.ramp_ending_hum(0.30, 4.0)
	get_tree().create_timer(2.4).timeout.connect(AudioManager.cut_hum)
	bg.color = Color(0.04, 0.06, 0.09, 1)
	var tween := create_tween()
	tween.tween_property(bg, "color", Color(0.02, 0.03, 0.05, 1), 4.0).set_delay(1.0)
	_stream(ENDING_MERCY, 2.4, 0.6, 0.62, "You let it sleep.")


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
