extends Node3D
# ACT - EVA AIRLOCK BAY (between engineering and storage).
# Where the crew suited up to service the array. A row of suit racks (one empty,
# one still occupied and watching), a round hatch onto the dark with a body
# drifting past it, and a cycle log authorising vacuum with someone inside —
# signed in Mara's own code.

const W := 12.0
const D := 14.0
const H := 3.6

var exit_open := false


func _ready() -> void:
	ActUtil.setup_lighting(self, Color(0.46, 0.52, 0.60), Color(0.05, 0.07, 0.11), 0.016, 0.50,
		Color(0.80, 0.88, 1.0), 3.4, 13.0)
	ActUtil.add_dust_motes(self, Vector3(0, 1.7, 0), Vector3(5, 1.8, 6), 80,
		Color(0.80, 0.86, 0.96, 0.16))

	Chamber.add_floor_ceiling(self, W, D, H, Color(0.18, 0.20, 0.24), Color(0.09, 0.10, 0.13))
	var wall := Color(0.24, 0.26, 0.32)
	Chamber.add_wall(self, "x", -W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "x", W/2, -D/2, D/2, H, wall)
	Chamber.add_wall(self, "z", -D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_wall(self, "z", D/2, -W/2, W/2, H, wall, 0.0)
	Chamber.add_door(self, "z", -D/2 + 0.05, 0, "ENGINEERING", Color(0.28, 0.27, 0.23), Callable(), "", true)
	Chamber.add_door(self, "z", D/2 - 0.05, 0, "STORAGE", Color(0.28, 0.27, 0.23),
		func(): exit_open = true, "Open STORAGE")
	ActUtil.wall_label(self, "<-  ENGINEERING", Vector3(0, Chamber.DOOR_H + 0.12, -D/2 + 0.18), 14, Color(0.70, 0.80, 0.96))
	ActUtil.wall_label(self, "STORAGE  ->", Vector3(0, Chamber.DOOR_H + 0.12, D/2 - 0.18), 15, Color(0.70, 0.80, 0.96))
	ActUtil.wall_label(self, "EVA  /  AIRLOCK", Vector3(W/2 - 0.10, 2.6, -3.0), 16, Color(0.62, 0.74, 0.94))

	# Suit racks down the west wall: 4 mounts — one occupied (and watching), one
	# stripped bare (whoever wore it went out and did not come back).
	_eva_suit(Vector3(-5.55, 0, -3.6), 90, true, false)   # occupied corpse-suit
	_eva_suit(Vector3(-5.55, 0, -1.2), 90, false, false)
	_eva_suit(Vector3(-5.55, 0, 1.2), 90, false, true)    # empty mount
	_eva_suit(Vector3(-5.55, 0, 3.6), 90, false, false)

	_build_hatch()

	# Prep bench + a cracked helmet on the deck.
	Chamber.make_prop_box(self, Vector3(2.2, 0.85, 0.7), Vector3(-2.6, 0.42, D/2 - 1.2), Color(0.22, 0.24, 0.29))
	var helmet := Chamber.make_prop_box(self, Vector3(0.34, 0.32, 0.34), Vector3(-0.6, 0.16, 4.2), Color(0.70, 0.72, 0.76))
	Interactable.attach(helmet, "Look at the helmet", "examine_only", {
		"text": "A cracked EVA helmet on the deck.  Inside the visor a film of frost has formed in the exact shape of a hand, fingers spread, pressing outward — as if someone inside tried to push the glass away from their own face.",
		"duration": 8.0,
	})

	# Airlock control panel + cycle log.
	var panel := Chamber.make_prop_box(self, Vector3(0.5, 0.7, 0.18), Vector3(4.2, 1.3, -4.4), Color(0.20, 0.23, 0.28))
	var pscr := MeshInstance3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(0.36, 0.26)
	pscr.mesh = pq
	pscr.position = Vector3(4.2, 1.42, -4.30)
	pscr.rotation_degrees = Vector3(0, 180, 0)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	pm.albedo_color = Color(0.10, 0.03, 0.03)
	pm.emission_enabled = true
	pm.emission = Color(0.86, 0.16, 0.12)
	pm.emission_energy_multiplier = 0.6
	pscr.material_override = pm
	add_child(pscr)
	Interactable.attach(panel, "Read the airlock log", "examine_only", {
		"text": "AIRLOCK CYCLE LOG\n----------------\nCycle 0081:  inner sealed.  outer OPENED.\nOccupant in chamber:  YES.\nOverride:  manual.\nAuthorised by:  VOSS, M.  (command code accepted)\n\nYou read your own name twice.  The third time it does not get easier.  You do not remember standing at this panel.  You do not remember deciding.",
		"duration": 12.0,
	})

	# --- Horror dressing -------------------------------------------------
	ActUtil.corpse(self, Vector3(2.0, 0, 2.4), -40, true, Color(0.74, 0.75, 0.78))
	ActUtil.blood_trail(self, Vector3(4.6, 0, 1.0), Vector3(2.4, 0, 2.2), 6)
	ActUtil.signal_growth(self, Vector3(-5.4, 0.2, 5.6), 1.1)
	ActUtil.viscera(self, Vector3(4.6, 0, 4.6))
	ActUtil.bloody_smears(self, Vector3(-5.92, 2.0, -5.0), 90, 4)
	ActUtil.wall_scrawl(self, "HE WENT\nOUTSIDE", Vector3(-5.92, 2.0, 4.5), 90, 34)
	# Frost ring on the deck by the hatch.
	var frost := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 1.6
	fc.bottom_radius = 1.6
	fc.height = 0.01
	frost.mesh = fc
	frost.position = Vector3(4.0, 0.02, 0)
	var frm := StandardMaterial3D.new()
	frm.albedo_color = Color(0.70, 0.82, 0.92, 0.35)
	frm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frost.material_override = frm
	add_child(frost)
	ActUtil.add_peeker(self, Vector3(-4.8, 0, -5.2), HorrorShape.KIND_HARGROVE, 30)

	ActUtil.haunt(self, {
		"intensity": 0.55,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(-4, 0, 4), Vector3(4, 0, -4), Vector3(-4, 0, -4), Vector3(0, 0, 5)], "creep": 0.7}],
	})

	ActUtil.spawn_player(Vector3(0, 0.5, -D/2 + 0.8), 0)


func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emit: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = color
	if emit:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	m.metallic = 0.2
	m.roughness = 0.6
	mi.material_override = m
	parent.add_child(mi)


# A wall-mounted EVA suit. occupied = a body still inside (visor glows red).
# empty = stripped to the backboard and a dangling tether.
func _eva_suit(pos: Vector3, rot_y: float, occupied: bool, empty: bool) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees = Vector3(0, rot_y, 0)
	add_child(holder)
	_part(holder, Vector3(0.70, 2.00, 0.10), Vector3(0, 1.0, -0.30), Color(0.16, 0.17, 0.21))
	if empty:
		_part(holder, Vector3(0.05, 0.55, 0.05), Vector3(0.0, 1.35, -0.12), Color(0.10, 0.10, 0.12))
		_part(holder, Vector3(0.30, 0.06, 0.06), Vector3(0.0, 1.62, -0.10), Color(0.30, 0.31, 0.36))
		return
	var suit := Color(0.80, 0.82, 0.86) if not occupied else Color(0.60, 0.60, 0.56)
	_part(holder, Vector3(0.18, 0.78, 0.18), Vector3(-0.12, 0.40, 0.0), suit)
	_part(holder, Vector3(0.18, 0.78, 0.18), Vector3(0.12, 0.40, 0.0), suit)
	_part(holder, Vector3(0.50, 0.72, 0.34), Vector3(0.0, 1.12, 0.0), suit)
	_part(holder, Vector3(0.40, 0.55, 0.18), Vector3(0.0, 1.12, -0.24), Color(0.30, 0.32, 0.36))
	_part(holder, Vector3(0.15, 0.60, 0.15), Vector3(-0.33, 1.06, 0.02), suit)
	_part(holder, Vector3(0.15, 0.60, 0.15), Vector3(0.33, 1.06, 0.02), suit)
	var helm := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.18
	hs.height = 0.36
	helm.mesh = hs
	helm.position = Vector3(0, 1.66, 0)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = suit
	hm.metallic = 0.3
	hm.roughness = 0.4
	helm.material_override = hm
	holder.add_child(helm)
	var vis := MeshInstance3D.new()
	var vb := SphereMesh.new()
	vb.radius = 0.13
	vb.height = 0.26
	vis.mesh = vb
	vis.position = Vector3(0, 1.66, 0.10)
	vis.scale = Vector3(1, 1, 0.5)
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color(0.03, 0.04, 0.06)
	if occupied:
		vm.emission_enabled = true
		vm.emission = Color(0.92, 0.12, 0.08)
		vm.emission_energy_multiplier = 1.3
	vis.material_override = vm
	holder.add_child(vis)


# A round hatch onto the dark in the east wall: ring, starfield, faint glass,
# and a suited body drifting past it.
func _build_hatch() -> void:
	var fx := 5.92
	# Dark space disc behind the glass.
	var disc := MeshInstance3D.new()
	var dc := CylinderMesh.new()
	dc.top_radius = 1.0
	dc.bottom_radius = 1.0
	dc.height = 0.03
	disc.mesh = dc
	disc.position = Vector3(fx + 0.02, 1.9, 0)
	disc.rotation_degrees = Vector3(0, 0, 90)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.012, 0.018, 0.035)
	disc.material_override = dm
	add_child(disc)
	# A few stars.
	for i in 20:
		var ang := randf() * TAU
		var rad := sqrt(randf()) * 0.9
		var star := MeshInstance3D.new()
		var sq := QuadMesh.new()
		var ss := randf_range(0.015, 0.04)
		sq.size = Vector2(ss, ss)
		star.mesh = sq
		star.position = Vector3(fx - 0.02, 1.9 + sin(ang) * rad, cos(ang) * rad)
		star.rotation_degrees = Vector3(0, -90, 0)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.emission_enabled = true
		var b := randf_range(0.6, 1.0)
		sm.albedo_color = Color(b, b, b)
		sm.emission = sm.albedo_color
		sm.emission_energy_multiplier = randf_range(1.0, 2.6)
		star.material_override = sm
		add_child(star)
	# The drifting body, tumbling slow, reaching back toward the glass.
	var drift := Node3D.new()
	drift.position = Vector3(fx - 0.06, 1.95, 0.05)
	drift.rotation_degrees = Vector3(18, 0, 26)
	var dcol := Color(0.10, 0.11, 0.14)
	_part(drift, Vector3(0.22, 0.5, 0.14), Vector3(0, 0, 0), dcol)
	_part(drift, Vector3(0.10, 0.30, 0.10), Vector3(-0.18, 0.18, 0), dcol)
	_part(drift, Vector3(0.10, 0.30, 0.10), Vector3(0.18, 0.20, 0), dcol)
	_part(drift, Vector3(0.10, 0.28, 0.10), Vector3(-0.08, -0.34, 0), dcol)
	_part(drift, Vector3(0.10, 0.28, 0.10), Vector3(0.08, -0.34, 0), dcol)
	var dh := MeshInstance3D.new()
	var dhs := SphereMesh.new()
	dhs.radius = 0.13
	dhs.height = 0.26
	dh.mesh = dhs
	dh.position = Vector3(0, 0.36, 0)
	var dhm := StandardMaterial3D.new()
	dhm.albedo_color = dcol
	dh.material_override = dhm
	drift.add_child(dh)
	add_child(drift)
	# Faint glass over the hatch.
	var glass := MeshInstance3D.new()
	var gc := CylinderMesh.new()
	gc.top_radius = 1.0
	gc.bottom_radius = 1.0
	gc.height = 0.02
	glass.mesh = gc
	glass.position = Vector3(fx - 0.12, 1.9, 0)
	glass.rotation_degrees = Vector3(0, 0, 90)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	gm.albedo_color = Color(0.42, 0.56, 0.72, 0.12)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.metallic = 0.6
	gm.roughness = 0.05
	glass.material_override = gm
	add_child(glass)
	# Decorative ring frame around the hatch, on the room side.
	var ring := MeshInstance3D.new()
	var tr := TorusMesh.new()
	tr.inner_radius = 1.0
	tr.outer_radius = 1.20
	ring.mesh = tr
	ring.position = Vector3(5.84, 1.9, 0)
	ring.rotation_degrees = Vector3(0, 0, 90)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	rm.albedo_color = Color(0.16, 0.17, 0.21)
	rm.metallic = 0.6
	rm.roughness = 0.4
	ring.material_override = rm
	add_child(ring)
	# Control sill below the hatch — interact here to look out.
	var sill := Chamber.make_prop_box(self, Vector3(0.35, 0.30, 2.2), Vector3(5.78, 0.70, 0), Color(0.18, 0.19, 0.24))
	Interactable.attach(sill, "Look out the hatch", "examine_only", {
		"text": "Something drifts past the hatch window — a figure in a station suit, tumbling slowly end over end, one arm reaching back toward the glass as it goes.  The visor is dark.  You cannot tell which of them it is.  You do not look away fast enough.",
		"duration": 9.0,
	})


func _process(_dt: float) -> void:
	if exit_open and GameState.player and GameState.player.global_position.z > D/2 + 0.1:
		SceneRouter.transition_to("act_storage")
