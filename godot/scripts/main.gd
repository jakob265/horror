extends Node
# Game entry point. Boots UI, manages menus, drives main loop.

@onready var world_root: Node3D = $WorldRoot
@onready var ui_layer: CanvasLayer = $UILayer
@onready var fader: ColorRect = $UILayer/Fader
@onready var player_holder: Node3D = $WorldRoot/PlayerHolder

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var player: CharacterBody3D = null
var main_menu: Control = null
var pause_menu: Control = null
var hud: Control = null
var ending_overlay: Control = null
var debug_warp: Control = null
var is_paused := false
var in_ending := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	NotesManager.setup(ui_layer)
	OlenManager.setup(ui_layer)
	SceneRouter.setup(world_root, fader)
	_setup_postfx()
	# Show main menu
	_show_main_menu()


# Cinematic overlay over the 3D view (vignette + grain). Sits on a CanvasLayer
# below UILayer so HUD/menus stay crisp. It alpha-composites its own output over
# the 3D (no screen sampling), which is why it renders reliably.
func _setup_postfx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/postfx.gdshader")
	rect.material = mat
	layer.add_child(rect)


func _show_main_menu() -> void:
	if main_menu and is_instance_valid(main_menu):
		main_menu.queue_free()
	main_menu = preload("res://ui/main_menu.tscn").instantiate()
	main_menu.start_new_game.connect(_begin_new_game)
	main_menu.quit_pressed.connect(_quit_app)
	ui_layer.add_child(main_menu)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DiscordRPC.set_menu_state()


func _begin_new_game() -> void:
	if main_menu:
		main_menu.queue_free()
		main_menu = null
	HorrorShape.reset_session()
	GameState.reset_for_new_game()
	ScareDirector.reset()
	# Player
	if player == null:
		player = PLAYER_SCENE.instantiate()
		player_holder.add_child(player)
		GameState.player = player
		InteractionManager.setup(player, player.camera, ui_layer)
		hud = preload("res://ui/hud.tscn").instantiate()
		ui_layer.add_child(hud)
		player.hud = hud
	OlenManager.fired.clear()
	OlenManager.reset_scene_triggers()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SceneRouter.transition_to("act1", true)


func _quit_app() -> void:
	get_tree().quit()


func _process(_dt: float) -> void:
	if player and not is_paused and GameState.modal_count == 0:
		OlenManager.update(player.global_position)
		ShapeTracker.update(player.global_position, _dt)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Debug act-warp (F9), available during gameplay only.
		if event.keycode == KEY_F9 and player and not in_ending and main_menu == null:
			_toggle_debug_warp()
			return
		if debug_warp and is_instance_valid(debug_warp):
			if event.keycode == KEY_ESCAPE:
				_close_debug_warp()
			return
		if event.keycode == KEY_ESCAPE:
			if NotesManager.is_open:
				NotesManager.close()
				return
			if InteractionManager.modal_open or InteractionManager._examine_root or InteractionManager._keypad_root or InteractionManager._terminal_root:
				InteractionManager.handle_input(event)
				return
			if main_menu == null and not in_ending:
				if is_paused:
					_resume_from_pause()
				else:
					_open_pause()
			return
		if event.keycode == KEY_R and is_paused:
			_resume_from_pause()
			return
		if event.keycode == KEY_Q and is_paused:
			_quit_to_menu()
			return
	# Route to subsystems
	NotesManager.handle_input(event)
	InteractionManager.handle_input(event)
	if player and player.has_method("handle_input"):
		player.handle_input(event)
	if GameState.terminal_ui and GameState.terminal_ui.has_method("handle_input"):
		GameState.terminal_ui.handle_input(event)
	# Endings handle their own skip + continue keys
	if in_ending and ending_overlay and ending_overlay.has_method("handle_input"):
		ending_overlay.handle_input(event)


func _toggle_debug_warp() -> void:
	if debug_warp and is_instance_valid(debug_warp):
		_close_debug_warp()
	else:
		_open_debug_warp()


func _open_debug_warp() -> void:
	if debug_warp and is_instance_valid(debug_warp):
		return
	debug_warp = preload("res://scripts/ui/debug_warp.gd").new()
	debug_warp.warp_requested.connect(_on_warp_requested)
	ui_layer.add_child(debug_warp)
	GameState.push_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_debug_warp() -> void:
	if debug_warp and is_instance_valid(debug_warp):
		debug_warp.queue_free()
	debug_warp = null
	GameState.pop_modal()
	if not is_paused and player and main_menu == null and not in_ending:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_warp_requested(act_name: String) -> void:
	_close_debug_warp()
	SceneRouter.transition_to(act_name)


func _open_pause() -> void:
	if is_paused or in_ending or main_menu: return
	is_paused = true
	GameState.push_modal()
	pause_menu = preload("res://ui/pause_menu.tscn").instantiate()
	pause_menu.resume_pressed.connect(_resume_from_pause)
	pause_menu.quit_pressed.connect(_quit_to_menu)
	ui_layer.add_child(pause_menu)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume_from_pause() -> void:
	if not is_paused: return
	is_paused = false
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	GameState.pop_modal()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _quit_to_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	is_paused = false
	SceneRouter._teardown()
	GameState.current_act = ""
	if player:
		player.queue_free()
		player = null
		GameState.player = null
	if hud:
		hud.queue_free()
		hud = null
	AudioManager.cut_hum()
	ScareDirector.reset()
	_show_main_menu()


func start_ending(which: String) -> void:
	if in_ending: return
	in_ending = true
	GameState.push_modal()
	if player:
		player.flashlight.visible = false
	if hud:
		hud.visible = false
	if InteractionManager.prompt_label:
		InteractionManager.prompt_label.visible = false
	ending_overlay = preload("res://ui/endings.tscn").instantiate()
	ending_overlay.finished.connect(_on_ending_done)
	ui_layer.add_child(ending_overlay)
	if which == "A":
		ending_overlay.play_ending_a()
	else:
		ending_overlay.play_ending_b()


func _on_ending_done() -> void:
	in_ending = false
	if ending_overlay:
		ending_overlay.queue_free()
		ending_overlay = null
	if hud:
		hud.visible = true
	if InteractionManager.prompt_label:
		InteractionManager.prompt_label.visible = true
	# Clear the modal stack pushed by start_ending so the player isn't frozen
	# in the seconds before _quit_to_menu disposes the player anyway.
	GameState.modal_count = 0
	_quit_to_menu()
