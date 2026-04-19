extends AudioStreamPlayer2D

@export var level := 0.35          # общая громкость
@export var click_rate := 10.0     # щелчков в секунду
@export var click_level := 0.9     # сила щелчков

@export var hp_cut := 250.0        # high-pass cutoff
@export var lp_cut := 4500.0       # low-pass cutoff

var playback: AudioStreamGeneratorPlayback

var lp_state := 0.0
var hp_state := 0.0
var hp_prev_x := 0.0

var click_env := 0.0
var click_mul := 0.0

func _ready() -> void:
	play()
	await get_tree().process_frame
	playback = get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	if playback == null:
		return

	var gen := stream as AudioStreamGenerator
	var sr: float = gen.mix_rate

	var available: int = playback.get_frames_available()
	var n: int = available
	if n > 4096:
		n = 4096

	var a_lp: float = 1.0 - exp(-TAU * lp_cut / sr)
	var alpha_hp: float = sr / (sr + TAU * hp_cut)
	var p_click: float = click_rate / sr

	for i in range(n):
		var x: float = randf_range(-1.0, 1.0)

		lp_state += a_lp * (x - lp_state)
		var lp: float = lp_state

		hp_state = alpha_hp * (hp_state + lp - hp_prev_x)
		hp_prev_x = lp
		var y: float = hp_state

		if randf() < p_click:
			click_env = 1.0
			click_mul = randf_range(0.92, 0.98)

		if click_env > 0.0001:
			var impulse: float = (-1.0 if randf() < 0.5 else 1.0) * click_level * click_env
			y += impulse
			click_env *= click_mul
		y *= level

		playback.push_frame(Vector2(y, y))
