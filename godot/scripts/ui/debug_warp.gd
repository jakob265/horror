extends Control
# Password-gated debug act-warp. Toggled with F9 during gameplay (main.gd).
# Enter the access code, then pick any act to jump straight to it — handy for
# inspecting rooms without playing through. Change ACCESS_CODE to rebind.

const ACCESS_CODE := "442K"

signal warp_requested(act_name: String)

var _field: LineEdit
var _msg: Label
var _list: VBoxContainer
var _unlocked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(540, 0)
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "//  DEBUG WARP  //"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 0.96))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_msg = Label.new()
	_msg.text = "Enter access code:"
	_msg.add_theme_color_override("font_color", Color(0.85, 0.86, 0.90))
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_msg)

	_field = LineEdit.new()
	_field.secret = true
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.placeholder_text = "code"
	_field.custom_minimum_size = Vector2(0, 38)
	_field.text_submitted.connect(_on_submit)
	box.add_child(_field)

	_list = VBoxContainer.new()
	_list.visible = false
	_list.add_theme_constant_override("separation", 8)
	box.add_child(_list)

	var hint := Label.new()
	hint.text = "F9 / Esc to close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.56, 0.62))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	_field.call_deferred("grab_focus")


func _on_submit(text: String) -> void:
	if _unlocked:
		return
	if text.strip_edges() == ACCESS_CODE:
		_unlock()
	else:
		_msg.text = "ACCESS DENIED"
		_msg.add_theme_color_override("font_color", Color(0.92, 0.26, 0.20))
		_field.clear()


func _unlock() -> void:
	_unlocked = true
	_field.visible = false
	_msg.text = "Select destination:"
	_msg.add_theme_color_override("font_color", Color(0.62, 0.92, 0.66))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_list.add_child(grid)
	for key in SceneRouter.ACT_SCENES.keys():
		var b := Button.new()
		b.text = key
		b.custom_minimum_size = Vector2(168, 34)
		b.pressed.connect(_on_pick.bind(key))
		grid.add_child(b)
	_list.visible = true


func _on_pick(act_name: String) -> void:
	warp_requested.emit(act_name)
