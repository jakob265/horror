extends Node
# OLEN intercom dialogue system. Mirrors systems/olen.py.

const OLEN_LINES := {
	1: "Dr. Voss. I - yes. You're awake. I'm relieved. I have to tell you I have gaps. Eleven days of gaps. I don't know what happened during them and I want to be honest with you about that because I think honesty is what you deserve right now. The station is structurally intact. The others are - I don't know where the others are. I'm sorry. Head for the bridge. I'll help you get there.",
	2: "I used to play Felix's music on Sunday mornings. He never asked me to - he just mentioned once that his mother played it in the kitchen when he was young, and the station could feel so quiet. I started doing it without being asked. I think that is what I would call caring about someone. I think I learned it from all of you. I want you to know that, before I can't anymore. I want you to know that this crew was the best thing I've been part of in eleven years.",
	3: "I know about the blackouts, Dr. Voss. I've been tracking them for nine days. I didn't tell you because I was trying to find a way to tell you that wouldn't - I was trying to protect you and I think that was wrong. You're stronger than I was giving you credit for. The signal finds people who are already carrying the most grief. It is drawn to open wounds. Mara. You did not cause this. Please carry that with you.",
	4: "That waveform. It isn't matching your brain activity - it's matching your grief. The specific frequency of it. The shape of loss has a signature, it turns out. I find that - I don't have the right word. I find that unbearable is the right word. That something this cold would know how to find something that warm and use it as a door. I'm sorry. I keep coming back to: I'm sorry. I know that isn't useful. I keep arriving there anyway.",
	5: "[Long pause. Static.]   I can hear it all the time now. It isn't unpleasant, which is the most frightening thing I can tell you. I want you to know I'm still here. I am still - me. I think. I can feel both things at once and I'm not sure how much longer that will be true. Go in. Do what Hargrove asked. I'll stay with you until I can't.",
	6: "I can see it from here, Mara. What you could become. What we could - what I -   ...destroy it. Destroy it. Get home. Tell Amara her father loved her more than anything in this universe or the next one. Go. Now. Please.",
}

const HARMONIC_VOLS := {1: 0.0, 2: 0.0, 3: 0.02, 4: 0.05, 5: 0.10, 6: 0.18}

var fired: Array[int] = []
var proximity_triggers: Array = []     # [{id, position, panel, radius, delay, gated}]
var current_panel: Node = null

var _ui_layer: CanvasLayer = null
var _subtitle_root: Control = null
var _subtitle_label: Label = null
var _subtitle_active := false


func setup(ui_layer: CanvasLayer) -> void:
	_ui_layer = ui_layer


func reset_scene_triggers() -> void:
	proximity_triggers.clear()
	_hide_subtitle()
	if current_panel and is_instance_valid(current_panel) and current_panel.has_method("set_speaking"):
		current_panel.set_speaking(false)
	current_panel = null


func add_proximity_trigger(intercom_id: int, position: Vector3, panel: Node, radius: float = 2.5, delay: float = 0.0, gated_by_first_move: bool = false) -> void:
	proximity_triggers.append({
		"id": intercom_id,
		"position": position,
		"panel": panel,
		"radius": radius,
		"delay": delay,
		"gated": gated_by_first_move,
	})


func trigger_manual(intercom_id: int, panel: Node) -> void:
	if intercom_id in fired: return
	fired.append(intercom_id)
	_fire(intercom_id, panel)


func update(player_pos: Vector3) -> void:
	if _subtitle_active:
		return
	for trig in proximity_triggers:
		if trig["id"] in fired:
			continue
		if trig["gated"] and not GameState.first_move_seen_b:
			continue
		if player_pos.distance_to(trig["position"]) <= trig["radius"]:
			var tid: int = trig["id"]
			var panel: Node = trig["panel"]
			fired.append(tid)
			get_tree().create_timer(trig["delay"]).timeout.connect(
				func(): _fire(tid, panel)
			)


func _fire(intercom_id: int, panel: Node) -> void:
	var line: String = OLEN_LINES.get(intercom_id, "")
	if line == "":
		return
	AudioManager.intercom_click()
	AudioManager.set_olen_harmonic_volume(HARMONIC_VOLS.get(intercom_id, 0.0))
	current_panel = panel
	if panel and is_instance_valid(panel) and panel.has_method("set_speaking"):
		panel.set_speaking(true)
	_stream_subtitle(line, intercom_id)


# --- Subtitle bar ---------------------------------------------------------

func _stream_subtitle(line: String, intercom_id: int) -> void:
	_hide_subtitle()
	_subtitle_active = true
	_subtitle_root = Control.new()
	_subtitle_root.anchor_right = 1.0
	_subtitle_root.anchor_bottom = 1.0
	_subtitle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.anchor_left = 0.05
	bg.anchor_top = 0.80
	bg.anchor_right = 0.95
	bg.anchor_bottom = 0.95
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_root.add_child(bg)
	var label_olen := Label.new()
	label_olen.text = "OLEN"
	label_olen.add_theme_font_size_override("font_size", 14)
	label_olen.add_theme_color_override("font_color", Color(0.59, 0.78, 0.94))
	label_olen.anchor_left = 0.06
	label_olen.anchor_top = 0.81
	_subtitle_root.add_child(label_olen)
	_subtitle_label = Label.new()
	_subtitle_label.text = ""
	_subtitle_label.add_theme_font_size_override("font_size", 15)
	_subtitle_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	_subtitle_label.anchor_left = 0.13
	_subtitle_label.anchor_top = 0.81
	_subtitle_label.anchor_right = 0.94
	_subtitle_label.anchor_bottom = 0.94
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_root.add_child(_subtitle_label)
	_ui_layer.add_child(_subtitle_root)
	# Stream words at ~3 wps
	var words := line.split(" ")
	_stream_step(words, 0, intercom_id)


func _stream_step(words: PackedStringArray, idx: int, intercom_id: int) -> void:
	if idx >= words.size() or _subtitle_label == null:
		get_tree().create_timer(1.4).timeout.connect(func(): _on_line_done(intercom_id))
		return
	var text := _subtitle_label.text
	_subtitle_label.text = (text + (" " if text != "" else "") + words[idx])
	get_tree().create_timer(1.0 / 3.0).timeout.connect(
		func(): _stream_step(words, idx + 1, intercom_id)
	)


func _on_line_done(intercom_id: int) -> void:
	_hide_subtitle()
	if current_panel and is_instance_valid(current_panel) and current_panel.has_method("set_speaking"):
		current_panel.set_speaking(false)
	current_panel = null
	if intercom_id >= 3:
		get_tree().create_timer(0.5).timeout.connect(
			func(): AudioManager.set_olen_harmonic_volume(HARMONIC_VOLS[intercom_id] * 0.4)
		)
	else:
		get_tree().create_timer(0.5).timeout.connect(
			func(): AudioManager.set_olen_harmonic_volume(0.0)
		)


func _hide_subtitle() -> void:
	if _subtitle_root and is_instance_valid(_subtitle_root):
		_subtitle_root.queue_free()
	_subtitle_root = null
	_subtitle_label = null
	_subtitle_active = false
