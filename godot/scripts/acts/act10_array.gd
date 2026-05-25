extends Node3D
# ACT 10 - COMMUNICATIONS ARRAY ROOM.
# Vast 30x30 room. Central tower with slow-pulsing core. Subsonic shake.
# Note 6 near entry, Note 7 at tower base. Three monitor stations.
# Hargrove-Shape at tower base. Terminal pedestal triggers DESTROY/LISTEN modal.
# Intercom 6 fires by proximity (2s delay) -> Hargrove farewell after it ends.

const RW := 30.0
const RD := 30.0
const RH := 18.0
const ENTRY_W := 1.4

var tower_core: MeshInstance3D = null
var tower_floor_pool: MeshInstance3D = null
var hargrove_shape: HorrorShape = null
var hargrove_started := false
var entry_sting_done := false
var t := 0.0
var shake_t := 0.0


func _ready() -> void:
	ActUtil.light_rig_act4(self)

	# Floor
	Chamber.make_prop_box(self, Vector3(RW, 0.2, RD), Vector3(0, -0.1, 0), Color(0.27, 0.28, 0.32))
	# Ceiling
	Chamber.make_prop_box(self, Vector3(RW, 0.2, RD), Vector3(0, RH, 0), Color(0.08, 0.08, 0.10), false)

	# East, west, north walls
	var wall := Color(0.22, 0.24, 0.27)
	Chamber.make_prop_box(self, Vector3(0.2, RH, RD), Vector3(-RW / 2, RH / 2, 0), wall)
	Chamber.make_prop_box(self, Vector3(0.2, RH, RD), Vector3(RW / 2, RH / 2, 0), wall)
	Chamber.make_prop_box(self, Vector3(RW, RH, 0.2), Vector3(0, RH / 2, RD / 2), wall)

	# South wall with 1.4 entry gap
	var south_seg_w := (RW - ENTRY_W) / 2
	for sx in [-(ENTRY_W / 2 + south_seg_w / 2), (ENTRY_W / 2 + south_seg_w / 2)]:
		Chamber.make_prop_box(self, Vector3(south_seg_w, RH, 0.2), Vector3(sx, RH / 2, -RD / 2), wall)
	# Header
	Chamber.make_prop_box(self, Vector3(ENTRY_W + 0.2, RH - 2.4, 0.2),
		Vector3(0, 2.4 + (RH - 2.4) / 2, -RD / 2), wall)
	# Sealed entry door (decorative + collidable)
	var entry_door := Chamber.make_prop_box(self, Vector3(ENTRY_W, 2.4, 0.10),
		Vector3(0, 1.2, -RD / 2 + 0.05), Color(0.70, 0.59, 0.51))

	# ARRAY label above entry — billboard so it always reads correctly
	ActUtil.wall_label(self, "ARRAY", Vector3(0, 2.7, -RD / 2 + 0.30), 28,
		Color(0.95, 0.80, 0.55))

	# Central tower
	var tower_pos := Vector3(0, 0, 4)
	var tower_outer := MeshInstance3D.new()
	var oc := CylinderMesh.new()
	oc.top_radius = 0.8
	oc.bottom_radius = 0.8
	oc.height = RH
	tower_outer.mesh = oc
	tower_outer.position = Vector3(tower_pos.x, RH / 2, tower_pos.z)
	var oc_mat := StandardMaterial3D.new()
	oc_mat.albedo_color = Color(0.16, 0.18, 0.22)
	tower_outer.material_override = oc_mat
	add_child(tower_outer)
	# Tower collider
	var tbody := StaticBody3D.new()
	tbody.position = Vector3(tower_pos.x, RH / 2, tower_pos.z)
	var tshape := CollisionShape3D.new()
	var tcyl := CylinderShape3D.new()
	tcyl.radius = 0.8
	tcyl.height = RH
	tshape.shape = tcyl
	tbody.add_child(tshape)
	add_child(tbody)

	# Tower core (the breathing light inside the tower)
	tower_core = MeshInstance3D.new()
	var coremesh := CylinderMesh.new()
	coremesh.top_radius = 0.4
	coremesh.bottom_radius = 0.4
	coremesh.height = RH - 1.0
	tower_core.mesh = coremesh
	tower_core.position = Vector3(tower_pos.x, RH / 2, tower_pos.z)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.86, 0.78, 0.70)
	cm.emission_enabled = true
	cm.emission = Color(0.86, 0.78, 0.70)
	cm.emission_energy_multiplier = 1.0
	tower_core.material_override = cm
	add_child(tower_core)

	# Floor light pool under core
	tower_floor_pool = MeshInstance3D.new()
	var pool_cyl := CylinderMesh.new()
	pool_cyl.top_radius = 4.0
	pool_cyl.bottom_radius = 4.0
	pool_cyl.height = 0.01
	tower_floor_pool.mesh = pool_cyl
	tower_floor_pool.position = Vector3(tower_pos.x, 0.03, tower_pos.z)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.90, 0.78, 0.66, 0.30)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.emission_enabled = true
	pmat.emission = Color(0.90, 0.78, 0.66)
	pmat.emission_energy_multiplier = 0.4
	tower_floor_pool.material_override = pmat
	add_child(tower_floor_pool)

	# Conduit cubes around the tower
	for ang in range(0, 360, 30):
		var ang_i: int = int(ang)
		var rad: float = 1.85
		var x: float = tower_pos.x + cos(deg_to_rad(float(ang_i))) * rad
		var z: float = tower_pos.z + sin(deg_to_rad(float(ang_i))) * rad
		var h: float = 4.0 + float(ang_i % 70) / 70.0 * 6.0
		Chamber.make_prop_box(self, Vector3(0.30, h, 0.30), Vector3(x, h / 2, z), Color(0.12, 0.14, 0.18))

	# Note 6 - on the floor near entrance
	Interactable.make_note(self, Vector3(0, 0.03, -12), "note_6", "Read maintenance log")
	# Note 7 - at the base of the tower
	Interactable.make_note(self, Vector3(tower_pos.x + 1.6, 0.03, tower_pos.z - 0.8), "note_7", "Read torn paper")

	# Three monitor stations
	for ang_deg in [-45, 0, 45]:
		var a := deg_to_rad(ang_deg)
		var sx := tower_pos.x + sin(a) * 7
		var sz := tower_pos.z + cos(a) * 7 + 3
		Chamber.make_prop_box(self, Vector3(1.2, 0.9, 0.5), Vector3(sx, 0.45, sz), Color(0.14, 0.16, 0.20))
		# Screen
		var screen := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(1.0, 0.6)
		screen.mesh = sq
		screen.position = Vector3(sx, 1.10, sz - 0.26)
		screen.rotation_degrees = Vector3(0, ang_deg, 0)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.23, 0.51, 0.70)
		smat.emission_enabled = true
		smat.emission = Color(0.23, 0.51, 0.70)
		smat.emission_energy_multiplier = 0.4
		screen.material_override = smat
		add_child(screen)
		ActUtil.wall_label(self, "SIGNAL ORIGIN\nBEARING: 000.000\nDIST:    0.000 m\n(SELF)",
			Vector3(sx, 1.10, sz - 0.30), 14, Color(0.55, 0.86, 0.95))

	# Hargrove-Shape at tower base, facing tower
	hargrove_shape = HorrorShape.create(HorrorShape.KIND_HARGROVE, Vector3(tower_pos.x, 0, tower_pos.z + 1.6), 180)
	add_child(hargrove_shape)
	ShapeTracker.register(hargrove_shape)
	GameState.hargrove_shape = hargrove_shape

	# Terminal pedestal
	Chamber.make_prop_box(self, Vector3(0.9, 1.1, 0.6), Vector3(tower_pos.x, 0.55, tower_pos.z - 2.2), Color(0.20, 0.24, 0.29))
	# Terminal screen (interactable)
	var term_screen := StaticBody3D.new()
	term_screen.position = Vector3(tower_pos.x, 1.15, tower_pos.z - 2.45)
	term_screen.rotation_degrees = Vector3(35, 0, 0)
	var tsm := MeshInstance3D.new()
	var tsb := BoxMesh.new()
	tsb.size = Vector3(0.75, 0.45, 0.04)
	tsm.mesh = tsb
	var tsmat := StandardMaterial3D.new()
	tsmat.albedo_color = Color(0.16, 0.51, 0.43)
	tsmat.emission_enabled = true
	tsmat.emission = Color(0.16, 0.51, 0.43)
	tsmat.emission_energy_multiplier = 0.5
	tsm.material_override = tsmat
	term_screen.add_child(tsm)
	var tscol := CollisionShape3D.new()
	var tscs := BoxShape3D.new()
	tscs.size = Vector3(0.75, 0.45, 0.08)
	tscol.shape = tscs
	term_screen.add_child(tscol)
	add_child(term_screen)
	ActUtil.wall_label(self, "[ ARRAY CONTROL ]\n  USE TERMINAL",
		Vector3(tower_pos.x, 1.15, tower_pos.z - 2.48), 16,
		Color(0.55, 0.95, 0.75))
	Interactable.attach(term_screen, "Use terminal", "trigger_event", {
		"callback": Callable(self, "_open_terminal"),
	})

	# Intercom 6 - proximity to terminal, 2s delay
	ActUtil.register_intercom(self, 6, Vector3(tower_pos.x, 1.7, tower_pos.z - 2.95), 0, Vector3(tower_pos.x, 1.6, tower_pos.z - 2.6), 2.2, 2.0)

	# Tower base ring of cable conduits piling outward
	for i in range(12):
		var a := float(i) * TAU / 12.0
		var r := 2.4 + (i % 3) * 0.3
		Chamber.make_prop_box(self, Vector3(0.18, 0.18, 0.18),
			Vector3(tower_pos.x + cos(a) * r, 0.10, tower_pos.z + sin(a) * r),
			Color(0.20, 0.20, 0.24))
	# Heavy floor cables snaking out from the tower base
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var len := 6.0
		var cable := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.10, 0.06, len)
		cable.mesh = cb
		cable.position = Vector3(tower_pos.x + cos(a) * (1.5 + len/2), 0.05,
			tower_pos.z + sin(a) * (1.5 + len/2))
		cable.rotation_degrees = Vector3(0, -rad_to_deg(a) + 90, 0)
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		cmat.albedo_color = Color(0.14, 0.14, 0.18)
		cmat.metallic = 0.3
		cable.material_override = cmat
		add_child(cable)

	# Equipment racks along the east and west walls
	var rack_led_palette: Array[Color] = [Color(0.86, 0.22, 0.22), Color(0.86, 0.70, 0.22), Color(0.22, 0.86, 0.42)]
	for rack_z in [-10, -4, 2, 8]:
		for wx in [-RW/2 + 0.5, RW/2 - 0.5]:
			Chamber.make_prop_box(self, Vector3(0.6, 2.4, 1.4), Vector3(wx, 1.2, rack_z), Color(0.18, 0.20, 0.24))
			# Indicator LEDs
			for ly in [0.6, 1.2, 1.8]:
				var led_col: Color = rack_led_palette[int(ly * 5) % 3]
				var led := MeshInstance3D.new()
				var lb := BoxMesh.new()
				lb.size = Vector3(0.04, 0.06, 0.06)
				led.mesh = lb
				led.position = Vector3(wx + (-0.30 if wx > 0 else 0.30), ly, rack_z)
				var lmat := StandardMaterial3D.new()
				lmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				lmat.albedo_color = led_col
				lmat.emission_enabled = true
				lmat.emission = led_col
				lmat.emission_energy_multiplier = 1.2
				led.material_override = lmat
				add_child(led)
			# Ventilation slots on the front
			for sy in [0.30, 2.10]:
				Chamber.make_prop_box(self, Vector3(0.04, 0.06, 1.10),
					Vector3(wx + (-0.30 if wx > 0 else 0.30), sy, rack_z),
					Color(0.06, 0.06, 0.08), false)

	# Server tower triplet against the north wall
	for tx in [-9, 0, 9]:
		Chamber.make_prop_box(self, Vector3(1.2, 2.4, 0.8), Vector3(tx, 1.2, RD/2 - 0.6), Color(0.16, 0.18, 0.22))
		# Glowing slits
		for sy_i in 5:
			Chamber.make_prop_box(self, Vector3(0.10, 0.04, 0.40), Vector3(tx - 0.4 + sy_i * 0.20, 1.95, RD/2 - 1.05),
				Color(0.22, 0.62, 0.86), false)

	# Cable mass hanging from the ceiling on the south end
	for cx in [-6, -3, 0, 3, 6]:
		Chamber.make_prop_box(self, Vector3(0.06, 1.20, 0.06), Vector3(cx, RH - 0.65, -10), Color(0.14, 0.14, 0.18), false)
		Chamber.make_prop_box(self, Vector3(0.20, 0.20, 0.06), Vector3(cx, RH - 1.30, -10), Color(0.20, 0.20, 0.24), false)

	# Big warning floor decals around the tower
	for ang in range(0, 360, 60):
		var a := deg_to_rad(float(ang))
		var stripe := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.60, 0.16)
		stripe.mesh = q
		stripe.rotation_degrees = Vector3(-90, ang, 0)
		stripe.position = Vector3(tower_pos.x + cos(a) * 4.8, 0.025, tower_pos.z + sin(a) * 4.8)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		sm.albedo_color = Color(0.86, 0.70, 0.16, 0.65)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.emission_enabled = true
		sm.emission = Color(0.86, 0.70, 0.16)
		sm.emission_energy_multiplier = 0.3
		stripe.material_override = sm
		add_child(stripe)

	# Catwalk gantry across the upper middle of the room
	Chamber.make_prop_box(self, Vector3(RW - 6, 0.20, 0.6), Vector3(0, 4.5, -2.0), Color(0.20, 0.22, 0.27), false)
	# Catwalk railings
	for ry in [4.95, 5.30]:
		Chamber.make_prop_box(self, Vector3(RW - 6, 0.04, 0.04), Vector3(0, ry, -2.30), Color(0.86, 0.70, 0.16), false)
		Chamber.make_prop_box(self, Vector3(RW - 6, 0.04, 0.04), Vector3(0, ry, -1.70), Color(0.86, 0.70, 0.16), false)
	# Catwalk support columns
	for cx in [-10, -5, 5, 10]:
		Chamber.make_prop_box(self, Vector3(0.20, 4.5, 0.20), Vector3(cx, 2.25, -2.0), Color(0.16, 0.18, 0.22), false)

	# Dust motes — heavy atmosphere in a vast space
	ActUtil.add_dust_motes(self, Vector3(0, 2.0, 0), Vector3(12, 2.5, 14), 160,
		Color(0.78, 0.74, 0.68, 0.16))

	# Lurkers out in the dark fringes of the huge room; slow creep so they
	# don't crowd the terminal. Intensity backs off a touch for the climax.
	ActUtil.haunt(self, {
		"intensity": 0.62,
		"flicker_rate": 1.0,
		"lurkers": [{"kind": "hargrove", "points": [
			Vector3(-11, 0, 9), Vector3(11, 0, 9), Vector3(0, 0, 12), Vector3(-11, 0, -4)], "creep": 0.5}],
	})

	# Player spawn
	ActUtil.spawn_player(Vector3(0, 0.5, -12.5), 0)


func _open_terminal() -> void:
	if GameState.terminal_ui:
		return
	var term := ArrayTerminal.create()
	var ui_root := _find_ui_layer()
	if ui_root:
		ui_root.add_child(term)
		term.open()
		GameState.terminal_ui = term
		term.chose_destroy.connect(_on_destroy)
		term.chose_listen.connect(_on_listen)


func _on_destroy() -> void:
	_close_terminal_and_end("A")


func _on_listen() -> void:
	_close_terminal_and_end("B")


func _close_terminal_and_end(which: String) -> void:
	if GameState.terminal_ui:
		GameState.terminal_ui.close()
		GameState.terminal_ui = null
	var main := get_tree().root.get_node_or_null("Main")
	if main and main.has_method("start_ending"):
		main.start_ending(which)


func _find_ui_layer() -> Node:
	var main := get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("UILayer")
	return null


func _process(dt: float) -> void:
	t += dt
	shake_t += dt

	# Tower core breathing
	if tower_core:
		var v := 0.5 + 0.5 * sin(t * (TAU / 4.0))
		var r := 0.70 + 0.20 * (1 - v)
		var g := 0.70 + 0.10 * (1 - v)
		var b := 0.59 + 0.35 * v
		var mat: StandardMaterial3D = tower_core.material_override
		mat.emission = Color(r, g, b)
		mat.emission_energy_multiplier = 0.8 + 0.6 * v
		if tower_floor_pool:
			var pmat: StandardMaterial3D = tower_floor_pool.material_override
			pmat.emission = Color(r, g, b)
			pmat.emission_energy_multiplier = 0.2 + 0.4 * v

	# Subsonic camera shake
	if InteractionManager.camera:
		var dx := 0.004 * sin(shake_t * 2.7)
		var dz := 0.004 * cos(shake_t * 3.1)
		InteractionManager.camera.position = Vector3(dx, 0, dz)

	# Initial sting on entry
	if not entry_sting_done and t > 0.4:
		entry_sting_done = true
		AudioManager.shape_sting()

	# Hargrove farewell after Intercom 6 finishes
	if not hargrove_started and 6 in OlenManager.fired and not OlenManager._subtitle_active:
		hargrove_started = true
		if hargrove_shape and is_instance_valid(hargrove_shape):
			hargrove_shape.farewell()
