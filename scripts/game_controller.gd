extends Node

var isMainMenu = true
var mainMenu: Control
var fade: TextureRect
var mat: ShaderMaterial
var music_player: AudioStreamPlayer
@onready var timerLabel: Label = %TimerLabel
var timer: Timer

var time_left := 180.0 # 3 минуты

func fade_out(duration := 0.5) -> void:
	fade.show()
	mat.set_shader_parameter("fade", 1.0)
	create_tween().tween_property(mat, "shader_parameter/fade", 0.0, duration)
	
func fade_in(duration := 0.5) -> void:
	fade.show()
	mat.set_shader_parameter("fade", 0.0)
	create_tween().tween_property(mat, "shader_parameter/fade", 1.0, duration)

func _cache_ui() -> void:
	var scene := get_tree().current_scene
	mainMenu = scene.get_node("UI/Control/MainMenuBg") as Control
	fade = scene.get_node("UI/Control/Fade") as TextureRect
	mat = fade.material as ShaderMaterial
	timerLabel = scene.get_node("UI/Control/TimerLabel") as Label
	print(timerLabel)
func play_loop(stream: AudioStream, bus := "Sfx", volume_db := 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.stream.loop = true
	add_child(p)
	p.play()
	return p

func play_one_shot(stream: AudioStream, bus := "Sfx", volume_db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	
func _init_menu() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_cache_ui()
	play_loop(preload("res://sounds/Blizzard.mp3"))
	play_loop(preload("res://sounds/Forest.mp3"))
	music_player = play_loop(preload("res://sounds/music/ambient_main_menu.mp3"),"Music")
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time_left
	add_child(timer)
	timer.timeout.connect(_on_time_up)
	_update_label()

func _ready() -> void:
	get_tree().paused = true
	_init_menu()
	

func _process(delta: float) -> void:
	if timer.is_stopped():
		return

	time_left = timer.time_left
	_update_label()

func _update_label() -> void:
	var seconds := int(ceil(time_left))
	var minutes := seconds / 60
	var secs := seconds % 60
	timerLabel.text = "%02d:%02d" % [minutes, secs]

func _on_time_up() -> void:
	timerLabel.text = "00:00"
	print("Время вышло!")


func _startGame() -> void:
	if get_tree().paused:
		get_tree().paused = false
	play_one_shot(preload("res://sounds/StartHit.mp3"))
	if music_player:
		music_player.stop()
		music_player = play_loop(preload("res://sounds/music/ambient_normal.mp3"),"Music")
	mainMenu.visible = false
	fade_out(3)
	isMainMenu = false
	timer.start()

func _returnToMainMenu() -> void:
	get_tree().paused = true
	play_one_shot(preload("res://sounds/StartHit.mp3"))
	if music_player:
		music_player.stop()
		music_player = play_loop(preload("res://sounds/music/ambient_main_menu.mp3"),"Music")
	mainMenu.visible = true
	fade_out(3)
	isMainMenu = true
	MenuController._hide_all()
