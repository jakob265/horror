"""
systems/visuals.py
------------------
Visual-fidelity upgrades for VOID FREQUENCY.

Provides:
    * Procedural texture generation (metal panels, concrete, grating,
      starfield, paper, screen scanlines) using PIL.  Textures live in the
      Ursina temp folder so the Audio asset-folder trick works for them too.
    * A starfield sky entity (huge inverted sphere).
    * Per-scene fog configuration (Panda3D fog).
    * A post-FX shader (vignette + scanlines + chromatic aberration + grain).
    * Helper to apply lit shaders + per-scene light rigs.

Everything is procedural - no external image files are required.

IMPORTANT - color normalization:
  Ursina's `color.rgb(R, G, B)` returns a Color where each component is
  taken as-is (not divided by 255). Panda3D's setColorScale treats values
  greater than 1 as saturating to white, so calling color.rgb(50, 60, 70)
  yields a white surface, not dim grey. We monkey-patch the color factory
  functions below to auto-normalize when any component is > 1, which keeps
  every existing call site working with 0-255 values.
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter
from ursina import (
    AmbientLight, DirectionalLight, Entity, PointLight, Shader, Texture,
    Vec3, application, color,
)
from ursina.shaders import (
    lit_with_shadows_shader, colored_lights_shader,
)

# Re-use the temp dir from audio (set by AudioManager bootstrap)
from systems.audio import _tmp_dir


# ----------------------------------------------------------------------------
# Color normalization patch
# ----------------------------------------------------------------------------

_orig_rgb = color.rgb
_orig_rgba = color.rgba


def _maybe_normalize(*vals):
    """If any value > 1, normalize RGB to 0-1.

    The scene files were authored assuming raw 0-255 inputs would display
    *as* those grey values. With unlit rendering and no implicit gamma,
    dividing by 255 produces materials that are perceptually too dark, so
    we divide by 200 to lift mid-tones - clamped to 1.0 to keep brights
    from saturating.
    """
    if any(v > 1.0 for v in vals[:3]):
        denom = 130.0
        if len(vals) == 4:
            a = vals[3]
            if a > 1.0:
                a = a / 255.0
            return (min(1.0, vals[0] / denom),
                    min(1.0, vals[1] / denom),
                    min(1.0, vals[2] / denom),
                    a)
        return tuple(min(1.0, v / denom) for v in vals)
    return vals


def _patched_rgb(r, g, b, a=1.0):
    """Patched color.rgb that auto-normalizes 0-255 inputs to 0-1."""
    nv = _maybe_normalize(r, g, b, a)
    if len(nv) == 3:
        return _orig_rgb(nv[0], nv[1], nv[2])
    return _orig_rgba(*nv)


def _patched_rgba(r, g, b, a=1.0):
    """Patched color.rgba that auto-normalizes 0-255 inputs to 0-1."""
    nv = _maybe_normalize(r, g, b, a)
    return _orig_rgba(*nv)


def install_color_patch():
    """Install the color normalization patch (idempotent)."""
    color.rgb = _patched_rgb
    color.rgba = _patched_rgba


# Install immediately on import - other modules call color.rgb at import time
# (scene modules do).  Importing this module first establishes the patch.
install_color_patch()


# ----------------------------------------------------------------------------
# Procedural texture generation
# ----------------------------------------------------------------------------

_TEX_CACHE = {}


def _save_png(name, img):
    """Save a PIL Image to the audio temp dir, return path + filename."""
    path = os.path.join(_tmp_dir(), name + ".png")
    img.save(path)
    return name, path


def _noise(w, h, base, variance, seed):
    """Per-pixel grayscale noise."""
    rng = random.Random(seed)
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            v = max(0, min(255, base + rng.randint(-variance, variance)))
            px[x, y] = (v, v, v)
    return img


def make_metal_panel(seed=1):
    """Brushed-metal panel with seams + rivets."""
    if "metal_panel" in _TEX_CACHE:
        return _TEX_CACHE["metal_panel"]
    size = 256
    img = _noise(size, size, base=72, variance=14, seed=seed)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    draw = ImageDraw.Draw(img)
    # Horizontal brushed streaks
    rng = random.Random(seed + 1)
    for _ in range(400):
        y = rng.randint(0, size - 1)
        v = rng.randint(-12, 12)
        for x in range(size):
            r, g, b = img.getpixel((x, y))
            img.putpixel((x, y), (max(0, min(255, r + v)),
                                  max(0, min(255, g + v)),
                                  max(0, min(255, b + v))))
    # Panel seam every 128px
    for x in (0, 128):
        draw.line([(x, 0), (x, size - 1)], fill=(30, 30, 35), width=2)
    for y in (0, 128):
        draw.line([(0, y), (size - 1, y)], fill=(30, 30, 35), width=2)
    # Rivets
    for cx, cy in [(16, 16), (16, 112), (112, 16), (112, 112),
                   (144, 16), (144, 112), (240, 16), (240, 112),
                   (16, 144), (16, 240), (112, 144), (112, 240),
                   (144, 144), (144, 240), (240, 144), (240, 240)]:
        draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3),
                     fill=(40, 42, 48), outline=(90, 92, 100))
    name, _ = _save_png("metal_panel", img)
    _TEX_CACHE["metal_panel"] = name
    return name


def make_concrete(seed=2):
    """Rough concrete floor / wall texture."""
    if "concrete" in _TEX_CACHE:
        return _TEX_CACHE["concrete"]
    size = 256
    img = _noise(size, size, base=85, variance=22, seed=seed)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    # Stains
    draw = ImageDraw.Draw(img)
    rng = random.Random(seed + 7)
    for _ in range(40):
        x = rng.randint(0, size - 1)
        y = rng.randint(0, size - 1)
        r = rng.randint(8, 28)
        a = rng.randint(-25, -8)
        for dy in range(-r, r):
            for dx in range(-r, r):
                if 0 <= x + dx < size and 0 <= y + dy < size:
                    d = math.hypot(dx, dy)
                    if d < r:
                        fade = 1 - d / r
                        cr, cg, cb = img.getpixel((x + dx, y + dy))
                        delta = int(a * fade)
                        img.putpixel((x + dx, y + dy),
                                     (max(0, cr + delta),
                                      max(0, cg + delta),
                                      max(0, cb + delta)))
    name, _ = _save_png("concrete", img)
    _TEX_CACHE["concrete"] = name
    return name


def make_grating(seed=3):
    """Industrial floor-grating texture - dark with regular slots."""
    if "grating" in _TEX_CACHE:
        return _TEX_CACHE["grating"]
    size = 256
    img = _noise(size, size, base=55, variance=8, seed=seed)
    draw = ImageDraw.Draw(img)
    # Cross-hatch slots
    for x in range(0, size, 16):
        draw.rectangle((x, 0, x + 3, size), fill=(20, 22, 26))
    for y in range(0, size, 32):
        draw.rectangle((0, y, size, y + 2), fill=(35, 38, 42))
    name, _ = _save_png("grating", img)
    _TEX_CACHE["grating"] = name
    return name


def make_starfield(seed=42):
    """Black sky with thousands of small stars - mapped onto a sky sphere."""
    if "starfield" in _TEX_CACHE:
        return _TEX_CACHE["starfield"]
    w, h = 1024, 512
    img = Image.new("RGB", (w, h), (3, 3, 6))
    rng = random.Random(seed)
    px = img.load()
    # ~3000 stars
    for _ in range(3000):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        b = rng.randint(60, 255)
        # warm or cool tint
        t = rng.random()
        if t < 0.6:
            px[x, y] = (b, b, b)
        elif t < 0.8:
            px[x, y] = (b, int(b * 0.95), int(b * 0.85))
        else:
            px[x, y] = (int(b * 0.85), int(b * 0.92), b)
        # Occasional brighter glow
        if rng.random() < 0.04:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    cb = int(b * 0.45)
                    cr, cg, _cb = px[nx, ny]
                    px[nx, ny] = (min(255, cr + cb), min(255, cg + cb),
                                  min(255, _cb + cb))
    # Wide dust band (galactic plane)
    draw = ImageDraw.Draw(img)
    cy = h // 2
    for x in range(w):
        band = 22 * math.exp(-((x / w * 6.0) - 3.0) ** 2 * 0.4)
        for dy in range(-int(band), int(band) + 1):
            y = cy + dy
            if 0 <= y < h:
                fade = max(0.0, 1.0 - abs(dy) / max(1, band))
                cr, cg, cb = px[x, y]
                px[x, y] = (min(255, cr + int(12 * fade)),
                            min(255, cg + int(10 * fade)),
                            min(255, cb + int(20 * fade)))
    name, _ = _save_png("starfield", img)
    _TEX_CACHE["starfield"] = name
    return name


def make_emergency_stripe(seed=11):
    """Yellow / black hazard stripe texture - used for door frames + crates."""
    if "stripe" in _TEX_CACHE:
        return _TEX_CACHE["stripe"]
    size = 128
    img = Image.new("RGB", (size, size), (40, 35, 10))
    draw = ImageDraw.Draw(img)
    for i in range(-size, size, 24):
        draw.polygon([(i, 0), (i + 12, 0), (i + 12 + size, size),
                      (i + size, size)],
                     fill=(220, 180, 30))
    name, _ = _save_png("stripe", img)
    _TEX_CACHE["stripe"] = name
    return name


def make_screen(seed=20):
    """Generic CRT scanline screen texture."""
    if "screen" in _TEX_CACHE:
        return _TEX_CACHE["screen"]
    w, h = 256, 256
    img = Image.new("RGB", (w, h), (5, 12, 18))
    px = img.load()
    for y in range(h):
        v = 10 + 6 * ((y % 2))
        for x in range(w):
            cr, cg, cb = px[x, y]
            px[x, y] = (cr, min(255, cg + v // 2),
                        min(255, cb + v))
    name, _ = _save_png("screen", img)
    _TEX_CACHE["screen"] = name
    return name


def bake_all_textures():
    """Pre-generate every texture used by the game.

    Also extends Ursina's texture_importer.folders to include our temp dir
    so `texture='metal_panel'` resolves at runtime.
    """
    # Make sure tmp dir exists and is registered with Ursina's texture loader
    import pathlib
    tmp = pathlib.Path(_tmp_dir())
    try:
        from ursina import texture_importer
        if tmp not in texture_importer.folders:
            texture_importer.folders.insert(0, tmp)
    except Exception:
        pass
    make_metal_panel()
    make_concrete()
    make_grating()
    make_starfield()
    make_emergency_stripe()
    make_screen()


# ----------------------------------------------------------------------------
# Camera post-FX shader (vignette + scanlines + grain + chromatic aberration)
# Follows Ursina's screenspace shader convention: fragment-only, with `tex`
# being the rendered framebuffer.
# ----------------------------------------------------------------------------

POSTFX_FRAG = """
#version 430
uniform sampler2D tex;
uniform float u_time;
uniform float u_vignette;
uniform float u_desat;
uniform float u_scanline;
uniform float u_grain;
uniform float u_ca;
in vec2 uv;
out vec4 color;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
    vec2 c = uv - 0.5;
    // Chromatic aberration: sample R and B with slight radial offset
    float r = texture(tex, uv - c * u_ca).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv + c * u_ca).b;
    vec3 col = vec3(r, g, b);

    // Desaturation
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(gray), u_desat);

    // Scanlines (every other line darkened)
    float scan = 0.5 + 0.5 * sin(uv.y * 800.0);
    col *= 1.0 - (u_scanline * (1.0 - scan));

    // Vignette
    float vdist = length(c) * 1.42;
    float vfade = smoothstep(0.4, 1.05, vdist);
    col *= 1.0 - u_vignette * vfade;

    // Film grain
    float n = (rand(uv * 1.0 + u_time) - 0.5) * u_grain;
    col += n;

    color = vec4(col, 1.0);
}
"""

POSTFX_SHADER = Shader(language=Shader.GLSL,
                      fragment=POSTFX_FRAG,
                      default_input={
                          "u_time": 0.0,
                          "u_vignette": 0.55,
                          "u_desat": 0.18,
                          "u_scanline": 0.10,
                          "u_grain": 0.06,
                          "u_ca": 0.0025,
                      })


# ----------------------------------------------------------------------------
# Starfield sky
# ----------------------------------------------------------------------------

def make_sky():
    """Build the sky entity (large inverted sphere with the starfield texture).

    The sphere is double-sided by inverting normals via negative scale.x.
    Sky doesn't need to be lit, so it uses no shader.
    """
    sky = Entity(
        model="sphere",
        texture=make_starfield(),
        scale=(-380, 380, 380),    # negative-X flips the normals inward
        double_sided=True,
        unlit=True,
    )
    sky.set_shader_input("dummy", 0)
    return sky


# ----------------------------------------------------------------------------
# Per-scene light rig
# ----------------------------------------------------------------------------

class LightRig:
    """Container for the lights + fog of a scene.  destroy() to clean up."""

    def __init__(self):
        """Empty rig."""
        self.entities = []

    def add(self, e):
        """Track an entity for later cleanup."""
        self.entities.append(e)
        return e

    def destroy(self):
        """Tear down every light + fog handle."""
        from ursina import destroy as _d
        for e in self.entities:
            try:
                _d(e)
            except Exception:
                pass
        self.entities = []
        # Clear fog from the global scene
        try:
            from direct.showbase.ShowBaseGlobal import render
            render.clearFog()
        except Exception:
            pass


def apply_fog(color_rgb=(0.04, 0.04, 0.06), density=0.05):
    """Apply linear/exponential fog to the global scene."""
    try:
        from panda3d.core import Fog
        from direct.showbase.ShowBaseGlobal import render
        fog = Fog("scene_fog")
        fog.set_color(*color_rgb)
        fog.set_exp_density(density)
        render.set_fog(fog)
    except Exception:
        pass


def _norm(r, g, b, a=255):
    """Convert 0-255 RGBA to normalized 0-1 Color tuple for Panda3D lights."""
    return color.rgba32(r, g, b, a)


def _bright_ambient(rig, r, g, b):
    """Add a normalized AmbientLight and return it (auto-tracked)."""
    a = AmbientLight(color=_norm(r, g, b))
    rig.add(a)
    return a


def make_act1_lights():
    """Cryo bay - red-tinted ambient + thin red fog."""
    rig = LightRig()
    _bright_ambient(rig, 220, 110, 110)
    apply_fog((0.18, 0.05, 0.06), density=0.020)
    return rig


def make_act2_lights():
    """Corridor / cabins - cool blue-grey ambient + thin fog."""
    rig = LightRig()
    _bright_ambient(rig, 180, 200, 220)
    apply_fog((0.16, 0.18, 0.22), density=0.018)
    return rig


def make_act3_lights():
    """Research deck - cold blue-white ambient."""
    rig = LightRig()
    _bright_ambient(rig, 180, 210, 240)
    apply_fog((0.14, 0.18, 0.24), density=0.015)
    return rig


def make_act4_lights():
    """Array room - dim warm-white ambient, deep dark-blue fog."""
    rig = LightRig()
    _bright_ambient(rig, 110, 100, 110)
    apply_fog((0.04, 0.05, 0.07), density=0.025)
    return rig


# ----------------------------------------------------------------------------
# Shader helpers
# ----------------------------------------------------------------------------

def lit_shader():
    """Return the lit-with-shadows shader (resolved at import time)."""
    return lit_with_shadows_shader


def apply_lit(entity):
    """Apply the lit shader and a default specular to an Entity if possible."""
    try:
        entity.shader = lit_with_shadows_shader
    except Exception:
        pass
    return entity
