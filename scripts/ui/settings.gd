extends Panel

@export var master_slider_path: NodePath
@export var sfx_slider_path: NodePath
@export var music_slider_path: NodePath

var master_slider: HSlider
var sfx_slider: HSlider
var music_slider: HSlider

const SAVE_PATH := "user://audio_settings.cfg"

var _master_bus := -1
var _sfx_bus := -1
var _music_bus := -1
var _default_master := 1.0
var _default_sfx := 0.7
var _default_music := 0.9

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index("Master")
	_sfx_bus = AudioServer.get_bus_index("Sfx")
	_music_bus  = AudioServer.get_bus_index("Music")
	
	master_slider = get_node(master_slider_path) as HSlider
	sfx_slider = get_node(sfx_slider_path) as HSlider
	music_slider  = get_node(music_slider_path) as HSlider

	if master_slider == null or sfx_slider == null or music_slider == null:
		push_error("Slider error")
		return
	
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	
	master_slider.drag_ended.connect(func(_changed: bool): _save_settings())
	sfx_slider.drag_ended.connect(func(_changed: bool): _save_settings())
	music_slider.drag_ended.connect(func(_changed: bool): _save_settings())

	_load_settings()
	_on_master_changed(master_slider.value)
	_on_sfx_changed(sfx_slider.value)
	_on_music_changed(music_slider.value)
	
func _on_master_changed(v: float) -> void:
	_set_bus_volume_linear(_master_bus, v)
	
func _on_sfx_changed(v: float) -> void:
	_set_bus_volume_linear(_sfx_bus, v)

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
	cfg.set_value("audio", "sfx", sfx_slider.value)
	cfg.set_value("audio", "music", music_slider.value)
	cfg.save(SAVE_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		master_slider.value = float(cfg.get_value("audio", "master", 1))
		sfx_slider.value = float(cfg.get_value("audio", "sfx", 1))
		music_slider.value  = float(cfg.get_value("audio", "music", 1))
	else:
		master_slider.value = _default_master
		sfx_slider.value = _default_sfx
		music_slider.value  = _default_music
