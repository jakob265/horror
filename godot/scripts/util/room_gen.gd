class_name RoomGen
extends RefCounted
# Procedural room + wing stamping. Designed so seam-perfect geometry is
# guaranteed by construction (not by hand-derivation): each side room's near
# edge ALWAYS coincides with the corridor's wall coordinate, walls fully
# enclose every chamber, doorway openings align with built doors.
#
# Built on the existing Chamber / ActUtil helpers - it does not introduce a
# new geometry primitive, just a higher-level pattern that calls them in a
# guaranteed-correct order.
#
# Primary entry point: stamp_corridor_wing(parent, cfg) -> int (room count).
# A wing = one corridor + N side rooms branching perpendicular.

# --- Theme presets --------------------------------------------------------
# Each theme tints walls/floor/ceiling and tunes the dressing layer (prop
# colours, density, horror chance). Pick one when calling stamp_*.

const THEMES := {
	"industrial": {
		"name":   "industrial",
		"wall":   Color(0.30, 0.32, 0.36),
		"floor":  Color(0.34, 0.36, 0.40),
		"ceil":   Color(0.13, 0.14, 0.17),
		"props":  [Color(0.30, 0.26, 0.18), Color(0.40, 0.42, 0.46), Color(0.30, 0.32, 0.36)],
		"density": 0.55,
		"corpse_chance": 0.35,
		"blood_chance":  0.45,
		"growth_chance": 0.12,
		"names":  ["MAINT", "AUX", "PUMP", "ELEC", "VALVE", "DUCT", "WORKSHOP"],
	},
	"lab": {
		"name":   "lab",
		"wall":   Color(0.28, 0.31, 0.36),
		"floor":  Color(0.32, 0.34, 0.38),
		"ceil":   Color(0.12, 0.13, 0.16),
		"props":  [Color(0.42, 0.44, 0.48), Color(0.30, 0.34, 0.40), Color(0.46, 0.48, 0.52)],
		"density": 0.60,
		"corpse_chance": 0.40,
		"blood_chance":  0.50,
		"growth_chance": 0.30,
		"names":  ["TEST", "SPECIMEN", "SAMPLE", "PCR", "INCUB", "AUTOCLAVE", "ANALYSIS"],
	},
	"dorm": {
		"name":   "dorm",
		"wall":   Color(0.30, 0.33, 0.38),
		"floor":  Color(0.34, 0.36, 0.40),
		"ceil":   Color(0.13, 0.14, 0.17),
		"props":  [Color(0.50, 0.30, 0.22), Color(0.28, 0.25, 0.18), Color(0.40, 0.34, 0.28)],
		"density": 0.55,
		"corpse_chance": 0.45,
		"blood_chance":  0.45,
		"growth_chance": 0.10,
		"names":  ["BUNK", "QTR", "PERS", "REC", "MESS", "WASH"],
	},
	"admin": {
		"name":   "admin",
		"wall":   Color(0.32, 0.34, 0.38),
		"floor":  Color(0.36, 0.38, 0.42),
		"ceil":   Color(0.14, 0.15, 0.18),
		"props":  [Color(0.30, 0.27, 0.22), Color(0.26, 0.28, 0.31), Color(0.20, 0.22, 0.26)],
		"density": 0.50,
		"corpse_chance": 0.35,
		"blood_chance":  0.40,
		"growth_chance": 0.08,
		"names":  ["ADMIN", "RADIO", "OPS", "ARCH", "FILES", "MEET"],
	},
	"ice": {
		"name":   "ice",
		"wall":   Color(0.34, 0.42, 0.52),
		"floor":  Color(0.40, 0.48, 0.58),
		"ceil":   Color(0.14, 0.18, 0.24),
		"props":  [Color(0.52, 0.66, 0.80), Color(0.40, 0.48, 0.58), Color(0.46, 0.54, 0.66)],
		"density": 0.30,
		"corpse_chance": 0.40,
		"blood_chance":  0.30,
		"growth_chance": 0.45,
		"names":  ["FISSURE", "SHELF", "DEPTH", "STRATUM"],
	},
}


# --- Public: stamp a corridor with N side rooms ---------------------------
# cfg: {
#   theme: String                     (key into THEMES)
#   axis: "x" | "z"                   (which axis the corridor RUNS along)
#   along_min, along_max: float       (corridor extent along its axis)
#   perp: float                       (the corridor's centerline on the other axis)
#   corridor_w: float                 (corridor width, default 4)
#   corridor_h: float                 (corridor height, default 3)
#   rooms_left: int                   (# side rooms on the smaller-perp side)
#   rooms_right: int                  (# side rooms on the larger-perp side)
#   room_depth: float                 (how far each side room extends from the corridor)
#   room_w_along: float               (each side room's extent along the corridor)
#   room_h: float                     (side room ceiling height)
#   seed: int                         (RNG seed for dressing variation)
#   seal_low_end, seal_high_end: bool (close off the corridor ends)
# }
# Returns total rooms placed (corridor + side rooms).
#
# Seam contract: every side room's NEAR EDGE equals corridor's wall coord
# (the bug I had hand-writing earlier - this can't happen here, the math
# is forced).
static func stamp_corridor_wing(parent: Node3D, cfg: Dictionary) -> int:
	var theme_name: String = cfg.get("theme", "industrial")
	var theme: Dictionary = THEMES[theme_name]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.get("seed", 0))

	var axis: String = cfg.get("axis", "z")
	var along_min: float = float(cfg["along_min"])
	var along_max: float = float(cfg["along_max"])
	var perp: float = float(cfg["perp"])
	var c_w: float = float(cfg.get("corridor_w", 4.0))
	var c_h: float = float(cfg.get("corridor_h", 3.0))
	var n_left: int = int(cfg.get("rooms_left", 0))
	var n_right: int = int(cfg.get("rooms_right", 0))
	var room_depth: float = float(cfg.get("room_depth", 7.0))
	var room_w_along: float = float(cfg.get("room_w_along", 6.0))
	var room_h: float = float(cfg.get("room_h", 3.0))
	var seal_low: bool = bool(cfg.get("seal_low_end", true))
	var seal_high: bool = bool(cfg.get("seal_high_end", true))

	# Corridor walls' perpendicular coordinates (the seam-coordinate that
	# side rooms must match exactly on their near edge).
	var corridor_low_perp: float = perp - c_w / 2.0
	var corridor_high_perp: float = perp + c_w / 2.0

	# Distribute door positions evenly along the corridor for each side.
	var left_doors: Array[float] = _distribute(along_min, along_max, n_left, room_w_along)
	var right_doors: Array[float] = _distribute(along_min, along_max, n_right, room_w_along)

	# Build the corridor: floor + ceiling + low/high walls with doorway gaps,
	# plus end walls.
	_stamp_corridor_box(parent, theme, axis, along_min, along_max, perp, c_w, c_h,
		left_doors, right_doors, seal_low, seal_high)

	# Stride between adjacent rooms on one side = corridor length / n. Each
	# room's variable along-extent must fit inside its stride with at least
	# 1.5 of wall between neighbors so the corridor wall doesn't get eaten.
	var c_len: float = along_max - along_min
	var stride_left: float = c_len / max(n_left, 1)
	var stride_right: float = c_len / max(n_right, 1)
	var max_w_left: float = max(Chamber.DOOR_W + 1.6, stride_left - 1.8)
	var max_w_right: float = max(Chamber.DOOR_W + 1.6, stride_right - 1.8)

	var count := 1  # the corridor itself
	for door_along in left_doors:
		_stamp_side_room(parent, theme, axis, true, door_along, room_w_along,
			max_w_left, corridor_low_perp, room_depth, room_h, rng)
		count += 1
	for door_along in right_doors:
		_stamp_side_room(parent, theme, axis, false, door_along, room_w_along,
			max_w_right, corridor_high_perp, room_depth, room_h, rng)
		count += 1

	# Atmosphere: dust in the corridor body so the wing reads as a real space.
	var c_center_along: float = (along_min + along_max) / 2.0
	var c_len: float = along_max - along_min
	var dust_center: Vector3 = _vec(axis, perp, c_center_along, c_h * 0.5)
	var dust_extents: Vector3 = _vec(axis, c_w * 0.4, c_len * 0.45, c_h * 0.5)
	ActUtil.add_dust_motes(parent, dust_center, dust_extents, max(20, int(c_len * 4.0)),
		Color(0.72, 0.78, 0.88, 0.12))

	return count


# --- Internals ------------------------------------------------------------

# Builds the corridor floor/ceiling and its four walls (low-perp wall and
# high-perp wall each get multiple doorway gaps via wall-segment runs;
# end walls are solid or sealed depending on cfg).
static func _stamp_corridor_box(parent: Node3D, theme: Dictionary, axis: String,
		along_min: float, along_max: float, perp: float, c_w: float, c_h: float,
		left_doors: Array[float], right_doors: Array[float],
		seal_low: bool, seal_high: bool) -> void:
	var c_center_along: float = (along_min + along_max) / 2.0
	var c_len: float = along_max - along_min
	var corridor_low_perp: float = perp - c_w / 2.0
	var corridor_high_perp: float = perp + c_w / 2.0

	if axis == "z":
		# z-axis corridor: along varies in z, perpendicular axis is x.
		Chamber.add_floor_ceiling(parent, c_w, c_len, c_h, theme["floor"], theme["ceil"],
			Vector3(perp, 0, c_center_along))
		# Low-x wall (left side) with doorway gaps for each left room.
		_run_wall_with_multi_gaps(parent, "x", corridor_low_perp, along_min, along_max,
			c_h, theme["wall"], left_doors)
		# High-x wall (right side).
		_run_wall_with_multi_gaps(parent, "x", corridor_high_perp, along_min, along_max,
			c_h, theme["wall"], right_doors)
		# End walls (z-axis walls). Sealed = solid; unsealed = doorway gap at
		# the corridor centerline (perp) so an adjoining wing can chain on.
		_end_wall(parent, "z", along_min, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"], perp, seal_low)
		_end_wall(parent, "z", along_max, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"], perp, seal_high)
	else:
		# x-axis corridor: along varies in x, perpendicular axis is z.
		Chamber.add_floor_ceiling(parent, c_len, c_w, c_h, theme["floor"], theme["ceil"],
			Vector3(c_center_along, 0, perp))
		_run_wall_with_multi_gaps(parent, "z", corridor_low_perp, along_min, along_max,
			c_h, theme["wall"], left_doors)
		_run_wall_with_multi_gaps(parent, "z", corridor_high_perp, along_min, along_max,
			c_h, theme["wall"], right_doors)
		_end_wall(parent, "x", along_min, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"], perp, seal_low)
		_end_wall(parent, "x", along_max, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"], perp, seal_high)


# An end-cap wall. If sealed, a solid wall; otherwise a wall with a doorway
# gap at gap_center so the next wing chains seamlessly onto this opening.
static func _end_wall(parent: Node3D, axis: String, fixed: float,
		span_min: float, span_max: float, h: float, color: Color,
		gap_center: float, sealed: bool) -> void:
	if sealed:
		Chamber.add_wall(parent, axis, fixed, span_min, span_max, h, color)
	else:
		Chamber.add_wall(parent, axis, fixed, span_min, span_max, h, color, gap_center)


# Run a single straight wall with N doorway gaps. Each gap is DOOR_W wide
# centred on the listed positions. Wall thickness still 0.2.
static func _run_wall_with_multi_gaps(parent: Node3D, axis: String, fixed: float,
		span_min: float, span_max: float, h: float, color: Color,
		gap_centers: Array[float]) -> void:
	if gap_centers.is_empty():
		Chamber.add_wall(parent, axis, fixed, span_min, span_max, h, color)
		return
	# Sort gaps so we can walk left to right and emit segments between them.
	var gaps: Array[float] = gap_centers.duplicate()
	gaps.sort()
	var half: float = Chamber.DOOR_W / 2.0
	var cursor: float = span_min
	for g in gaps:
		var gap_low: float = g - half
		var gap_high: float = g + half
		if gap_low > cursor:
			Chamber.add_wall(parent, axis, fixed, cursor, gap_low, h, color)
		# Each gap also gets a doorframe + header beam so it reads as a portal,
		# matching how Chamber.add_wall renders a single gap.
		_add_header_and_frame(parent, axis, fixed, g, h, color)
		cursor = gap_high
	if span_max > cursor:
		Chamber.add_wall(parent, axis, fixed, cursor, span_max, h, color)


# Match Chamber's single-gap "header above the opening + emissive doorframe"
# treatment so multi-gap walls don't look different from single-gap ones.
static func _add_header_and_frame(parent: Node3D, axis: String, fixed: float,
		gap_center: float, h: float, color: Color) -> void:
	var header_h: float = max(0.0, h - Chamber.DOOR_H)
	if header_h > 0.001:
		var hpos: Vector3
		var hsize: Vector3
		if axis == "x":
			hpos = Vector3(fixed, Chamber.DOOR_H + header_h / 2.0, gap_center)
			hsize = Vector3(0.2, header_h, Chamber.DOOR_W + 0.2)
		else:
			hpos = Vector3(gap_center, Chamber.DOOR_H + header_h / 2.0, fixed)
			hsize = Vector3(Chamber.DOOR_W + 0.2, header_h, 0.2)
		Chamber.make_prop_box(parent, hsize, hpos, color, true, "header")


# Stamp one side room. is_low_side=true means the room is on the smaller-perp
# side of the corridor (its near edge is at corridor_low_perp, far edge
# extends away). The room's perpendicular span runs from far_edge to near_edge.
#
# Per-room dimension variation: each room rolls its own w_along, depth, and
# height (clamped so neighbor frontage and doorway alignment are preserved).
# This is what stops every room from looking like the next.
static func _stamp_side_room(parent: Node3D, theme: Dictionary, corridor_axis: String,
		is_low_side: bool, door_along: float, base_w_along: float, max_w_along: float,
		near_edge_perp: float, base_depth: float, base_h: float,
		rng: RandomNumberGenerator) -> void:
	# Roll dimensions per room. w_along is clamped tight enough that the
	# doorway gap (DOOR_W wide centred at door_along) remains inside the room
	# and adjacent rooms keep at least ~1.8 of wall between them.
	var w_along: float = clamp(base_w_along * rng.randf_range(0.72, 1.30),
		Chamber.DOOR_W + 1.4, max_w_along)
	var room_depth: float = clamp(base_depth * rng.randf_range(0.65, 1.55), 4.0, 14.0)
	var room_h: float = clamp(base_h * rng.randf_range(0.82, 1.35), 2.4, 4.6)

	# Room's perpendicular extent.
	var far_edge_perp: float
	if is_low_side:
		far_edge_perp = near_edge_perp - room_depth
	else:
		far_edge_perp = near_edge_perp + room_depth
	var perp_low: float = min(near_edge_perp, far_edge_perp)
	var perp_high: float = max(near_edge_perp, far_edge_perp)
	var perp_center: float = (perp_low + perp_high) / 2.0
	# Room's along extent.
	var along_low: float = door_along - w_along / 2.0
	var along_high: float = door_along + w_along / 2.0
	var along_center: float = door_along

	# Build the floor + ceiling slab, sized to perp_high - perp_low x along.
	if corridor_axis == "z":
		# perp = x, along = z
		Chamber.add_floor_ceiling(parent, room_depth, w_along, room_h,
			theme["floor"], theme["ceil"], Vector3(perp_center, 0, along_center))
		# Far wall (parallel to corridor wall, perpendicular axis).
		Chamber.add_wall(parent, "x", far_edge_perp, along_low, along_high, room_h, theme["wall"])
		# Two side walls (perpendicular to corridor).
		Chamber.add_wall(parent, "z", along_low, perp_low, perp_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "z", along_high, perp_low, perp_high, room_h, theme["wall"])
	else:
		# perp = z, along = x
		Chamber.add_floor_ceiling(parent, w_along, room_depth, room_h,
			theme["floor"], theme["ceil"], Vector3(along_center, 0, perp_center))
		Chamber.add_wall(parent, "z", far_edge_perp, along_low, along_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "x", along_low, perp_low, perp_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "x", along_high, perp_low, perp_high, room_h, theme["wall"])

	# Roll an internal partition occasionally (~25% chance, only if the room
	# is large enough). The partition runs perpendicular to the door axis,
	# splits the room into two visual zones, and has its own 1.4-wide opening
	# offset from the entry door so the room reads as two connected spaces
	# rather than one box.
	if rng.randf() < 0.25 and room_depth >= 7.5 and w_along >= 5.5:
		_add_internal_partition(parent, theme, corridor_axis, is_low_side,
			perp_low, perp_high, along_low, along_high, room_h, rng)

	# Dispatch dressing to the theme's archetype. Each archetype lays out
	# characteristic furniture instead of the previous random-cuboid spray.
	_dress_dispatch(parent, theme, perp_low, perp_high, along_low, along_high,
		room_h, corridor_axis, is_low_side, rng)


# Dispatch to a theme-specific dresser. Each archetype produces
# characteristic furniture rather than a uniform cuboid spray, so a dorm
# reads as a dorm (bunks, footlockers) and a lab reads as a lab (benches,
# glassware), even when both rooms are the same dimensions.
#
# After the archetype lays its furniture, _scatter_atmosphere adds
# theme-tuned corpses, blood, growth - the previously-shared horror layer.
static func _dress_dispatch(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String, is_low_side: bool,
		rng: RandomNumberGenerator) -> void:
	var theme_name: String = theme.get("name", "industrial")
	# near_perp is the corridor-side edge of the room - we point the room's
	# "back" furniture against far_perp so the door isn't blocked.
	var near_perp: float
	var far_perp: float
	if is_low_side:
		near_perp = perp_high  # corridor is at perp_high for low-side rooms
		far_perp = perp_low
	else:
		near_perp = perp_low
		far_perp = perp_high

	match theme_name:
		"dorm":
			_dress_dorm(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)
		"lab":
			_dress_lab(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)
		"admin":
			_dress_admin(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)
		"industrial":
			_dress_industrial(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)
		"ice":
			_dress_ice(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)
		_:
			_dress_industrial(parent, theme, perp_low, perp_high, along_low, along_high,
				room_h, corridor_axis, near_perp, far_perp, rng)

	_scatter_atmosphere(parent, theme, perp_low, perp_high, along_low, along_high,
		corridor_axis, rng)


# --- Theme archetypes -----------------------------------------------------
# Each builds characteristic furniture out of make_prop_box. Furniture is
# anchored to walls where it would physically sit (bunks against far wall,
# desks under windows, machines centred) so rooms read as occupied spaces
# rather than scattered junk. The rng-picked sub-variant inside each
# archetype keeps no two rooms identical even with the same theme.

# DORM: bunks against the far wall, footlocker/dresser/wall locker variants.
static func _dress_dorm(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String,
		near_perp: float, far_perp: float, rng: RandomNumberGenerator) -> void:
	var variant: int = rng.randi() % 3
	var bunk_col: Color = Color(0.32, 0.28, 0.22)
	var mattress_col: Color = Color(0.46, 0.36, 0.30)
	var blanket_col: Color = Color(0.30, 0.16, 0.14)
	var locker_col: Color = Color(0.26, 0.28, 0.32)
	var sign_perp: float = signf(far_perp - near_perp)
	# A bunk is 2.0 long (along), 0.9 deep (perp), 1.8 tall stacked.
	# Place bunk's perp center 0.6 in from the far wall so its back touches.
	var bunk_perp_center: float = far_perp - sign_perp * 0.55

	if variant == 0:
		# "Two bunks": stacked bunk near each along-end of the far wall.
		for off in [-1, 1]:
			var ac: float = (along_low + along_high) / 2.0 + off * ((along_high - along_low) / 2.0 - 1.2)
			_place_bunk(parent, corridor_axis, bunk_perp_center, ac, bunk_col, mattress_col, blanket_col)
		# Footlocker at the foot of one bunk.
		var fpos: Vector3 = _flat_pos(corridor_axis,
			bunk_perp_center - sign_perp * 1.4, (along_low + along_high) / 2.0)
		fpos.y = 0.25
		Chamber.make_prop_box(parent, Vector3(1.2, 0.5, 0.6), fpos, Color(0.20, 0.18, 0.16))
	elif variant == 1:
		# "Bunk + desk": one bunk on far wall, desk against one side wall.
		var ac1: float = (along_low + along_high) / 2.0 + ((along_high - along_low) / 2.0 - 1.2)
		_place_bunk(parent, corridor_axis, bunk_perp_center, ac1, bunk_col, mattress_col, blanket_col)
		# Desk against the OPPOSITE along-side wall.
		var desk_along: float = along_low + 0.8
		var desk_perp: float = bunk_perp_center
		var dpos: Vector3 = _flat_pos(corridor_axis, desk_perp, desk_along)
		dpos.y = 0.4
		Chamber.make_prop_box(parent, Vector3(1.2, 0.8, 0.7), dpos, Color(0.36, 0.26, 0.20))
		# Chair tucked in.
		var chair_along: float = desk_along + 0.7
		var chair_perp: float = bunk_perp_center - sign_perp * 0.5
		var cpos: Vector3 = _flat_pos(corridor_axis, chair_perp, chair_along)
		Chamber.make_chair(parent, cpos, Color(0.22, 0.20, 0.18), 0.0, 0.5)
	else:
		# "Stripped": mattress on floor + wall locker.
		var mpos: Vector3 = _flat_pos(corridor_axis,
			far_perp - sign_perp * 0.9, (along_low + along_high) / 2.0)
		mpos.y = 0.08
		Chamber.make_prop_box(parent, Vector3(2.0, 0.15, 0.85), mpos, mattress_col)
		# Two wall lockers against the far wall, narrower side.
		for off in [-0.9, 0.9]:
			var ac: float = (along_low + along_high) / 2.0 + off
			var lp: Vector3 = _flat_pos(corridor_axis,
				far_perp - sign_perp * 0.3, ac)
			lp.y = 0.85
			Chamber.make_prop_box(parent, Vector3(0.7, 1.7, 0.5), lp, locker_col)


static func _place_bunk(parent: Node3D, corridor_axis: String,
		perp_center: float, along_center: float,
		frame_col: Color, mattress_col: Color, blanket_col: Color) -> void:
	# Stacked bunk: lower bed + upper bed + four corner posts.
	var bunk_size: Vector3 = Vector3(2.0, 0.2, 0.9)
	# Lower mattress at y=0.4.
	var lp: Vector3 = _flat_pos(corridor_axis, perp_center, along_center)
	lp.y = 0.4
	Chamber.make_prop_box(parent, bunk_size, lp, mattress_col)
	# Lower blanket (slightly smaller, on top of mattress, brighter).
	var blp: Vector3 = lp
	blp.y = 0.52
	Chamber.make_prop_box(parent, Vector3(1.8, 0.05, 0.7), blp, blanket_col)
	# Upper mattress at y=1.55.
	var up: Vector3 = lp
	up.y = 1.55
	Chamber.make_prop_box(parent, bunk_size, up, mattress_col)
	# Upper blanket.
	var bup: Vector3 = up
	bup.y = 1.67
	Chamber.make_prop_box(parent, Vector3(1.8, 0.05, 0.7), bup, blanket_col)
	# Frame ladder at one end.
	var ladder_pos: Vector3 = _flat_pos(corridor_axis, perp_center + 0.35, along_center + 0.95)
	ladder_pos.y = 1.0
	Chamber.make_prop_box(parent, Vector3(0.06, 1.8, 0.06), ladder_pos, frame_col)


# LAB: workbench against the far wall, glassware on top, equipment racks.
static func _dress_lab(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String,
		near_perp: float, far_perp: float, rng: RandomNumberGenerator) -> void:
	var variant: int = rng.randi() % 3
	var sign_perp: float = signf(far_perp - near_perp)
	var bench_col: Color = Color(0.42, 0.44, 0.48)
	var glass_col: Color = Color(0.55, 0.78, 0.72)
	var rack_col: Color = Color(0.30, 0.32, 0.38)
	var w: float = along_high - along_low
	# Workbench: runs along the far wall, 0.7 deep, 0.9 tall.
	var bench_perp: float = far_perp - sign_perp * 0.4
	var bench_along: float = (along_low + along_high) / 2.0
	var bench_w: float = clamp(w - 1.2, 1.6, 4.0)
	var bp: Vector3 = _flat_pos(corridor_axis, bench_perp, bench_along)
	bp.y = 0.45
	Chamber.make_prop_box(parent, Vector3(bench_w, 0.9, 0.7), bp, bench_col)

	if variant == 0:
		# "Wet lab": bottles on the bench, centrifuge.
		for i in 5:
			var ax: float = bench_along - bench_w / 2.0 + 0.35 + (bench_w - 0.7) * (i / 4.0)
			var gp: Vector3 = _flat_pos(corridor_axis, bench_perp, ax)
			gp.y = 1.05 + (i % 2) * 0.05
			Chamber.make_prop_box(parent, Vector3(0.18, 0.35, 0.18), gp, glass_col)
		# Centrifuge on the bench.
		var cp: Vector3 = _flat_pos(corridor_axis, bench_perp, bench_along + bench_w * 0.3)
		cp.y = 1.15
		Chamber.make_prop_box(parent, Vector3(0.5, 0.5, 0.5), cp, Color(0.50, 0.52, 0.56))
	elif variant == 1:
		# "Specimen room": tanks in a row, an equipment rack.
		for i in 3:
			var ax: float = bench_along - 1.4 + i * 1.4
			var tp: Vector3 = _flat_pos(corridor_axis, bench_perp + sign_perp * 0.0, ax)
			tp.y = 1.25
			Chamber.make_prop_box(parent, Vector3(0.55, 0.6, 0.55), tp,
				Color(0.30, 0.55, 0.45, 1.0))
		# Equipment rack against side wall.
		var rp: Vector3 = _flat_pos(corridor_axis, far_perp - sign_perp * 1.4, along_low + 0.7)
		rp.y = 0.9
		Chamber.make_prop_box(parent, Vector3(0.6, 1.8, 0.6), rp, rack_col)
	else:
		# "Ruined": shattered glass on the bench, an overturned stool.
		for _i in 4:
			var ax2: float = rng.randf_range(bench_along - bench_w / 2.0 + 0.3, bench_along + bench_w / 2.0 - 0.3)
			var sp: Vector3 = _flat_pos(corridor_axis, bench_perp, ax2)
			sp.y = 1.0
			Chamber.make_prop_box(parent, Vector3(rng.randf_range(0.1, 0.3), 0.08, rng.randf_range(0.1, 0.3)),
				sp, Color(0.6, 0.78, 0.74, 1.0))
		var stool_p: Vector3 = _flat_pos(corridor_axis, bench_perp - sign_perp * 1.1, bench_along - bench_w * 0.3)
		stool_p.y = 0.25
		Chamber.make_prop_box(parent, Vector3(0.45, 0.45, 0.45), stool_p, Color(0.32, 0.28, 0.24))


# ADMIN: desk + chair + filing cabinet variants. The "office" archetype.
static func _dress_admin(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String,
		near_perp: float, far_perp: float, rng: RandomNumberGenerator) -> void:
	var variant: int = rng.randi() % 3
	var sign_perp: float = signf(far_perp - near_perp)
	var desk_col: Color = Color(0.34, 0.26, 0.20)
	var cabinet_col: Color = Color(0.24, 0.26, 0.30)
	var paper_col: Color = Color(0.78, 0.74, 0.62)
	var along_center: float = (along_low + along_high) / 2.0

	if variant == 0:
		# "Office": desk facing the door, chair behind, cabinet against side.
		var desk_perp: float = far_perp - sign_perp * 0.55
		var dp: Vector3 = _flat_pos(corridor_axis, desk_perp, along_center)
		dp.y = 0.4
		Chamber.make_prop_box(parent, Vector3(1.6, 0.8, 0.8), dp, desk_col)
		# Monitor (broken) on desk.
		var mon_p: Vector3 = _flat_pos(corridor_axis, desk_perp - sign_perp * 0.05, along_center - 0.4)
		mon_p.y = 1.0
		Chamber.make_prop_box(parent, Vector3(0.55, 0.4, 0.1), mon_p, Color(0.10, 0.11, 0.12))
		# Chair behind desk.
		var chair_perp: float = desk_perp - sign_perp * 0.8
		var cp: Vector3 = _flat_pos(corridor_axis, chair_perp, along_center)
		Chamber.make_chair(parent, cp, Color(0.22, 0.20, 0.18), 0.0, 0.5)
		# Filing cabinet against side wall.
		var cab_p: Vector3 = _flat_pos(corridor_axis, far_perp - sign_perp * 0.35, along_low + 0.5)
		cab_p.y = 0.75
		Chamber.make_prop_box(parent, Vector3(0.6, 1.5, 0.6), cab_p, cabinet_col)
		# Paper stack on desk.
		var pp: Vector3 = _flat_pos(corridor_axis, desk_perp + sign_perp * 0.1, along_center + 0.5)
		pp.y = 0.86
		Chamber.make_prop_box(parent, Vector3(0.3, 0.12, 0.4), pp, paper_col)
	elif variant == 1:
		# "Archive": rows of filing cabinets along the far wall.
		var cab_perp: float = far_perp - sign_perp * 0.35
		var w: float = along_high - along_low
		var n: int = max(3, int(w / 0.9))
		for i in n:
			var ax: float = along_low + 0.6 + (w - 1.2) * (float(i) / float(n - 1))
			var cap: Vector3 = _flat_pos(corridor_axis, cab_perp, ax)
			cap.y = 0.75
			Chamber.make_prop_box(parent, Vector3(0.7, 1.5, 0.6), cap, cabinet_col)
		# Loose papers on the floor.
		for _i in 4:
			var px: float = rng.randf_range(along_low + 1.0, along_high - 1.0)
			var pp_perp: float = rng.randf_range(near_perp + sign_perp * 0.8, far_perp - sign_perp * 1.4)
			var pp2: Vector3 = _flat_pos(corridor_axis, pp_perp, px)
			pp2.y = 0.04
			Chamber.make_prop_box(parent, Vector3(rng.randf_range(0.25, 0.4), 0.04, rng.randf_range(0.3, 0.5)),
				pp2, paper_col)
	else:
		# "Comms": equipment rack + console + cabling.
		var rack_perp: float = far_perp - sign_perp * 0.4
		for off in [-1.2, 0.0, 1.2]:
			var rp: Vector3 = _flat_pos(corridor_axis, rack_perp, along_center + off)
			rp.y = 0.95
			Chamber.make_prop_box(parent, Vector3(0.7, 1.9, 0.7), rp, Color(0.15, 0.17, 0.20))
			# Status panel on each rack.
			var sp: Vector3 = _flat_pos(corridor_axis, rack_perp - sign_perp * 0.05, along_center + off)
			sp.y = 1.4
			Chamber.make_prop_box(parent, Vector3(0.4, 0.2, 0.05), sp, Color(0.20, 0.05, 0.05, 1.0))
		# Console facing the racks.
		var con_perp: float = near_perp + sign_perp * 1.4
		var conp: Vector3 = _flat_pos(corridor_axis, con_perp, along_center)
		conp.y = 0.55
		Chamber.make_prop_box(parent, Vector3(1.8, 1.1, 0.7), conp, Color(0.18, 0.20, 0.22))


# INDUSTRIAL: machinery centrepieces, crates, barrels, pipes.
static func _dress_industrial(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String,
		near_perp: float, far_perp: float, rng: RandomNumberGenerator) -> void:
	var variant: int = rng.randi() % 3
	var sign_perp: float = signf(far_perp - near_perp)
	var metal_col: Color = Color(0.38, 0.40, 0.44)
	var crate_col: Color = Color(0.34, 0.26, 0.18)
	var barrel_col: Color = Color(0.28, 0.24, 0.20)
	var pipe_col: Color = Color(0.46, 0.42, 0.36)
	var along_center: float = (along_low + along_high) / 2.0

	if variant == 0:
		# "Machine bay": one big machine + pipes overhead.
		var m_perp: float = (near_perp + far_perp) / 2.0
		var mp: Vector3 = _flat_pos(corridor_axis, m_perp, along_center)
		mp.y = 0.9
		Chamber.make_prop_box(parent, Vector3(1.6, 1.8, 1.4), mp, metal_col)
		# Output pipe up to ceiling.
		var pp: Vector3 = _flat_pos(corridor_axis, m_perp, along_center + 0.5)
		pp.y = (1.8 + room_h) / 2.0
		Chamber.make_prop_box(parent, Vector3(0.35, room_h - 1.8, 0.35), pp, pipe_col)
		# A side panel/access door on the machine.
		var sd: Vector3 = _flat_pos(corridor_axis, m_perp - sign_perp * 0.75, along_center)
		sd.y = 1.1
		Chamber.make_prop_box(parent, Vector3(0.05, 1.0, 0.6), sd, Color(0.55, 0.10, 0.08))
	elif variant == 1:
		# "Storage": stacked crates in two rows.
		for row in 2:
			var perp_off: float = (far_perp - near_perp) * (0.30 + 0.30 * row)
			var c_perp: float = near_perp + perp_off
			for col in 3:
				var ax: float = along_low + 0.9 + col * 1.4
				if ax > along_high - 0.8:
					continue
				var stack_h: int = 1 + rng.randi() % 2
				for stack in stack_h:
					var p: Vector3 = _flat_pos(corridor_axis, c_perp, ax)
					p.y = 0.5 + stack * 1.0
					Chamber.make_prop_box(parent, Vector3(1.0, 1.0, 1.0), p,
						crate_col.lerp(Color(0.5, 0.4, 0.3), float(stack) * 0.2))
	else:
		# "Pipe room": barrels + valve manifold on the far wall.
		# Barrels in a cluster.
		var barrel_count: int = 3 + rng.randi() % 3
		for i in barrel_count:
			var bx: float = along_low + 0.8 + i * 0.85
			if bx > along_high - 0.6:
				break
			var b_perp: float = far_perp - sign_perp * (1.5 + (i % 2) * 0.4)
			var bp: Vector3 = _flat_pos(corridor_axis, b_perp, bx)
			bp.y = 0.5
			Chamber.make_prop_box(parent, Vector3(0.6, 1.0, 0.6), bp, barrel_col)
		# Pipe along the far wall at mid height.
		var pp_perp: float = far_perp - sign_perp * 0.2
		var pipe_y: float = room_h * 0.6
		var pp: Vector3 = _flat_pos(corridor_axis, pp_perp, along_center)
		pp.y = pipe_y
		var pipe_along: float = (along_high - along_low) - 0.6
		if corridor_axis == "z":
			Chamber.make_prop_box(parent, Vector3(0.25, 0.25, pipe_along), pp, pipe_col)
		else:
			Chamber.make_prop_box(parent, Vector3(pipe_along, 0.25, 0.25), pp, pipe_col)
		# Two valve wheels on the pipe.
		for off in [-0.9, 0.9]:
			var vp: Vector3 = _flat_pos(corridor_axis, pp_perp - sign_perp * 0.1, along_center + off)
			vp.y = pipe_y
			Chamber.make_prop_box(parent, Vector3(0.4, 0.4, 0.05), vp, Color(0.45, 0.20, 0.15))


# ICE: sparse - irregular ice formations + crystals + occasional frozen body.
static func _dress_ice(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String,
		near_perp: float, far_perp: float, rng: RandomNumberGenerator) -> void:
	var variant: int = rng.randi() % 2
	var sign_perp: float = signf(far_perp - near_perp)
	var ice_a: Color = Color(0.54, 0.68, 0.82, 1.0)
	var ice_b: Color = Color(0.46, 0.56, 0.70, 1.0)
	var crystal: Color = Color(0.66, 0.78, 0.90, 1.0)

	if variant == 0:
		# "Stalagmite cavern": vertical ice spikes from floor.
		var n: int = 4 + rng.randi() % 4
		for _i in n:
			var ax: float = rng.randf_range(along_low + 0.6, along_high - 0.6)
			var px: float = rng.randf_range(perp_low + 0.6, perp_high - 0.6)
			var sp: Vector3 = _flat_pos(corridor_axis, px, ax)
			var h: float = rng.randf_range(0.6, 1.8)
			sp.y = h / 2.0
			Chamber.make_prop_box(parent, Vector3(rng.randf_range(0.3, 0.7), h, rng.randf_range(0.3, 0.7)),
				sp, ice_a if rng.randf() < 0.5 else ice_b)
		# A few hanging crystals (cubes near ceiling).
		for _i in 3:
			var ax2: float = rng.randf_range(along_low + 0.6, along_high - 0.6)
			var px2: float = rng.randf_range(perp_low + 0.6, perp_high - 0.6)
			var cp: Vector3 = _flat_pos(corridor_axis, px2, ax2)
			cp.y = room_h - rng.randf_range(0.3, 0.8)
			Chamber.make_prop_box(parent, Vector3(0.3, 0.4, 0.3), cp, crystal)
	else:
		# "Frozen storage": a few boxes encased in ice.
		var crate_col: Color = Color(0.36, 0.40, 0.46)
		for _i in 2:
			var ax3: float = rng.randf_range(along_low + 1.0, along_high - 1.0)
			var pos: Vector3 = _flat_pos(corridor_axis, far_perp - sign_perp * 1.4, ax3)
			pos.y = 0.5
			Chamber.make_prop_box(parent, Vector3(1.0, 1.0, 1.0), pos, crate_col)
			# Ice shell over each crate.
			var shell_pos: Vector3 = pos
			shell_pos.y = 0.55
			Chamber.make_prop_box(parent, Vector3(1.2, 1.2, 1.2), shell_pos, ice_a)
		# A single ice mound near the door.
		var moundp: Vector3 = _flat_pos(corridor_axis,
			near_perp + sign_perp * 1.4, (along_low + along_high) / 2.0)
		moundp.y = 0.45
		Chamber.make_prop_box(parent, Vector3(1.6, 0.9, 1.2), moundp, ice_b)


# Internal partition: a ceiling-high wall that splits the room into two
# zones, with a DOOR_W-wide opening offset from the entry door so the room
# reads as two connected spaces. Runs perpendicular to the door axis.
static func _add_internal_partition(parent: Node3D, theme: Dictionary,
		corridor_axis: String, is_low_side: bool,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, rng: RandomNumberGenerator) -> void:
	# Partition is parallel to the corridor (so its "fixed" axis = perp axis).
	# Place it ~60% of the depth toward the far wall.
	var t: float = rng.randf_range(0.55, 0.70)
	var p_perp: float = perp_low + (perp_high - perp_low) * t
	# Opening centred ~30% off the centerline, so doorway isn't aligned with
	# the entry door (which is the corridor-side door).
	var ac: float = (along_low + along_high) / 2.0
	var w: float = along_high - along_low
	var offset: float = (rng.randf() * 2.0 - 1.0) * (w * 0.25)
	var gap_center: float = clamp(ac + offset, along_low + 1.0, along_high - 1.0)
	var part_color: Color = theme.get("wall", Color(0.30, 0.32, 0.36))

	if corridor_axis == "z":
		# Partition runs along z (along axis), fixed in x at p_perp.
		Chamber.add_wall(parent, "x", p_perp, along_low, along_high, room_h, part_color, gap_center)
	else:
		Chamber.add_wall(parent, "z", p_perp, along_low, along_high, room_h, part_color, gap_center)


# Atmospheric horror layer: corpses, blood, growth - rolled per theme.
# Position rolls avoid the centre line where the entry door arrives.
static func _scatter_atmosphere(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		corridor_axis: String, rng: RandomNumberGenerator) -> void:
	var pad: float = 0.8
	# Corpse.
	if rng.randf() < float(theme.get("corpse_chance", 0.3)):
		var cp_perp: float = rng.randf_range(perp_low + pad, perp_high - pad)
		var cp_along: float = rng.randf_range(along_low + pad, along_high - pad)
		var cp: Vector3 = _flat_pos(corridor_axis, cp_perp, cp_along)
		ActUtil.corpse(parent, cp, rng.randf_range(0, 360), true,
			Color(0.20 + rng.randf() * 0.08, 0.22, 0.24))
	# Blood decal.
	if rng.randf() < float(theme.get("blood_chance", 0.4)):
		var bp_perp: float = rng.randf_range(perp_low + pad, perp_high - pad)
		var bp_along: float = rng.randf_range(along_low + pad, along_high - pad)
		var bp: Vector3 = _flat_pos(corridor_axis, bp_perp, bp_along)
		bp.y = 0.02
		ActUtil.blood_decal(parent, bp,
			Vector2(rng.randf_range(0.8, 2.0), rng.randf_range(0.8, 1.6)))
	# Signal growth (lab/ice especially).
	if rng.randf() < float(theme.get("growth_chance", 0.1)):
		var gp_perp: float = rng.randf_range(perp_low + pad, perp_high - pad)
		var gp_along: float = rng.randf_range(along_low + pad, along_high - pad)
		var gp: Vector3 = _flat_pos(corridor_axis, gp_perp, gp_along)
		ActUtil.signal_growth(parent, gp, rng.randf_range(0.8, 1.6),
			Color(0.07, 0.13, 0.10))


# Distribute N door positions evenly across the corridor span. Returns empty
# if n <= 0. Each door gets at least room_w_along of corridor frontage.
static func _distribute(span_min: float, span_max: float, n: int,
		room_w_along: float) -> Array[float]:
	var out: Array[float] = []
	if n <= 0:
		return out
	var avail: float = span_max - span_min
	# Each room consumes room_w_along of frontage; add pads at the ends.
	var stride: float = avail / float(n)
	for i in n:
		var c: float = span_min + stride * (float(i) + 0.5)
		out.append(c)
	return out


# Build a Vector3 where perp + along are placed onto the axes that match
# the corridor_axis convention. y is taken as-is.
static func _vec(corridor_axis: String, perp: float, along: float, y: float) -> Vector3:
	if corridor_axis == "z":
		return Vector3(perp, y, along)
	else:
		return Vector3(along, y, perp)


# Same as _vec but flat (y=0).
static func _flat_pos(corridor_axis: String, perp: float, along: float) -> Vector3:
	return _vec(corridor_axis, perp, along, 0.0)
