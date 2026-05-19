extends Node
# Per-frame forward raycast + interaction dispatcher.
# Mirrors systems/interaction.py.
#
# An entity becomes interactable by calling Interactable.attach(node, label, kind, data).
# The data is stored in the node's `interact` dict.

const RAY_DIST := 1.8

var player: Node = null
var camera: Camera3D = null

var prompt_label: Label = null
var _examine_root: Control = null
var _terminal_root: Control = null
var _keypad_root: Control = null
var _keypad_buffer := ""
var _keypad_target: Node = null
var _keypad_display: Label = null
var _current_target: Node = null
var _ui_layer: CanvasLayer = null
var modal_open := false


func setup(p_player: Node, p_camera: Camera3D, p_ui: CanvasLayer) -> void:
	player = p_player
	camera = p_camera
	_ui_layer = p_ui
	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	prompt_label.anchor_left = 0.5
	prompt_label.anchor_top = 0.52
	prompt_label.position = Vector2(-80, 0)
	_ui_layer.add_child(prompt_label)


# --- Per-frame --------------------------------------------------------------

func _physics_process(_dt: float) -> void:
	if camera == null:
		return
	if modal_open or NotesManager.is_open:
		prompt_label.text = ""
		_current_target = null
		return
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var to := origin - camera.global_transform.basis.z * RAY_DIST
	var params := PhysicsRayQueryParameters3D.create(origin, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	if player and player.has_method("get_collider_rid"):
		params.exclude = [player.get_collider_rid()]
	var hit := space.intersect_ray(params)
	var target: Node = null
	if not hit.is_empty():
		var ent: Node = hit["collider"]
		# Walk up to a node tagged with interact dict
		while ent and not ent.has_meta("interact"):
			ent = ent.get_parent()
		if ent and ent.has_meta("interact"):
			var data: Dictionary = ent.get_meta("interact")
			var used: bool = ent.has_meta("interact_used") and ent.get_meta("interact_used")
			var kind: String = data.get("kind", "")
			if not used or kind in ["read_terminal", "toggle_door", "keypad", "examine_only", "trigger_event"]:
				target = ent
	_current_target = target
	if target:
		prompt_label.text = "[E] " + target.get_meta("interact")["label"]
	else:
		prompt_label.text = ""


# --- Input dispatch ---------------------------------------------------------

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if _examine_root != null:
				_close_examine()
				return
			if _terminal_root != null:
				_close_terminal()
				return
			if _keypad_root != null:
				_keypad_submit()
				return
			_trigger_current()
			return
		if event.keycode == KEY_ESCAPE:
			if _examine_root: _close_examine()
			if _terminal_root: _close_terminal()
			if _keypad_root: _close_keypad()
			return
		if _keypad_root != null:
			if event.keycode >= KEY_0 and event.keycode <= KEY_9 and _keypad_buffer.length() < 6:
				_keypad_buffer += char(event.unicode)
				_keypad_display.text = _keypad_buffer + "_"
			elif event.keycode == KEY_BACKSPACE:
				_keypad_buffer = _keypad_buffer.substr(0, _keypad_buffer.length() - 1)
				_keypad_display.text = _keypad_buffer + "_"
			elif event.keycode == KEY_ENTER:
				_keypad_submit()


# --- Dispatch ---------------------------------------------------------------

func _trigger_current() -> void:
	var ent := _current_target
	if ent == null:
		return
	var data: Dictionary = ent.get_meta("interact")
	var kind: String = data.get("kind", "")
	match kind:
		"examine_only":
			_examine(data.get("text", ""), data.get("duration", 3.0))
			ent.set_meta("interact_used", true)
		"collect_note":
			NotesManager.collect(data["note_id"])
			ent.queue_free()
		"read_terminal":
			_open_terminal(data.get("title", "TERMINAL"), data.get("text", ""))
		"keypad":
			_open_keypad(ent, data)
		"trigger_event":
			var cb: Callable = data.get("callback", Callable())
			if cb.is_valid():
				cb.call()
			ent.set_meta("interact_used", true)


# --- examine_only -----------------------------------------------------------

func _examine(text: String, duration: float) -> void:
	if _examine_root:
		_examine_root.queue_free()
		_examine_root = null
	_examine_root = Control.new()
	_examine_root.anchor_right = 1.0
	_examine_root.anchor_bottom = 1.0
	_examine_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.anchor_left = 0.10
	bg.anchor_top = 0.75
	bg.anchor_right = 0.90
	bg.anchor_bottom = 0.86
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_examine_root.add_child(bg)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.90))
	lbl.anchor_left = 0.12
	lbl.anchor_top = 0.76
	lbl.anchor_right = 0.88
	lbl.anchor_bottom = 0.85
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_examine_root.add_child(lbl)
	_ui_layer.add_child(_examine_root)
	get_tree().create_timer(duration).timeout.connect(_close_examine)


func _close_examine() -> void:
	if _examine_root and is_instance_valid(_examine_root):
		_examine_root.queue_free()
		_examine_root = null


func show_examine(text: String, duration: float = 3.5) -> void:
	# Public hook for scene callbacks
	_examine(text, duration)


# --- read_terminal ----------------------------------------------------------

func _open_terminal(title: String, body: String) -> void:
	if modal_open: return
	modal_open = true
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_terminal_root = Control.new()
	_terminal_root.anchor_right = 1.0
	_terminal_root.anchor_bottom = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.03, 0.05, 0.96)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_terminal_root.add_child(bg)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color(0.47, 0.86, 0.78))
	t.position = Vector2(80, 60)
	_terminal_root.add_child(t)
	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(0.51, 0.90, 0.78))
	b.position = Vector2(80, 110)
	b.size = Vector2(1120, 550)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_terminal_root.add_child(b)
	var f := Label.new()
	f.text = "Close [E]"
	f.add_theme_color_override("font_color", Color(0.47, 0.86, 0.78))
	f.anchor_left = 0.85
	f.anchor_top = 0.92
	_terminal_root.add_child(f)
	_ui_layer.add_child(_terminal_root)


func _close_terminal() -> void:
	if _terminal_root:
		_terminal_root.queue_free()
		_terminal_root = null
	if modal_open:
		modal_open = false
		GameState.pop_modal()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- keypad ----------------------------------------------------------------

func _open_keypad(ent: Node, data: Dictionary) -> void:
	if modal_open: return
	modal_open = true
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_keypad_target = ent
	_keypad_buffer = ""
	_keypad_root = Control.new()
	_keypad_root.anchor_right = 1.0
	_keypad_root.anchor_bottom = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.anchor_left = 0.35
	bg.anchor_top = 0.25
	bg.anchor_right = 0.65
	bg.anchor_bottom = 0.75
	_keypad_root.add_child(bg)
	var hdr := Label.new()
	hdr.text = "ENTER CODE"
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", Color(0.78, 0.86, 0.94))
	hdr.anchor_left = 0.42
	hdr.anchor_top = 0.30
	_keypad_root.add_child(hdr)
	_keypad_display = Label.new()
	_keypad_display.text = "_"
	_keypad_display.add_theme_font_size_override("font_size", 40)
	_keypad_display.add_theme_color_override("font_color", Color(0.70, 0.94, 0.86))
	_keypad_display.anchor_left = 0.46
	_keypad_display.anchor_top = 0.42
	_keypad_root.add_child(_keypad_display)
	var hint := Label.new()
	hint.text = "[digits]  [Enter] confirm  [Esc] cancel"
	hint.add_theme_color_override("font_color", Color(0.59, 0.67, 0.74))
	hint.anchor_left = 0.38
	hint.anchor_top = 0.66
	_keypad_root.add_child(hint)
	_ui_layer.add_child(_keypad_root)


func _keypad_submit() -> void:
	if _keypad_target == null or _keypad_root == null: return
	var data: Dictionary = _keypad_target.get_meta("interact")
	var expected: String = str(data.get("code", ""))
	if _keypad_buffer == expected:
		AudioManager.keypad_accept()
		var cb: Callable = data.get("on_unlock", Callable())
		_keypad_target.set_meta("interact_used", true)
		_close_keypad()
		if cb.is_valid():
			get_tree().create_timer(0.2).timeout.connect(cb)
	else:
		AudioManager.keypad_reject()
		_keypad_buffer = ""
		_keypad_display.text = "_  (incorrect)"
		get_tree().create_timer(1.2).timeout.connect(func():
			if _keypad_root:
				_keypad_display.text = _keypad_buffer + "_"
		)


func _close_keypad() -> void:
	if _keypad_root:
		_keypad_root.queue_free()
		_keypad_root = null
	_keypad_target = null
	if modal_open:
		modal_open = false
		GameState.pop_modal()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
