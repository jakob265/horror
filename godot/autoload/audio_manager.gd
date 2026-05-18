extends Node
# Procedural audio manager. Mirrors systems/audio.py.
# All sounds are generated at runtime from sine/square/noise waveforms
# baked into AudioStreamWAV resources. No external .wav files needed.

const SAMPLE_RATE := 22050

var _streams := {}              # key -> AudioStreamWAV
var _hum_player: AudioStreamPlayer
var _signal_player: AudioStreamPlayer
var _signal_harm_player: AudioStreamPlayer

# Pool of one-shot players (reused so we don't spawn nodes every SFX)
var _oneshot_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bake_all()
	_hum_player = _make_player(_streams["station_hum"], -22.0)
	_hum_player.bus = "Master"
	_hum_player.play()
	_signal_player = _make_player(_streams["signal_tone"], -80.0)
	_signal_player.play()
	_signal_harm_player = _make_player(_streams["signal_tone_harm"], -80.0)
	_signal_harm_player.play()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_oneshot_pool.append(p)


# --- Stream baking ---------------------------------------------------------

func _bake_all() -> void:
	_streams["station_hum"] = _bake_loop(_gen_sine(38.0, 4.0, 0.85))
	_streams["signal_tone"] = _bake_loop(_gen_warble(440.0, 3.0, 0.4, 6.0, 0.8))
	_streams["signal_tone_harm"] = _bake_loop(_mix(
		_gen_warble(440.0, 3.0, 0.4, 6.0, 0.55),
		_gen_warble(440.0 * pow(2.0, 2.0 / 12.0), 3.0, 0.4, 4.0, 0.55)
	))
	_streams["intercom_click"] = _bake(_apply_fade(_gen_square(800.0, 0.06, 0.4), 0.005, 0.02))
	_streams["note_chime"]     = _bake(_apply_fade(_gen_sine(880.0, 0.4, 0.55), 0.005, 0.35))
	_streams["shape_sting"]    = _bake(_apply_fade(_gen_noise(0.3, 0.65), 0.002, 0.28))
	_streams["keypad_accept"]  = _bake(_apply_fade(_gen_sine(1200.0, 0.15, 0.5), 0.005, 0.08))
	_streams["keypad_reject"]  = _bake(_apply_fade(_gen_square(220.0, 0.25, 0.45), 0.005, 0.12))
	_streams["door"]           = _bake(_apply_fade(_gen_noise(0.5, 0.25), 0.05, 0.4))
	_streams["scrape"]         = _bake(_apply_fade(_mix(_gen_noise(0.6, 0.3), _gen_sine(70.0, 0.6, 0.4)), 0.05, 0.3))
	_streams["ending_tone"]    = _bake(_apply_fade(_mix(_gen_sine(164.81, 4.0, 0.35), _gen_sine(246.94, 4.0, 0.30)), 0.8, 1.2))


# --- Public SFX ------------------------------------------------------------

func intercom_click() -> void: _one_shot("intercom_click", -8.0)
func note_chime()     -> void: _one_shot("note_chime",     -8.0)
func shape_sting()    -> void: _one_shot("shape_sting",    -4.0)
func keypad_accept()  -> void: _one_shot("keypad_accept",  -6.0)
func keypad_reject()  -> void: _one_shot("keypad_reject",  -6.0)
func door()           -> void: _one_shot("door",           -8.0)
func scrape()         -> void: _one_shot("scrape",         -6.0)
func ending_tone()    -> void: _one_shot("ending_tone",    -6.0)


func set_signal_proximity_volume(v: float) -> void:
	# v in [0, 0.08] -> dB
	v = clamp(v, 0.0, 0.08)
	_signal_player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v * 10.0)


func set_olen_harmonic_volume(v: float) -> void:
	v = clamp(v, 0.0, 0.25)
	_signal_harm_player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v * 4.0)


func ramp_ending_hum(target_linear: float, seconds: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		func(v): _hum_player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v),
		db_to_linear(_hum_player.volume_db),
		target_linear,
		seconds,
	)


func cut_hum() -> void:
	_hum_player.volume_db = -80.0
	_signal_player.volume_db = -80.0
	_signal_harm_player.volume_db = -80.0


# --- Internals -------------------------------------------------------------

func _make_player(stream: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = db
	return p


func _one_shot(key: String, db: float) -> void:
	if not _streams.has(key):
		return
	var p := _find_free_player()
	p.stream = _streams[key]
	p.volume_db = db
	p.play()


func _find_free_player() -> AudioStreamPlayer:
	for p in _oneshot_pool:
		if not p.playing:
			return p
	# Steal the oldest if everything's busy
	return _oneshot_pool[0]


func _bake(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var s := int(clamp(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s)
	stream.data = data
	return stream


func _bake_loop(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := _bake(samples)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = samples.size()
	return s


func _gen_sine(freq: float, duration: float, amp: float = 0.5) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = amp * sin(TAU * freq * i / SAMPLE_RATE)
	return out


func _gen_warble(freq: float, duration: float, lfo_hz: float, lfo_depth: float, amp: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var cur := freq + lfo_depth * sin(TAU * lfo_hz * t)
		phase += TAU * cur / SAMPLE_RATE
		out[i] = amp * sin(phase)
	return out


func _gen_square(freq: float, duration: float, amp: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var period := SAMPLE_RATE / freq
	for i in n:
		out[i] = amp if (i % int(period)) < (period / 2.0) else -amp
	return out


func _gen_noise(duration: float, amp: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = amp * (randf() * 2.0 - 1.0)
	return out


func _apply_fade(samples: PackedFloat32Array, fade_in_s: float, fade_out_s: float) -> PackedFloat32Array:
	var n := samples.size()
	var fi := int(fade_in_s * SAMPLE_RATE)
	var fo := int(fade_out_s * SAMPLE_RATE)
	for i in min(fi, n):
		samples[i] *= float(i) / fi
	for i in min(fo, n):
		samples[n - 1 - i] *= float(i) / fo
	return samples


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := max(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a[i] if i < a.size() else 0.0
		var vb := b[i] if i < b.size() else 0.0
		out[i] = clamp(va + vb, -1.0, 1.0)
	return out
