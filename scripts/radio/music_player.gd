extends AudioStreamPlayer2D

@export var radio_mix: float = 1.0      # 0..1 сколько радио-эффекта
@export var drive: float = 2.2          # сатурация/клиппинг
@export var bit_depth: int = 7          # 4..12 (меньше = грязнее)
@export var downsample: int = 3         # 1..10 (больше = грубее)
@export var dropout_rate: float = 0.008 # вероятность провала
@export var dropout_hold_ms: float = 18.0
@export var am_depth: float = 0.18      # амплитудная модуляция
@export var am_rate: float = 6.0
@export var hiss: float = 0.035         # шипение
@export var click_rate: float = 5.0     # щелчки/сек
@export var click_level: float = 0.55
@export var hp_cut: float = 250.0       # “радио полоса” в коде
@export var lp_cut: float = 4500.0

# --- внутреннее состояние радио ---
var _ds_counter: int = 0
var _ds_hold_l: float = 0.0
var _ds_hold_r: float = 0.0
var _drop_samples_left: int = 0
var _click_env: float = 0.0
var _click_mul: float = 0.95
var _am_phase: float = 0.0

# фильтры (простая band-pass полоса)
var _lp_l: float = 0.0
var _lp_r: float = 0.0
var _hp_l: float = 0.0
var _hp_r: float = 0.0
var _hp_prev_l: float = 0.0
var _hp_prev_r: float = 0.0

@export var wav: AudioStreamWAV            # сюда перетащи WAV в инспекторе
@export var level := 0.6                  # общая громкость

var pb: AudioStreamGeneratorPlayback

# WAV формат
var _sr := 44100
var _stereo := false
var _fmt := 0 # AudioStreamWAV.FORMAT_16_BITS / FORMAT_8_BITS / FORMAT_IMA_ADPCM
var _data: PackedByteArray
var _pos_samples := 0 # позиция в сэмплах (не в байтах)

func _play() -> void:
	play()
	await get_tree().process_frame
	pb = get_stream_playback() as AudioStreamGeneratorPlayback
	
func _ready() -> void:
	# 1) Забираем параметры WAV
	_sr = wav.mix_rate
	_stereo = wav.stereo
	_fmt = wav.format
	_data = wav.data

	# 2) Настраиваем генератор под тот же sample rate
	var gen := stream as AudioStreamGenerator
	gen.mix_rate = _sr
	gen.buffer_length = 0.5

func _process(_delta: float) -> void:
	if pb == null:
		return

	var available: int = pb.get_frames_available()
	var n := available
	if n > 4096:
		n = 4096

	for i in range(n):
		var frame := _read_frame() # Vector2(L, R) в диапазоне -1..1
		# тут можно сделать radio_process(frame.x) и radio_process(frame.y)
		var sr := float(_sr)
		var l := radio_process(frame.x, sr, true)
		var r := radio_process(frame.y, sr, false)
		pb.push_frame(Vector2(l, r) * level)

# --- чтение одного фрейма из wav.data ---
func _read_frame() -> Vector2:
	match _fmt:
		AudioStreamWAV.FORMAT_16_BITS:
			return _read_frame_16()
		AudioStreamWAV.FORMAT_8_BITS:
			return _read_frame_8()
		_:
			# IMA ADPCM: в чистом GDScript декодить можно, но это отдельно и длинно
			return Vector2.ZERO

func _read_frame_16() -> Vector2:
	# 16-bit signed little-endian
	var ch := 2 if _stereo else 1
	var bytes_per_sample := 2
	var bytes_per_frame := bytes_per_sample * ch

	var byte_index := _pos_samples * bytes_per_frame
	if byte_index + bytes_per_frame > _data.size():
		_pos_samples = 0
		byte_index = 0

	var l := _read_s16_le(byte_index) / 32768.0
	var r := l
	if _stereo:
		r = _read_s16_le(byte_index + 2) / 32768.0

	_pos_samples += 1
	return Vector2(l, r)

func _read_frame_8() -> Vector2:
	# 8-bit unsigned (0..255) -> (-1..1)
	var ch := 2 if _stereo else 1
	var bytes_per_frame := ch

	var byte_index := _pos_samples * bytes_per_frame
	if byte_index + bytes_per_frame > _data.size():
		_pos_samples = 0
		byte_index = 0

	var l := (float(_data[byte_index]) - 128.0) / 128.0
	var r := l
	if _stereo:
		r = (float(_data[byte_index + 1]) - 128.0) / 128.0

	_pos_samples += 1
	return Vector2(l, r)

func _read_s16_le(i: int) -> int:
	var lo := int(_data[i])
	var hi := int(_data[i + 1])
	var v := (hi << 8) | lo
	# sign extend
	if v >= 0x8000:
		v -= 0x10000
	return v

func _saturate(x: float, d: float) -> float:
	return tanh(x * d)

func _bitcrush(x: float, bits: int) -> float:
	var b : int = max(bits, 1)
	var levels := float(1 << b)
	return round(x * levels) / levels

func _bandpass(x: float, sr: float, is_left: bool) -> float:
	var a_lp: float = 1.0 - exp(-TAU * lp_cut / sr)
	var alpha_hp: float = sr / (sr + TAU * hp_cut)

	if is_left:
		_lp_l = _lp_l + a_lp * (x - _lp_l)
		_hp_l = alpha_hp * (_hp_l + _lp_l - _hp_prev_l)
		_hp_prev_l = _lp_l
		return _hp_l
	else:
		_lp_r = _lp_r + a_lp * (x - _lp_r)
		_hp_r = alpha_hp * (_hp_r + _lp_r - _hp_prev_r)
		_hp_prev_r = _lp_r
		return _hp_r

func radio_process(x: float, sr: float, is_left: bool) -> float:
	var dry := x

	# 1) “радио полоса” (делает сразу похоже)
	x = _bandpass(x, sr, is_left)

	# 2) сатурация
	x = _saturate(x, drive)

	# 3) downsample/hold (sample&hold)
	_ds_counter += 1
	var ds : int= max(downsample, 1)
	if _ds_counter >= ds:
		_ds_counter = 0
		if is_left:
			_ds_hold_l = x
		else:
			_ds_hold_r = x
	else:
		x = _ds_hold_l if is_left else _ds_hold_r

	# 4) биткраш
	x = _bitcrush(x, bit_depth)

	# 5) dropouts (на оба канала одинаково)
	if _drop_samples_left > 0:
		_drop_samples_left -= 1
		x *= 0.12
	elif randf() < dropout_rate:
		_drop_samples_left = int((dropout_hold_ms / 1000.0) * sr)
		x *= 0.12

	# 6) AM (лёгкая дрожь эфира)
	_am_phase += TAU * am_rate / sr
	if _am_phase > TAU:
		_am_phase -= TAU
	var am := 1.0 - am_depth + am_depth * (0.5 + 0.5 * sin(_am_phase))
	x *= am

	# 7) шипение
	x += randf_range(-1.0, 1.0) * hiss

	# 8) щелчки
	var p_click: float = click_rate / sr
	if randf() < p_click:
		_click_env = 1.0
		_click_mul = randf_range(0.90, 0.97)
	if _click_env > 0.0001:
		var impulse: float = (-1.0 if randf() < 0.5 else 1.0) * click_level * _click_env
		x += impulse
		_click_env *= _click_mul

	# 9) dry/wet
	return lerp(dry, clamp(x, -1.0, 1.0), radio_mix)
