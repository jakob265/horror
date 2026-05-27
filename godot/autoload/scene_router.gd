extends Node
# Manages the active act scene + the fade overlay between scenes.

signal scene_changed(act_name: String)

const ACT_SCENES := {
	"act1":         "res://scenes/acts/act1_surface.tscn",
	"act2":         "res://scenes/acts/act2_dormitory.tscn",
	"act_med":      "res://scenes/acts/act_med.tscn",
	"act3":         "res://scenes/acts/act3_mess.tscn",
	"act4":         "res://scenes/acts/act4_lounge.tscn",
	"act_obs":      "res://scenes/acts/act_obs.tscn",
	"act_mess":     "res://scenes/acts/act_mess.tscn",
	"act_comms":    "res://scenes/acts/act_comms.tscn",
	"act5":         "res://scenes/acts/act5_lab.tscn",
	"act6":         "res://scenes/acts/act6_hydro.tscn",
	"act_cargo":    "res://scenes/acts/act_cargo.tscn",
	"act7":         "res://scenes/acts/act7_engineering.tscn",
	"act_eva":      "res://scenes/acts/act_eva.tscn",
	"act_storage":  "res://scenes/acts/act_storage.tscn",
	"act8":         "res://scenes/acts/act8_bridge.tscn",
	"act_maint":    "res://scenes/acts/act_maint.tscn",
	"act9":         "res://scenes/acts/act9_approach.tscn",
	"act10":        "res://scenes/acts/act10_array.tscn",
}

var world_root: Node3D = null
var current_scene: Node3D = null
var fader: ColorRect = null
var _transitioning := false


func setup(p_world_root: Node3D, p_fader: ColorRect) -> void:
	world_root = p_world_root
	fader = p_fader


func transition_to(act_name: String, instant_in: bool = false) -> void:
	if _transitioning:
		return
	if GameState.current_act == act_name:
		return
	if not ACT_SCENES.has(act_name):
		push_warning("Unknown act: " + act_name)
		return
	_transitioning = true

	var swap_target := act_name
	var do_swap := func() -> void:
		_teardown()
		_build(swap_target)
		GameState.current_act = swap_target
		emit_signal("scene_changed", swap_target)
		_transitioning = false
		if instant_in:
			fader.color = Color(0, 0, 0, 0)
		else:
			_fade_from_black(1.2)

	if GameState.current_act == "" and instant_in:
		do_swap.call()
		return
	_fade_to_black(0.8, do_swap)


func _teardown() -> void:
	OlenManager.reset_scene_triggers()
	ShapeTracker.clear()
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null


func _build(act_name: String) -> void:
	var packed: PackedScene = load(ACT_SCENES[act_name])
	if packed == null:
		push_error("Failed to load act scene: " + act_name)
		return
	current_scene = packed.instantiate()
	world_root.add_child(current_scene)


func _fade_to_black(duration: float, on_done: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(fader, "color", Color(0, 0, 0, 1.0), duration)
	tween.tween_callback(on_done)


func _fade_from_black(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fader, "color", Color(0, 0, 0, 0), duration)
