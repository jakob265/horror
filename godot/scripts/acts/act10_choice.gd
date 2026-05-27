extends Node3D
# VESPER - ACT 10: THE CHOICE
# The deepest point. Three ways out, one of them a door. Each station ends the
# game on its ending: SEAL (collapse the shaft), BURN (fire the nest), or
# SUCCUMB (put the lamp down and stay).

const WALL := Color(0.28, 0.38, 0.48)
const FLOOR := Color(0.34, 0.42, 0.52)
const CEIL := Color(0.10, 0.14, 0.20)

var chosen := false


func _ready() -> void:
	ActUtil.light_rig_ice(self)
	_build_choice_room()
	ActUtil.haunt(self, {"intensity": 0.85, "flicker": true, "flicker_rate": 0.5})

	if GameState.player:
		GameState.player.global_position = Vector3(0, 0.5, 4.0)
		GameState.player.rotation_degrees.y = 0.0


func _build_choice_room() -> void:
	Chamber.add_room(self, 16, 14, 5.0, FLOOR, CEIL, WALL, Vector3(0, 0, 0), {},
		[{"axis": "z", "fixed": 7.0, "gap": 0.0}])

	# SEAL - collapse charges on the shaft (west).
	var seal := Chamber.make_prop_box(self, Vector3(1.2, 1.1, 0.8), Vector3(-5.5, 0.55, -1.0), Color(0.30, 0.34, 0.40))
	Chamber.make_prop_box(self, Vector3(0.3, 0.4, 0.2), Vector3(-5.5, 1.3, -1.0), Color(0.7, 0.15, 0.12), false)
	Interactable.attach(seal, "Bring the shaft down", "trigger_event", {"callback": Callable(self, "_seal")})
	ActUtil.wall_label(self, "SHAFT CHARGES", Vector3(-5.5, 2.0, -1.0), 13, Color(0.7, 0.78, 0.85))

	# BURN - fuel manifold + igniter (east).
	var burn := Chamber.make_prop_box(self, Vector3(1.2, 1.2, 0.8), Vector3(5.5, 0.6, -1.0), Color(0.40, 0.30, 0.18))
	Chamber.make_prop_box(self, Vector3(0.2, 1.6, 0.2), Vector3(5.5, 1.4, -1.6), Color(0.5, 0.4, 0.2), false)
	Interactable.attach(burn, "Open the fuel lines and strike the flare", "trigger_event", {"callback": Callable(self, "_burn")})
	ActUtil.wall_label(self, "FUEL MANIFOLD", Vector3(5.5, 2.1, -1.0), 13, Color(0.85, 0.55, 0.3))

	# SUCCUMB - the warm dark at the back (north).
	var mass := Chamber.make_prop_box(self, Vector3(2.4, 4.6, 1.4), Vector3(0, 2.3, -6.2), Color(0.05, 0.09, 0.08))
	ActUtil.signal_growth(self, Vector3(0, 0, -6.0), 2.6, Color(0.07, 0.13, 0.11))
	Interactable.attach(mass, "Put the lamp down. Stay.", "trigger_event", {"callback": Callable(self, "_succumb")})
	ActUtil.add_omni(self, Vector3(0, 2.5, -6.0), Color(0.6, 0.4, 0.3), 0.8, 6.0, false)

	ActUtil.hanging_corpse(self, Vector3(-3, 4.0, -4), 1.8, Color(0.30, 0.38, 0.40))
	ActUtil.hanging_corpse(self, Vector3(3, 4.0, -4), 1.8, Color(0.30, 0.38, 0.40))
	ActUtil.wall_label(self, "ONE OF THESE IS A DOOR", Vector3(0, 3.4, 6.8), 18, Color(0.6, 0.78, 0.9))


func _seal() -> void:
	_finish("seal")


func _burn() -> void:
	_finish("burn")


func _succumb() -> void:
	_finish("succumb")


func _finish(which: String) -> void:
	if chosen:
		return
	chosen = true
	var main := get_tree().root.get_node_or_null("Main")
	if main and main.has_method("start_ending"):
		main.start_ending(which)
