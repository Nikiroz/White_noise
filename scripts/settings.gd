extends Panel

@export var master_slider_path: NodePath
@export var music_slider_path: NodePath

var master_slider: HSlider
var music_slider: HSlider

const SAVE_PATH := "user://audio_settings.cfg"

var _master_bus := -1
var _music_bus := -1

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index("Master")
	_music_bus  = AudioServer.get_bus_index("Music")

	# "ручная" инициализация
	master_slider = get_node(master_slider_path) as HSlider
	music_slider  = get_node(music_slider_path) as HSlider

	# защита от null
	if master_slider == null or music_slider == null:
		push_error("Слайдеры не назначены: проверь master_slider_path / music_slider_path в Inspector.")
		return

	# подключаем сигналы один раз
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)

	master_slider.drag_ended.connect(func(_changed: bool): _save_settings())
	music_slider.drag_ended.connect(func(_changed: bool): _save_settings())

	_load_settings()
	_on_master_changed(master_slider.value)
	_on_music_changed(music_slider.value)

func _on_master_changed(v: float) -> void:
	_set_bus_volume_linear(_master_bus, v)

func _on_music_changed(v: float) -> void:
	_set_bus_volume_linear(_music_bus, v)

func _set_bus_volume_linear(bus_index: int, linear: float) -> void:
	if bus_index == -1:
		return

	if linear <= 0.0001:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear))

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_slider.value)
	cfg.set_value("audio", "music", music_slider.value)
	cfg.save(SAVE_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		master_slider.value = float(cfg.get_value("audio", "master", 1.0))
		music_slider.value  = float(cfg.get_value("audio", "music", 1.0))
	else:
		master_slider.value = 1.0
		music_slider.value  = 1.0
