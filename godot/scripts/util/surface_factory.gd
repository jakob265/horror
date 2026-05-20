class_name SurfaceFactory
extends RefCounted
# PBR material factory. Caches one StandardMaterial3D per (category, tint).
# Normal + roughness maps are procedural NoiseTexture2D, shared per category.
# No external assets required.

const CAT_AUTO := "auto"
const CAT_WALL_METAL := "wall_metal"
const CAT_WALL_PANEL := "wall_panel"
const CAT_WALL_CONCRETE := "wall_concrete"
const CAT_FLOOR_METAL := "floor_metal"
const CAT_FLOOR_GRATE := "floor_grate"
const CAT_FLOOR_TILE := "floor_tile"
const CAT_CEILING_PANEL := "ceiling_panel"
const CAT_PLASTIC := "plastic"
const CAT_RUBBER := "rubber"
const CAT_PAPER := "paper"
const CAT_FABRIC := "fabric"
const CAT_WOOD := "wood"
const CAT_GLASS := "glass"
const CAT_EMISSIVE := "emissive"
const CAT_PROP := "prop"

static var _tex_cache: Dictionary = {}
static var _mat_cache: Dictionary = {}


static func get_material(category: String, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := category + ":" + _color_key(tint)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := _build(category, tint)
	_mat_cache[key] = m
	return m


# Heuristic: pick a category from a hint name + tint when caller didn't specify.
static func infer_category(name_hint: String, tint: Color) -> String:
	var n := name_hint.to_lower()
	if n.begins_with("floor"):
		return CAT_FLOOR_METAL if _is_metal_tint(tint) else CAT_FLOOR_TILE
	if n.begins_with("ceiling"):
		return CAT_CEILING_PANEL
	if n.begins_with("wall") or n.begins_with("header"):
		return CAT_WALL_PANEL if _is_metal_tint(tint) else CAT_WALL_CONCRETE
	if n.begins_with("door"):
		return CAT_WALL_METAL
	return CAT_PROP


static func _is_metal_tint(c: Color) -> bool:
	# Saturated colors aren't metal; near-grey at any value is metal-ish.
	var avg: float = (c.r + c.g + c.b) / 3.0
	var spread: float = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b))
	return spread < 0.12 and avg < 0.7


static func _color_key(c: Color) -> String:
	# Quantize to 4 digits so near-duplicates share a material.
	return "%.3f_%.3f_%.3f_%.3f" % [c.r, c.g, c.b, c.a]


# ---------- material builders ----------

static func _build(cat: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.metallic_specular = 0.5

	match cat:
		CAT_WALL_METAL:
			m.metallic = 0.85
			m.roughness = 0.42
			_apply_normal(m, "metal_fine", 0.55, 1.8)
			_apply_roughness(m, "metal_fine", 0.18, 0.30, 0.62)
			m.uv1_scale = Vector3(2.5, 2.5, 2.5)
		CAT_WALL_PANEL:
			m.metallic = 0.55
			m.roughness = 0.55
			_apply_normal(m, "panel_seams", 0.7, 0.95)
			_apply_roughness(m, "metal_fine", 0.10, 0.42, 0.65)
			_apply_ao(m, "panel_seams", 0.7)
			m.uv1_scale = Vector3(1.5, 1.5, 1.5)
		CAT_WALL_CONCRETE:
			m.metallic = 0.0
			m.roughness = 0.86
			_apply_normal(m, "concrete", 1.1, 0.85)
			_apply_roughness(m, "concrete", 0.20, 0.72, 0.95)
			_apply_ao(m, "concrete", 0.5)
			m.uv1_scale = Vector3(1.2, 1.2, 1.2)
		CAT_FLOOR_METAL:
			m.metallic = 0.78
			m.roughness = 0.48
			_apply_normal(m, "panel_seams", 0.55, 0.7)
			_apply_roughness(m, "metal_fine", 0.16, 0.35, 0.65)
			_apply_ao(m, "panel_seams", 0.55)
			m.uv1_scale = Vector3(2.0, 2.0, 2.0)
		CAT_FLOOR_GRATE:
			m.metallic = 0.9
			m.roughness = 0.38
			_apply_normal(m, "grate", 1.8, 0.35)
			_apply_ao(m, "grate", 1.2)
			m.uv1_scale = Vector3(3.0, 3.0, 3.0)
		CAT_FLOOR_TILE:
			m.metallic = 0.05
			m.roughness = 0.62
			_apply_normal(m, "concrete", 0.45, 0.65)
			_apply_roughness(m, "concrete", 0.12, 0.55, 0.78)
			m.uv1_scale = Vector3(1.8, 1.8, 1.8)
		CAT_CEILING_PANEL:
			m.metallic = 0.35
			m.roughness = 0.7
			_apply_normal(m, "panel_seams", 0.55, 1.1)
			_apply_roughness(m, "metal_fine", 0.12, 0.6, 0.8)
			_apply_ao(m, "panel_seams", 0.4)
			m.uv1_scale = Vector3(1.4, 1.4, 1.4)
		CAT_PLASTIC:
			m.metallic = 0.0
			m.roughness = 0.45
			_apply_normal(m, "fine", 0.22, 4.0)
			_apply_roughness(m, "fine", 0.06, 0.38, 0.55)
		CAT_RUBBER:
			m.metallic = 0.0
			m.roughness = 0.92
			_apply_normal(m, "fine", 0.5, 2.5)
		CAT_PAPER:
			m.metallic = 0.0
			m.roughness = 0.88
			_apply_normal(m, "fine", 0.18, 6.0)
			_apply_roughness(m, "fine", 0.12, 0.82, 0.96)
		CAT_FABRIC:
			m.metallic = 0.0
			m.roughness = 0.94
			_apply_normal(m, "fabric", 0.6, 1.6)
		CAT_WOOD:
			m.metallic = 0.0
			m.roughness = 0.72
			_apply_normal(m, "wood", 0.55, 0.7)
			_apply_roughness(m, "wood", 0.16, 0.6, 0.85)
			m.uv1_scale = Vector3(1.2, 1.2, 1.2)
		CAT_GLASS:
			m.metallic = 0.0
			m.roughness = 0.04
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var a := tint
			a.a = min(0.35, a.a)
			m.albedo_color = a
			m.refraction_enabled = false
			m.rim_enabled = true
			m.rim = 0.4
		CAT_EMISSIVE:
			m.metallic = 0.0
			m.roughness = 0.4
			m.emission_enabled = true
			m.emission = tint
			m.emission_energy_multiplier = 2.5
		CAT_PROP, _:
			m.metallic = 0.12
			m.roughness = 0.62
			_apply_normal(m, "fine", 0.35, 3.5)
			_apply_roughness(m, "fine", 0.08, 0.5, 0.72)

	return m


# ---------- procedural texture helpers ----------

static func _apply_normal(m: StandardMaterial3D, key: String, strength: float, period: float) -> void:
	m.normal_enabled = true
	m.normal_scale = strength
	m.normal_texture = _normal_tex(key, period)


static func _apply_roughness(m: StandardMaterial3D, key: String, amplitude: float, low: float, high: float) -> void:
	# Texture modulates the .roughness scalar (1.0 base) — we re-bias via roughness scalar.
	m.roughness_texture = _value_tex(key + "_rough", amplitude)
	m.roughness = (low + high) * 0.5
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE


static func _apply_ao(m: StandardMaterial3D, key: String, strength: float) -> void:
	m.ao_enabled = true
	m.ao_light_affect = clamp(strength, 0.0, 1.0)
	m.ao_texture = _ao_tex(key)


static func _normal_tex(key: String, period: float) -> Texture2D:
	var cache_key := "normal:" + key + ":%.3f" % period
	if _tex_cache.has(cache_key):
		return _tex_cache[cache_key]
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.seamless_blend_skirt = 0.2
	t.as_normal_map = true
	t.bump_strength = 16.0
	t.noise = _noise_for(key, period)
	_tex_cache[cache_key] = t
	return t


static func _value_tex(key: String, amplitude: float) -> Texture2D:
	var cache_key := "value:" + key + ":%.3f" % amplitude
	if _tex_cache.has(cache_key):
		return _tex_cache[cache_key]
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.seamless_blend_skirt = 0.2
	t.noise = _noise_for(key, 2.0)
	t.normalize = true
	_tex_cache[cache_key] = t
	return t


static func _ao_tex(key: String) -> Texture2D:
	var cache_key := "ao:" + key
	if _tex_cache.has(cache_key):
		return _tex_cache[cache_key]
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.seamless_blend_skirt = 0.2
	t.noise = _noise_for(key + "_ao", 1.2)
	t.normalize = true
	_tex_cache[cache_key] = t
	return t


static func _noise_for(key: String, period: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = hash(key) & 0x7fffffff
	n.frequency = max(0.001, 1.0 / max(0.5, period))
	if key.begins_with("metal_fine") or key.begins_with("fine"):
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_octaves = 4
		n.fractal_gain = 0.55
	elif key.begins_with("panel_seams"):
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
		n.cellular_jitter = 0.0
		n.fractal_octaves = 1
	elif key.begins_with("grate"):
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.cellular_distance_function = FastNoiseLite.DISTANCE_MANHATTAN
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_DIV
		n.cellular_jitter = 0.0
		n.fractal_octaves = 1
	elif key.begins_with("concrete"):
		n.noise_type = FastNoiseLite.TYPE_PERLIN
		n.fractal_octaves = 5
		n.fractal_lacunarity = 2.4
		n.fractal_gain = 0.6
	elif key.begins_with("wood"):
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.fractal_octaves = 4
		n.fractal_lacunarity = 2.0
		n.fractal_gain = 0.65
		n.frequency *= 0.3
	elif key.begins_with("fabric"):
		n.noise_type = FastNoiseLite.TYPE_VALUE
		n.fractal_octaves = 2
	else:
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.fractal_octaves = 3
	return n
