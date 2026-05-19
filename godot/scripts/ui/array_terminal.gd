class_name ArrayTerminal
extends Control
# Two-option modal terminal at the foot of the array tower.
# DESTROY (with confirm) -> Ending A.  LISTEN -> Ending B.
# After 15 idle seconds the LISTEN button starts pulsing.

signal chose_destroy
signal chose_listen

const PULSE_DELAY := 15.0
const PULSE_PERIOD := 4.0

var destroy_btn: Button
var listen_btn: Button
var confirming := false
var confirm_root: Control = null
var opened_at_ms: int = 0
var pulse_t := 0.0
var pulse_active := false


static func create() -> ArrayTerminal:
	var t := ArrayTerminal.new()
	t.anchor_right = 1.0
	t.anchor_bottom = 1.0
	t._build()
	return t


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := Label.new()
	title.text = "ARRAY CONTROL TERMINAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.47, 0.86, 0.78))
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.18
	title.position = Vector2(0, 0)
	add_child(title)

	var sub := Label.new()
	sub.text = "Select an action."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.70, 0.86, 0.90, 0.85))
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.anchor_top = 0.26
	add_child(sub)

	destroy_btn = Button.new()
	destroy_btn.text = "[ DESTROY TRANSMITTER - EMERGENCY DISCHARGE PROTOCOL ]"
	destroy_btn.anchor_left = 0.25
	destroy_btn.anchor_right = 0.75
	destroy_btn.anchor_top = 0.46
	destroy_btn.offset_top = -28
	destroy_btn.offset_bottom = 28
	destroy_btn.add_theme_color_override("font_color", Color(0.94, 0.86, 0.86))
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0.31, 0.12, 0.12)
	destroy_btn.add_theme_stylebox_override("normal", dsb)
	add_child(destroy_btn)
	destroy_btn.pressed.connect(_choose_destroy)

	listen_btn = Button.new()
	listen_btn.text = "[ LISTEN ]"
	listen_btn.anchor_left = 0.25
	listen_btn.anchor_right = 0.75
	listen_btn.anchor_top = 0.58
	listen_btn.offset_top = -28
	listen_btn.offset_bottom = 28
	listen_btn.add_theme_color_override("font_color", Color(0.86, 0.94, 0.94))
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.12, 0.23, 0.31)
	listen_btn.add_theme_stylebox_override("normal", lsb)
	add_child(listen_btn)
	listen_btn.pressed.connect(_choose_listen)

	var hint := Label.new()
	hint.text = "(15 seconds.  Something is waiting.)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.62, 0.70, 0.78, 0.78))
	hint.add_theme_font_size_override("font_size", 13)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 0.72
	add_child(hint)


func open() -> void:
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened_at_ms = Time.get_ticks_msec()


func _process(dt: float) -> void:
	var elapsed := (Time.get_ticks_msec() - opened_at_ms) / 1000.0
	if elapsed >= PULSE_DELAY and not pulse_active:
		pulse_active = true
	if pulse_active and listen_btn:
		pulse_t += dt
		var v := 0.5 + 0.5 * sin(pulse_t * (TAU / PULSE_PERIOD))
		var sb := listen_btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			sb.bg_color = Color(0.16 + 0.39 * v, 0.31 + 0.47 * v, 0.43 + 0.51 * v)


func handle_input(event: InputEvent) -> void:
	if confirming: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_choose_destroy()
		elif event.keycode == KEY_2:
			_choose_listen()


func _choose_destroy() -> void:
	if confirming: return
	confirming = true
	destroy_btn.disabled = true
	listen_btn.disabled = true

	confirm_root = Control.new()
	confirm_root.anchor_right = 1.0
	confirm_root.anchor_bottom = 1.0
	add_child(confirm_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.97)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	confirm_root.add_child(bg)

	var msg := Label.new()
	msg.text = "This action is irreversible.\nConfirm?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 22)
	msg.add_theme_color_override("font_color", Color(0.94, 0.78, 0.78))
	msg.anchor_left = 0.0
	msg.anchor_right = 1.0
	msg.anchor_top = 0.36
	confirm_root.add_child(msg)

	var c_btn := Button.new()
	c_btn.text = "[ CONFIRM DESTROY ]"
	c_btn.anchor_left = 0.35
	c_btn.anchor_right = 0.65
	c_btn.anchor_top = 0.52
	c_btn.offset_top = -28
	c_btn.offset_bottom = 28
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.47, 0.08, 0.08)
	c_btn.add_theme_stylebox_override("normal", csb)
	c_btn.add_theme_color_override("font_color", Color(0.96, 0.84, 0.84))
	confirm_root.add_child(c_btn)
	c_btn.pressed.connect(_do_destroy)

	var x_btn := Button.new()
	x_btn.text = "[ Cancel ]"
	x_btn.anchor_left = 0.35
	x_btn.anchor_right = 0.65
	x_btn.anchor_top = 0.62
	x_btn.offset_top = -28
	x_btn.offset_bottom = 28
	confirm_root.add_child(x_btn)
	x_btn.pressed.connect(_cancel_destroy)


func _cancel_destroy() -> void:
	if confirm_root:
		confirm_root.queue_free()
		confirm_root = null
	confirming = false
	destroy_btn.disabled = false
	listen_btn.disabled = false


func _do_destroy() -> void:
	chose_destroy.emit()


func _choose_listen() -> void:
	if confirming: return
	chose_listen.emit()


func close() -> void:
	GameState.pop_modal()
	queue_free()
