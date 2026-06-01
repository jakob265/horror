extends Node
# Holds the player's physical items and drives the inventory screen.
# Mirrors NotesManager; item definitions live in InventoryData.

signal item_added(item_id: String)
signal item_removed(item_id: String)

var counts: Dictionary = {}        # id -> int (stackable)
var order: Array[String] = []      # display order (insertion)
var active_item := ""              # highlighted item (for "use on world")
var is_open := false

var _root: Control = null
var _toast: Label = null
var _ui_layer: CanvasLayer = null
var _sel := 0


func setup(ui_layer: CanvasLayer) -> void:
	_ui_layer = ui_layer
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.add_theme_color_override("font_color", Color(0.86, 0.84, 0.66))
	_toast.modulate.a = 0.0
	_toast.anchor_left = 0.74
	_toast.anchor_top = 0.11
	_ui_layer.add_child(_toast)


func reset() -> void:
	if is_open:
		close()
	counts.clear()
	order.clear()
	active_item = ""
	_sel = 0


# --- Item state -----------------------------------------------------------

func has(id: String) -> bool:
	return counts.get(id, 0) > 0


func count(id: String) -> int:
	return counts.get(id, 0)


func add(id: String, n: int = 1) -> void:
	if not InventoryData.ALL.has(id):
		push_warning("InventoryManager: unknown item id '%s'" % id)
		return
	if not counts.has(id):
		order.append(id)
	counts[id] = counts.get(id, 0) + n
	AudioManager.note_chime()
	_show_toast("Picked up: " + InventoryData.name_of(id))
	emit_signal("item_added", id)
	if is_open:
		_rebuild()


func remove(id: String, n: int = 1) -> bool:
	if counts.get(id, 0) < n:
		return false
	counts[id] -= n
	if counts[id] <= 0:
		counts.erase(id)
		order.erase(id)
		if active_item == id:
			active_item = ""
	emit_signal("item_removed", id)
	if is_open:
		_sel = clampi(_sel, 0, maxi(0, order.size() - 1))
		_rebuild()
	return true


func _show_toast(txt: String) -> void:
	_toast.text = txt
	var tween := create_tween()
	tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(2.0)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.7)


# --- Screen ---------------------------------------------------------------

func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or NotesManager.is_open or InteractionManager.modal_open:
		return
	is_open = true
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sel = clampi(_sel, 0, maxi(0, order.size() - 1))
	if not order.is_empty():
		active_item = order[_sel]
	_rebuild()


func close() -> void:
	if _root and is_instance_valid(_root):
		_root.queue_free()
		_root = null
	if is_open:
		is_open = false
		GameState.pop_modal()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild() -> void:
	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = _build()
	_ui_layer.add_child(_root)


func _build() -> Control:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.95)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	root.add_child(bg)

	var header := Label.new()
	header.text = "INVENTORY"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.86, 0.84, 0.70))
	header.position = Vector2(40, 30)
	root.add_child(header)

	var hint := Label.new()
	hint.text = "[Up/Down] select   [1-9] jump   [I] close"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.62, 0.58))
	hint.position = Vector2(40, 60)
	root.add_child(hint)

	if order.is_empty():
		var none := Label.new()
		none.text = "Your hands are empty."
		none.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		none.position = Vector2(40, 110)
		root.add_child(none)
		return root

	var y := 110.0
	for i in order.size():
		var id := order[i]
		var d: Dictionary = InventoryData.ALL[id]
		var sel := i == _sel
		var row := Label.new()
		var n: int = counts[id]
		var label_txt := "%d. %s" % [i + 1, d.get("name", id)]
		if n > 1:
			label_txt += "  x%d" % n
		row.text = ("> " if sel else "   ") + label_txt
		var col: Color = _cat_color(d.get("category", "misc")) if sel else Color(0.78, 0.78, 0.78)
		row.add_theme_color_override("font_color", col)
		row.position = Vector2(40, y)
		root.add_child(row)
		y += 34

	var sid := order[_sel]
	var sd: Dictionary = InventoryData.ALL[sid]
	var dt := Label.new()
	dt.text = sd.get("name", sid)
	dt.add_theme_font_size_override("font_size", 20)
	dt.add_theme_color_override("font_color", _cat_color(sd.get("category", "misc")))
	dt.position = Vector2(620, 110)
	root.add_child(dt)

	var cat := Label.new()
	cat.text = "(" + str(sd.get("category", "misc")).to_upper() + ")"
	cat.add_theme_font_size_override("font_size", 13)
	cat.add_theme_color_override("font_color", Color(0.62, 0.64, 0.66))
	cat.position = Vector2(620, 140)
	root.add_child(cat)

	var desc := Label.new()
	desc.text = sd.get("desc", "")
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))
	desc.position = Vector2(620, 174)
	desc.size = Vector2(560, 420)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(desc)
	return root


func _cat_color(cat: String) -> Color:
	match cat:
		"key": return Color(0.86, 0.78, 0.45)
		"tool": return Color(0.72, 0.80, 0.88)
		"part": return Color(0.82, 0.64, 0.46)
		"fuel": return Color(0.90, 0.68, 0.36)
		"consumable": return Color(0.64, 0.84, 0.64)
		_: return Color(0.80, 0.80, 0.80)


# --- Input (routed from main) ---------------------------------------------

func handle_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := int(event.keycode)
		if k == KEY_E or k == KEY_ESCAPE:
			close()
		elif k == KEY_UP and not order.is_empty():
			_set_sel((_sel - 1 + order.size()) % order.size())
		elif k == KEY_DOWN and not order.is_empty():
			_set_sel((_sel + 1) % order.size())
		elif k >= KEY_1 and k <= KEY_9:
			var idx := int(k) - int(KEY_1)
			if idx < order.size():
				_set_sel(idx)


func _set_sel(idx: int) -> void:
	_sel = idx
	active_item = order[_sel]
	_rebuild()
