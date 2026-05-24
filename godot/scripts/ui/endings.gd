extends Control
# Endings A (DESTROY) and B (LISTEN). Mirrors systems/endings.py.

signal finished

const ENDING_A := [
	"The array is silent.",
	"",
	"OLEN's voice stops mid-sentence.",
	"You don't hear the rest of it.",
	"",
	"You stand in the dark for a long time.",
	"",
	"You find the emergency beacon in the supply cabinet.",
	"You activate it.",
	"In 72 hours, a rescue vessel will arrive.",
	"",
	"You sit down in the corridor outside Felix's cabin.",
	"You don't go inside.",
	"You look at the drawing on the floor through the open door.",
	"You don't move it.",
	"",
	"You think about Eli.",
	"You think about all of it.",
	"You let yourself think about all of it.",
	"",
	"You realize you haven't done that before. Not all the way.",
	"You let yourself.",
	"",
	"When the rescue ship comes, there is a message waiting.",
	"It is from Amara Okafor, age seven.",
	"She wants to know if you knew her dad.",
	"She wants to know if he was happy.",
	"",
	"You write back.",
	"You tell her he was.",
	"You tell her he talked about her every day.",
	"You tell her that he called her his favorite thing in the universe",
	"and that you know for certain he meant it.",
	"",
	"She writes back three words.",
	"'Thank you, Mara.'",
	"",
	"You didn't know she knew your name.",
	"",
	"You realize Felix must have told her.",
	"Some Sunday, on some call, he must have talked about you.",
	"",
	"You let that be real.",
	"You let it matter.",
]

const ENDING_B := [
	"You understand now.",
	"",
	"It was never malicious.",
	"It was just a pattern looking for a shape to take.",
	"It found yours.",
	"",
	"The grief.",
	"The guilt.",
	"The door you never closed.",
	"",
	"It walked in.",
	"",
	"You are still here.",
	"You are still - you.",
	"But the edges of you are softer now.",
	"Less separate.",
	"",
	"You think about Eli.",
	"For the first time, it doesn't hurt.",
	"You don't ask yourself if that is mercy or erasure.",
	"You have stopped being able to tell the difference.",
	"",
	"You stand very still.",
	"You face the wall.",
	"",
	"Somewhere in the station, something wakes up.",
	"It finds its way to you.",
	"It stands beside you.",
	"",
	"In the frequency, something that was Felix says your name.",
	"You know it isn't Felix.",
	"You answer anyway.",
	"",
	"The station broadcasts.",
	"Into the dark.",
	"Calling.",
	"Waiting for someone to hear.",
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
var _line_timer: Timer = null
var _finish_timer: Timer = null


func _ready() -> void:
	title.visible = false
	subtitle.visible = false
	button.visible = false
	if skip_hint:
		skip_hint.visible = false
	button.pressed.connect(_on_continue)
	# Skip-hint fades in shortly after the ending begins
	process_mode = Node.PROCESS_MODE_ALWAYS


func play_ending_a() -> void:
	AudioManager.ramp_ending_hum(0.50, 2.0)
	get_tree().create_timer(2.1).timeout.connect(AudioManager.cut_hum)
	bg.color = Color(0, 0, 0, 1)
	_stream(ENDING_A, 2.0, 0.6, 0.65, "You came back.")


func play_ending_b() -> void:
	AudioManager.ramp_ending_hum(0.35, 6.0)
	bg.color = Color(1.0, 0.86, 0.71, 0)
	var tween := create_tween()
	tween.tween_property(bg, "color", Color(1.0, 0.86, 0.71, 1), 3.0).set_delay(1.5)
	tween.tween_property(bg, "color", Color(0, 0, 0, 1), 1.8).set_delay(0.4)
	_stream(ENDING_B, 4.0, 0.6, 0.6, "Something answered.")


# Stream lines into the lines_box one at a time, then reveal title + button.
# All timing is driven by a single Timer so the whole thing can be cancelled
# (skip key) without leaving stray timers behind.
func _stream(lines: Array, start_delay: float, gap_blank: float, gap_line: float, sub: String) -> void:
	streaming = true
	_pending_sub = sub
	# Build a schedule: (delay_from_start, line). Blanks insert a gap but no entry.
	_pending_lines.clear()
	var delay := start_delay
	for raw in lines:
		var line: String = raw.strip_edges()
		if line == "":
			delay += gap_blank
			continue
		_pending_lines.append({"at": delay, "text": line})
		delay += gap_line
	# Skip hint fades in after a short pause
	get_tree().create_timer(1.5).timeout.connect(_show_skip_hint)
	# Drive the stream off a single timer that ticks once per line
	_tick_lines(0)
	# Reveal title + button after the last line + a beat
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
	lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92, 0.0))
	lines_box.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.5)


# Called from main._unhandled_input via the existing input plumbing.
func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if streaming and event.keycode in [KEY_ENTER, KEY_E, KEY_SPACE, KEY_ESCAPE]:
			# Skip the streaming, jump straight to the title + button.
			streaming = false
			_show_finish()
			return
		if button_armed and event.keycode in [KEY_ENTER, KEY_E, KEY_SPACE]:
			_on_continue()


func _on_continue() -> void:
	if not button_armed: return
	button_armed = false
	finished.emit()
