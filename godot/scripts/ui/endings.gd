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

var button_armed := false


func _ready() -> void:
	title.visible = false
	subtitle.visible = false
	button.visible = false
	button.pressed.connect(_on_continue)


func play_ending_a() -> void:
	AudioManager.ramp_ending_hum(0.50, 2.0)
	get_tree().create_timer(2.1).timeout.connect(AudioManager.cut_hum)
	bg.color = Color(0, 0, 0, 1)
	_stream(ENDING_A, 4.0, 1.4, 1.2, "You came back.")


func play_ending_b() -> void:
	AudioManager.ramp_ending_hum(0.35, 8.0)
	bg.color = Color(1.0, 0.86, 0.71, 0)
	var tween := create_tween()
	tween.tween_property(bg, "color", Color(1.0, 0.86, 0.71, 1), 4.0).set_delay(2.0)
	tween.tween_property(bg, "color", Color(0, 0, 0, 1), 2.0).set_delay(0.5)
	_stream(ENDING_B, 9.0, 1.4, 1.1, "Something answered.")


func _stream(lines: Array, start_delay: float, gap_blank: float, gap_line: float, sub: String) -> void:
	var delay := start_delay
	for raw in lines:
		var line: String = raw.strip_edges()
		if line == "":
			delay += gap_blank
			continue
		var current_delay := delay
		get_tree().create_timer(current_delay).timeout.connect(
			func(): _add_line(line)
		)
		delay += gap_line
	# Show title + button
	get_tree().create_timer(delay + 2.0).timeout.connect(
		func():
			for c in lines_box.get_children():
				c.queue_free()
			title.visible = true
			subtitle.text = sub
			subtitle.visible = true
	)
	get_tree().create_timer(delay + 5.0).timeout.connect(
		func():
			button.visible = true
			button_armed = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)


func _add_line(line: String) -> void:
	var lbl := Label.new()
	lbl.text = line
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92, 0.0))
	lines_box.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.8)


func handle_input(event: InputEvent) -> void:
	if not button_armed: return
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ENTER, KEY_E, KEY_SPACE]:
			_on_continue()


func _on_continue() -> void:
	if not button_armed: return
	button_armed = false
	finished.emit()
