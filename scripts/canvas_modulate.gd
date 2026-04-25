@tool
extends CanvasModulate

# Максимальная "тьма" (0..1). 0.9 = почти чёрный, но не 0.
@export_range(0.0, 1.0, 0.01) var target_darkness := 0.9

# Длительность затухания (сек)
@export_range(0.05, 30.0, 0.05) var fade_duration := 5.0

# Дебаг вручную в инспекторе (работает в редакторе из-за @tool)
@export_range(0.0, 1.0, 0.01) var debug_darkness := 0.0:
	set(v):
		debug_darkness = clampf(v, 0.0, 1.0)
		if Engine.is_editor_hint() and not _fading:
			_set_darkness(debug_darkness)

var _fading := false
var _elapsed := 0.0
var _start_darkness := 0.0

func _ready() -> void:
	# стартовое состояние — светло
	if not Engine.is_editor_hint():
		_set_darkness(0.0)

func start_fade() -> void:
	# Запуск отдельным вызовом
	_fading = true
	_elapsed = 0.0
	_start_darkness = _get_darkness()

func stop_fade() -> void:
	_fading = false

func reset_light() -> void:
	_fading = false
	_set_darkness(0.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not _fading:
		return

	_elapsed += delta
	var t := clampf(_elapsed / maxf(fade_duration, 0.001), 0.0, 1.0)

	# Плавность (можешь убрать, если надо линейно)
	t = t * t * (3.0 - 2.0 * t) # smoothstep

	var d := lerpf(_start_darkness, target_darkness, t)
	_set_darkness(d)

	if t >= 1.0:
		_fading = false

func _set_darkness(d: float) -> void:
	# d=0 -> белый, d=1 -> чёрный
	d = clampf(d, 0.0, 1.0)
	var c := 1.0 - d
	color = Color(c, c, c, 1.0)

func _get_darkness() -> float:
	# берём текущую “тьму” из текущего цвета (серый)
	return 1.0 - color.r
