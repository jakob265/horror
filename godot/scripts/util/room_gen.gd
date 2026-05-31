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

	var count := 1  # the corridor itself
	for door_along in left_doors:
		_stamp_side_room(parent, theme, axis, true, door_along, room_w_along,
			corridor_low_perp, room_depth, room_h, rng)
		count += 1
	for door_along in right_doors:
		_stamp_side_room(parent, theme, axis, false, door_along, room_w_along,
			corridor_high_perp, room_depth, room_h, rng)
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
		# End walls (z-axis walls).
		Chamber.add_wall(parent, "z", along_min, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"])
		Chamber.add_wall(parent, "z", along_max, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"])
	else:
		# x-axis corridor: along varies in x, perpendicular axis is z.
		Chamber.add_floor_ceiling(parent, c_len, c_w, c_h, theme["floor"], theme["ceil"],
			Vector3(c_center_along, 0, perp))
		_run_wall_with_multi_gaps(parent, "z", corridor_low_perp, along_min, along_max,
			c_h, theme["wall"], left_doors)
		_run_wall_with_multi_gaps(parent, "z", corridor_high_perp, along_min, along_max,
			c_h, theme["wall"], right_doors)
		Chamber.add_wall(parent, "x", along_min, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"])
		Chamber.add_wall(parent, "x", along_max, corridor_low_perp, corridor_high_perp,
			c_h, theme["wall"])


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
static func _stamp_side_room(parent: Node3D, theme: Dictionary, corridor_axis: String,
		is_low_side: bool, door_along: float, room_w_along: float,
		near_edge_perp: float, room_depth: float, room_h: float,
		rng: RandomNumberGenerator) -> void:
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
	var along_low: float = door_along - room_w_along / 2.0
	var along_high: float = door_along + room_w_along / 2.0
	var along_center: float = door_along

	# Build the floor + ceiling slab, sized to perp_high - perp_low x along.
	if corridor_axis == "z":
		# perp = x, along = z
		Chamber.add_floor_ceiling(parent, room_depth, room_w_along, room_h,
			theme["floor"], theme["ceil"], Vector3(perp_center, 0, along_center))
		# Far wall (parallel to corridor wall, perpendicular axis).
		Chamber.add_wall(parent, "x", far_edge_perp, along_low, along_high, room_h, theme["wall"])
		# Two side walls (perpendicular to corridor).
		Chamber.add_wall(parent, "z", along_low, perp_low, perp_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "z", along_high, perp_low, perp_high, room_h, theme["wall"])
	else:
		# perp = z, along = x
		Chamber.add_floor_ceiling(parent, room_w_along, room_depth, room_h,
			theme["floor"], theme["ceil"], Vector3(along_center, 0, perp_center))
		Chamber.add_wall(parent, "z", far_edge_perp, along_low, along_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "x", along_low, perp_low, perp_high, room_h, theme["wall"])
		Chamber.add_wall(parent, "x", along_high, perp_low, perp_high, room_h, theme["wall"])

	# Dress the room according to the theme.
	_dress_room(parent, theme, perp_low, perp_high, along_low, along_high, room_h,
		corridor_axis, rng)


# Spray props/corpses/blood/growth into a room. Quantity = density * area.
# Themes vary palette + horror chance.
static func _dress_room(parent: Node3D, theme: Dictionary,
		perp_low: float, perp_high: float, along_low: float, along_high: float,
		room_h: float, corridor_axis: String, rng: RandomNumberGenerator) -> void:
	var perp_center: float = (perp_low + perp_high) / 2.0
	var along_center: float = (along_low + along_high) / 2.0
	var area: float = (perp_high - perp_low) * (along_high - along_low)
	var density: float = float(theme.get("density", 0.5))
	var prop_count: int = clamp(int(area * 0.18 * density), 2, 12)
	var palette: Array = theme.get("props", [Color(0.4, 0.4, 0.4)])

	# Pad inwards so props don't intersect walls.
	var pad: float = 0.7

	for _i in prop_count:
		var p_perp: float = rng.randf_range(perp_low + pad, perp_high - pad)
		var p_along: float = rng.randf_range(along_low + pad, along_high - pad)
		var pos: Vector3 = _flat_pos(corridor_axis, p_perp, p_along)
		var col: Color = palette[rng.randi() % palette.size()]
		# Random prop sizes: low boxes mostly, occasional tall one.
		var prop_h: float = rng.randf_range(0.4, 1.6)
		var prop_w: float = rng.randf_range(0.4, 1.2)
		var prop_d: float = rng.randf_range(0.4, 1.2)
		pos.y = prop_h / 2.0
		Chamber.make_prop_box(parent, Vector3(prop_w, prop_h, prop_d), pos, col)

	# A corpse if the theme rolls it.
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
		ActUtil.blood_decal(parent, bp, Vector2(rng.randf_range(0.8, 2.0), rng.randf_range(0.8, 1.6)))

	# Signal growth if the theme rolls it (lab/ice especially).
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
