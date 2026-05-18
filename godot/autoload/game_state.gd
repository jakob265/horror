extends Node
# Cross-scene flags + global game-state container.

signal modal_count_changed(count: int)
signal first_move_seen

# Per-run flags
var cryo_keycard := false
var cryo_door_open := false
var hatch_open := false
var array_keycard := false
var array_door_open := false
var decon_door_open := false
var med_door_open := false
var approach_door_open := false

# Stored references
var player: Node = null
var hargrove_shape: Node = null
var terminal_ui: Node = null

# Modal stack (when > 0 the player is frozen)
var modal_count := 0

# First-move latch (gates Intercom 1)
var first_move_seen_b := false

# Per-run options
var mouse_sensitivity := 0.0028
var fullscreen := false
var current_act := ""


func reset_for_new_game() -> void:
	cryo_keycard = false
	cryo_door_open = false
	hatch_open = false
	array_keycard = false
	array_door_open = false
	decon_door_open = false
	med_door_open = false
	approach_door_open = false
	hargrove_shape = null
	terminal_ui = null
	modal_count = 0
	first_move_seen_b = false
	current_act = ""


func push_modal() -> void:
	modal_count += 1
	emit_signal("modal_count_changed", modal_count)
	if player and player.has_method("freeze"):
		player.freeze()


func pop_modal() -> void:
	modal_count = max(0, modal_count - 1)
	emit_signal("modal_count_changed", modal_count)
	if modal_count == 0 and player and player.has_method("unfreeze"):
		player.unfreeze()


func mark_first_move() -> void:
	if not first_move_seen_b:
		first_move_seen_b = true
		emit_signal("first_move_seen")
