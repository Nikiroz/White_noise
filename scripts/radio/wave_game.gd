extends Control

@onready var target_line: Line2D = $GraphPanel/TargetLine
@onready var player_line: Line2D = $GraphPanel/PlayerLine
@onready var score_label: Label = $ScoreLabel
@onready var status_label: Label = $StatusLabel

@onready var freq_knob = %Knob
@onready var phase_knob = %Knob2
@onready var amp_knob = $Knob3

@export var width_px := 160
@export var height_px := 140
@export var samples := 120
@onready var knob_sound := get_node_or_null("%AlmostSound") as AudioStreamPlayer2D
@onready var signal_sound := get_node_or_null("%SignalPlayer") as AudioStreamPlayer2D
	
var target_freq: float
var target_phase: float
var target_amp: float

var player_freq: float = 1.0
var player_phase: float = 0.0
var player_amp: float = 1.0

@export var win_score := 0.92     
@export var hold_time := 1.5
var hold := 0.0
var won := false

var t := 2.0

func _ready() -> void:
	randomize()
	_new_target()
	var scene := get_tree().current_scene
	knob_sound = scene.get_node("Scene/Radio/AlmostSound") as AudioStreamPlayer2D
	signal_sound = scene.get_node("Scene/Radio/SignalPlayer") as AudioStreamPlayer2D
	if freq_knob.has_signal("value_changed"):
		freq_knob.value_changed.connect(_on_freq_changed)
	if phase_knob.has_signal("value_changed"):
		phase_knob.value_changed.connect(_on_phase_changed)
	if amp_knob.has_signal("value_changed"):
		amp_knob.value_changed.connect(_on_amp_changed)
		
	_on_freq_changed(int(freq_knob.value))
	_on_phase_changed(int(phase_knob.value))
	_on_amp_changed(int(amp_knob.value))
	_update_lines()
	
	
func _on_amp_changed(v: int) -> void:
	player_amp = lerp(0.3, 1.2, float(v) / 100.0)
	
func _process(delta: float) -> void:
	if won:
		return

	t += delta
	_update_lines()

	var score := _calc_score()
	_update_ui(score)
	_check_win(score, delta)

func _new_target() -> void:
	target_freq = randf_range(0.8, 5.5)
	target_phase = randf_range(0.0, TAU)
	target_amp = randf_range(0.4, 1.1)

	status_label.text = "Подстрой частоту и фазу"

func _on_freq_changed(v: int) -> void:
	player_freq = lerp(0.8, 5.5, float(v) / 100.0)

func _on_phase_changed(v: int) -> void:
	player_phase = lerp(0.0, TAU, float(v) / 100.0)

func _update_lines() -> void:
	var origin := Vector2(0, 0)
	var half_h := height_px * 0.5

	target_line.clear_points()
	player_line.clear_points()

	for i in range(samples):
		var x := float(i) / float(samples - 1)
		var px := origin.x + x * width_px

		var time_shift := t * 0.0

		var ty := sin((x * TAU * target_freq) + target_phase + time_shift) * target_amp
		var py := sin((x * TAU * player_freq) + player_phase + time_shift) * player_amp

		var y_target := origin.y + half_h - ty * half_h
		var y_player := origin.y + half_h - py * half_h

		target_line.add_point(Vector2(px, y_target))
		player_line.add_point(Vector2(px, y_player))

func _calc_score() -> float:
	var err := 0.0
	for i in range(samples):
		var x := float(i) / float(samples - 1)
		var time_shift := t * 0.0

		var ty := sin((x * TAU * target_freq) + target_phase + time_shift) * target_amp
		var py := sin((x * TAU * player_freq) + player_phase + time_shift) * player_amp

		err += abs(ty - py)

	err /= float(samples)
	var score := 1.0 - (err * 0.5)
	return clamp(score, 0.0, 1.0)

func _update_ui(score: float) -> void:
	score_label.text = "Совпадение: %d%%" % int(round(score * 100.0))

func _check_win(score: float, delta: float) -> void:
	if score >= win_score:
		if knob_sound:
			knob_sound.volume_db = move_toward(knob_sound.volume_db, 8, 300 * delta)
		hold += delta
		status_label.text = "Почти! Держи…"
	else:
		if knob_sound:
			knob_sound.volume_db = move_toward(knob_sound.volume_db, -80, 300 * delta)
		hold = max(0.0, hold - delta * 0.8)
		status_label.text = "Подстрой частоту и фазу"

	if hold >= hold_time:
		won = true
		signal_sound._play()
		status_label.text = "СОВПАЛО"
		
		
