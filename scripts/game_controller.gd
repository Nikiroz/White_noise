extends Node

var isMainMenu = true
var mainMenu: Control
var endingScene: Control
var fade: TextureRect
var mat: ShaderMaterial
var music_player: AudioStreamPlayer
var ambient_player1: AudioStreamPlayer
var ambient_player2: AudioStreamPlayer
var panic_player: AudioStreamPlayer
var timer: Timer
var timer_digits: Node2D
var time_total: float = 180.0
var time_left: float = time_total
var code = 0
var isBlockInteraction = false
var isEnd = false
var isStartPanic := false
var radio_code: String = ""
var idx := AudioServer.get_bus_index("Ambient");
var global_light : CanvasModulate
var isNuke = false

func set_radio_code(code: String) -> void:
	radio_code = code
	print("GameController radio_code =", radio_code)

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
	endingScene = scene.get_node("UI/EndingScene") as Control
	fade = scene.get_node("UI/Control/Fade") as TextureRect
	mat = fade.material as ShaderMaterial
	timer_digits = scene.get_node("Scene/TimerDigits") as Node2D
	global_light = scene.get_node("Scene/globalLight") as CanvasModulate
	
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

func play_one_shot(stream: AudioStream, bus := "Sfx", volume_db := 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p

func play_one_shot_cb(stream: AudioStream, on_done: Callable, bus := "Sfx", volume_db := 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)

	# 1) твой коллбек
	if on_done.is_valid():
		p.finished.connect(on_done)

	# 2) освобождение
	p.finished.connect(p.queue_free)

	p.play()
	return p	

func _init_menu() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_cache_ui()
	ambient_player1 = play_loop(preload("res://sounds/Blizzard.mp3"),"Ambient")
	ambient_player2 = play_loop(preload("res://sounds/Forest.mp3"),"Ambient")
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

func _on_sequence_generated(seq: Array[int]) -> void:
	print("Новый ряд:", seq)
	
func _process(delta: float) -> void:
	if timer.is_stopped():
		return

	time_left = timer.time_left
	_update_label()
	
	var ratio: float = clampf(time_left / time_total, 0.0, 1.0)
	if not isStartPanic and ratio <= 0.1:
		_start_panic()
		
func _update_label() -> void:
	if timer_digits == null:
		timer_digits = get_tree().get_first_node_in_group("timer_digits") as Node2D
	timer_digits._update_timer_sprites(time_left)

func _on_time_up() -> void:
	time_left = 0
	timer.stop()
	timer.wait_time = 0.1
	_update_label()
	isBlockInteraction = true;
	if not isNuke:
		for n in get_tree().current_scene.find_children("*", "CustomTerminal", true, false):
					if n:
						n._escape()
		var p := get_tree().get_first_node_in_group("player")
	
		if p:
			p.set_can_move(true)
	for n in get_tree().current_scene.find_children("*", "CustomRadio", true, false):
		if n:
			n._escape()
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

func on_terminal_success() -> void:
	if panic_player:
		panic_player.stop()
		if idx != -1:
			var db := AudioServer.get_bus_volume_db(idx)
			AudioServer.set_bus_volume_db(idx, db + 6.0206)
	_start_nuke()
	
func end() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set_can_move(false)
	print("Bad end")

func _start_panic() -> void:
	isEnd=true
	
	global_light.start_fade()
	if idx != -1:
		var db := AudioServer.get_bus_volume_db(idx)
		AudioServer.set_bus_volume_db(idx, db - 6.0206)
	isStartPanic = true
	panic_player = play_one_shot_cb(
		preload("res://sounds/eng/panic.mp3"),
		func():
			music_player.stop()
			ambient_player1.stop()
			ambient_player2.stop()
			fade_in(0.01)
			play_one_shot(preload("res://sounds/suicide_gun_shot.mp3"))
			end()
	)
func _start_nuke()->void:
	isEnd=true
	isNuke = true
	_on_time_up()
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set_can_move(false)
	print("Good end")
	var scene := get_tree().current_scene
	fade = scene.get_node("UI/Control/FadeWhite") as TextureRect
	fade_in(13)
	ambient_player2.stop()
	play_one_shot_cb(
		preload("res://sounds/nuke.mp3"),
		func():
			for n in get_tree().current_scene.find_children("*", "CustomTerminal", true, false):
				if n:
					n._escape()
			endingScene.show()
			fade_out(5)
	)
	
