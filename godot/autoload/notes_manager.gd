extends Node
# Tracks collected notes + drives the journal/reader UI.

signal note_collected(note_id: String)

var collected_ids: Array[String] = []
var is_open := false

var _reader_root: Control = null
var _journal_root: Control = null
var _toast_label: Label = null
var _ui_layer: CanvasLayer = null


func setup(ui_layer: CanvasLayer) -> void:
	_ui_layer = ui_layer
	# Toast
	_toast_label = Label.new()
	_toast_label.text = "(Note recovered)"
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.modulate.a = 0.0
	_toast_label.anchor_left = 0.78
	_toast_label.anchor_top = 0.06
	_toast_label.position = Vector2(0, 0)
	_ui_layer.add_child(_toast_label)


func has(note_id: String) -> bool:
	return note_id in collected_ids


func collect(note_id: String) -> void:
	if note_id in collected_ids:
		return
	if not NotesData.ALL.has(note_id):
		return
	collected_ids.append(note_id)
	AudioManager.note_chime()
	_show_toast()
	emit_signal("note_collected", note_id)
	open_reader(note_id)


# Credit the journal without popping the reader - used by the intercom
# note-echo path, which is already streaming an excerpt.
func mark_collected(note_id: String) -> void:
	if note_id in collected_ids:
		return
	if not NotesData.ALL.has(note_id):
		return
	collected_ids.append(note_id)
	AudioManager.note_chime()
	_show_toast()
	emit_signal("note_collected", note_id)


func _show_toast() -> void:
	var tween := create_tween()
	tween.tween_property(_toast_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(2.0)
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.7)


# --- Reader (single note overlay) ----------------------------------------

func open_reader(note_id: String) -> void:
	if is_open:
		return
	var note := NotesData.get_note(note_id)
	if note.is_empty():
		return
	is_open = true
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_reader_root = _build_overlay(note["title"], "(" + note["location"] + ")", note["body"], "Close [E]")
	_ui_layer.add_child(_reader_root)


# --- Journal (Tab) -------------------------------------------------------

func toggle_journal() -> void:
	if is_open:
		close()
		return
	is_open = true
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_journal_root = _build_journal()
	_ui_layer.add_child(_journal_root)


func _build_journal() -> Control:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.96)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var header := Label.new()
	header.text = "RECOVERED:  %d / %d" % [collected_ids.size(), NotesData.ORDER.size()]
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.80, 0.86, 0.95))
	header.position = Vector2(40, 30)
	root.add_child(header)

	var hint := Label.new()
	hint.text = "[Tab] close   [1-9] open note"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.69, 0.78))
	hint.position = Vector2(40, 60)
	root.add_child(hint)

	# Left column - titles
	var y := 100.0
	if collected_ids.is_empty():
		var none := Label.new()
		none.text = "No notes recovered yet."
		none.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
		none.position = Vector2(40, y)
		root.add_child(none)
	for i in collected_ids.size():
		var nid := collected_ids[i]
		var n: Dictionary = NotesData.ALL[nid]
		var title := Label.new()
		title.text = "%d. %s" % [i + 1, n["title"]]
		title.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))
		title.position = Vector2(40, y)
		root.add_child(title)
		var loc := Label.new()
		loc.text = "   (%s)" % n["location"]
		loc.add_theme_font_size_override("font_size", 12)
		loc.add_theme_color_override("font_color", Color(0.59, 0.63, 0.71))
		loc.position = Vector2(40, y + 22)
		root.add_child(loc)
		y += 50

	# Right pane - first note body
	if not collected_ids.is_empty():
		var first: Dictionary = NotesData.ALL[collected_ids[0]]
		var body_title := Label.new()
		body_title.text = first["title"]
		body_title.add_theme_color_override("font_color", Color(0.82, 0.86, 0.90))
		body_title.position = Vector2(700, 100)
		root.add_child(body_title)
		var body := Label.new()
		body.text = first["body"]
		body.add_theme_font_size_override("font_size", 13)
		body.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		body.position = Vector2(700, 130)
		body.size = Vector2(540, 600)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(body)
	return root


# --- Shared overlay builder ---------------------------------------------

func _build_overlay(title: String, location: String, body: String, footer: String) -> Control:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.93)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.90))
	title_lbl.position = Vector2(80, 60)
	root.add_child(title_lbl)

	var loc_lbl := Label.new()
	loc_lbl.text = location
	loc_lbl.add_theme_font_size_override("font_size", 13)
	loc_lbl.add_theme_color_override("font_color", Color(0.63, 0.67, 0.71))
	loc_lbl.position = Vector2(80, 90)
	root.add_child(loc_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.add_theme_font_size_override("font_size", 14)
	body_lbl.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))
	body_lbl.position = Vector2(80, 130)
	body_lbl.size = Vector2(1120, 540)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body_lbl)

	var footer_lbl := Label.new()
	footer_lbl.text = footer
	footer_lbl.add_theme_color_override("font_color", Color(0.70, 0.78, 0.86))
	footer_lbl.anchor_left = 0.85
	footer_lbl.anchor_top = 0.92
	root.add_child(footer_lbl)
	return root


# --- Closing ----------------------------------------------------------

func close() -> void:
	if _reader_root and is_instance_valid(_reader_root):
		_reader_root.queue_free()
		_reader_root = null
	if _journal_root and is_instance_valid(_journal_root):
		_journal_root.queue_free()
		_journal_root = null
	if is_open:
		is_open = false
		GameState.pop_modal()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called by main router on key input
func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_journal()
		elif event.keycode == KEY_E and _reader_root != null:
			close()
		elif event.keycode == KEY_ESCAPE and is_open:
			close()
		elif _journal_root != null and event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = int(event.keycode) - int(KEY_1)
			if idx < collected_ids.size():
				_select_journal(idx)


func _select_journal(idx: int) -> void:
	if _journal_root:
		_journal_root.queue_free()
		_journal_root = null
	# Re-build with the new selection at first position
	var reordered := collected_ids.duplicate()
	# We render the body of `idx` regardless of position by rebuilding with idx as primary
	# (simple: swap idx with 0 temporarily)
	var saved := collected_ids
	collected_ids = [reordered[idx]] + reordered.slice(0, idx) + reordered.slice(idx + 1)
	_journal_root = _build_journal()
	_ui_layer.add_child(_journal_root)
	collected_ids = saved
