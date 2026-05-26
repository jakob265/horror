extends Node3D
# ACT - CARGO BAY (between hydroponics and engineering).
# A cold cavern of stacked containers and an overhead crane. This is where they
# put the ones who stopped being themselves first — and where one of them is
# still hanging from the gantry hook.

const W := 18.0
const D := 16.0
const H := 5.0

var exit_open := false


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.42, 0.46, 0.52), Color(0.06, 0.08, 0.11), 0.018, 0.42,
		Color(0.95, 0.82, 0.55), 3.2, 14.0)
	ActUtil.add_dust_motes(self, Vector3(0, 2.2, 0), Vector3(8, 2.6, 7), 120,
		Color(0.78, 0.78, 0.84, 0.15))

	Chamber.add_floor_ceiling(self, W, D, H, Color(0.17, 0.18, 0.21), Color(0.08, 0.09, 0.11))
	var wall := Color(0.23, 0.24, 0.28)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "HYDROPONICS", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "ENGINEERING", Color(0.28, 0.27, 0.23),
		func(): exit_open = true, "Open ENGINEERING")
	ActUtil.wall_label(self, "<-  HYDROPONICS", Vector3(0, Chamber.DOOR_H + 0.12, -D/2 + 0.18), 14, Color(0.86, 0.80, 0.62))
	ActUtil.wall_label(self, "ENGINEERING  ->", Vector3(0, Chamber.DOOR_H + 0.12, D/2 - 0.18), 15, Color(0.86, 0.80, 0.62))
	ActUtil.wall_label(self, "CARGO BAY 2", Vector3(-W/2 + 0.10, 3.0, -4.0), 18, Color(0.90, 0.80, 0.55))

	# Container stacks down both sides, leaving a central aisle.
	var pal := [Color(0.45, 0.30, 0.22), Color(0.24, 0.33, 0.40), Color(0.36, 0.36, 0.26), Color(0.30, 0.24, 0.30)]
	_container(Vector3(-6.8, 0.9, -5.0), Vector3(2.4, 1.8, 2.4), pal[0])
	_container(Vector3(-6.8, 2.7, -5.0), Vector3(2.2, 1.6, 2.2), pal[1])
	_container(Vector3(-7.2, 0.9, -0.5), Vector3(2.4, 1.8, 2.6), pal[2])
	_container(Vector3(-6.6, 0.9, 4.2), Vector3(2.4, 1.8, 2.4), pal[3])
	_container(Vector3(6.8, 0.9, -4.2), Vector3(2.4, 1.8, 2.6), pal[1])
	_container(Vector3(6.8, 0.9, 0.5), Vector3(2.4, 1.8, 2.4), pal[0])
	_container(Vector3(6.8, 2.7, 0.5), Vector3(2.2, 1.6, 2.2), pal[2])
	_container(Vector3(7.0, 0.9, 5.2), Vector3(2.4, 1.8, 2.4), pal[3])

	# Overhead crane gantry + a hanging hook.
	Chamber.make_prop_box(self, Vector3(W - 1.0, 0.4, 0.4), Vector3(0, H - 0.5, 0), Color(0.28, 0.27, 0.22), false)
	Chamber.make_prop_box(self, Vector3(0.5, 0.5, 1.2), Vector3(1.5, H - 0.6, 0), Color(0.30, 0.30, 0.34), false)
	Chamber.make_prop_box(self, Vector3(0.05, 1.6, 0.05), Vector3(1.5, H - 1.4, 0), Color(0.12, 0.12, 0.14), false)

	# A loader parked against the west wall.
	Chamber.make_prop_box(self, Vector3(1.2, 1.0, 1.8), Vector3(-7.6, 0.5, 6.4), Color(0.55, 0.45, 0.16))
	Chamber.make_prop_box(self, Vector3(0.9, 0.9, 0.9), Vector3(-7.6, 1.4, 5.8), Color(0.20, 0.20, 0.24))
	for fk in [-0.3, 0.3]:
		Chamber.make_prop_box(self, Vector3(0.10, 0.10, 1.4), Vector3(-7.6 + fk, 0.18, 7.6), Color(0.16, 0.16, 0.18), false)

	# A container that should never have been a container.
	var rem := _container(Vector3(4.2, 0.7, -6.2), Vector3(2.0, 1.4, 1.6), Color(0.30, 0.20, 0.18))
	ActUtil.wall_scrawl(self, "HUMAN REMAINS\nDO NOT OPEN", Vector3(4.2, 0.9, -5.38), 0, 18, Color(0.78, 0.16, 0.12))
	Interactable.attach(rem, "Read the container tag", "examine_only", {
		"text": "A standard cargo container, resealed by hand.  The shipping tag has been crossed out and rewritten:  CONTENTS - HUMAN REMAINS (4).  DO NOT OPEN.  Authorised: HARGROVE.  Below it, scratched in by someone else:  'they didn't stay dead.  we resealed it twice.'",
		"duration": 11.0,
	})

	# --- Horror dressing -------------------------------------------------
	ActUtil.hanging_corpse(self, Vector3(1.5, H - 2.2, 0), 2.2)
	ActUtil.corpse(self, Vector3(-3.6, 0, 5.4), 25)
	ActUtil.corpse(self, Vector3(5.4, 0, 3.2), -60)
	ActUtil.signal_growth(self, Vector3(-7.6, 0.2, 1.8), 1.5)
	ActUtil.signal_growth(self, Vector3(8.0, 0.2, -6.5), 1.3)
	ActUtil.viscera(self, Vector3(3.0, 0, 4.0))
	ActUtil.blood_trail(self, Vector3(0.5, 0, 1.0), Vector3(-3.2, 0, 5.0), 7)
	ActUtil.bloody_smears(self, Vector3(-8.92, 2.4, -3.0), 90, 5)
	ActUtil.wall_scrawl(self, "THEY KEPT\nUS IN HERE", Vector3(8.92, 2.6, 2.0), -90, 36)
	ActUtil.add_peeker(self, Vector3(-6.5, 0, -6.4), HorrorShape.KIND_HARGROVE, 25)

	ActUtil.haunt(self, {
		"intensity": 0.60,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(-6, 0, 5), Vector3(6, 0, -5), Vector3(-6, 0, -5), Vector3(6, 0, 5)], "creep": 0.85}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _container(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var c := Chamber.make_prop_box(self, size, pos, color)
	# Corrugation ribs + a darker door end.
	for ry in [-0.3, 0.0, 0.3]:
		Chamber.make_prop_box(self, Vector3(size.x + 0.02, 0.06, size.z + 0.02),
			pos + Vector3(0, ry * size.y, 0), color.darkened(0.3), false)
	return c


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act7")
