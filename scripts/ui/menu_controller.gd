extends Node

var _menuSettings: Control
var _containerSettings: Control
var _containerPause: Control
var _scene: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var scene := get_tree().current_scene
	_menuSettings = scene.get_node("UI/Control/MenuContainer") as Control
	_containerSettings = scene.get_node("UI/Control/MenuContainer/SettingsContainer") as Control
	_containerPause = scene.get_node("UI/Control/MenuContainer/PauseContainer") as Control
	_scene = scene.get_node("Scene") as Node

func _show_settings() -> void:
	_menuSettings.visible = true
	_containerPause.visible = false
	_containerSettings.visible = true

func _hide_settings() -> void:
	_menuSettings.visible = true
	_containerPause.visible = true
	_containerSettings.visible = false
	
func _show_pause() -> void:
	if GameController.isEnd:
		return
	_menuSettings.visible = true
	_containerPause.visible = true
	_containerSettings.visible = false
	get_tree().paused = true
	
func _hide_pause() -> void:
	_menuSettings.visible = false
	_containerPause.visible = false
	_containerSettings.visible = false
	get_tree().paused = false

func _hide_all() ->void:
	_hide_settings()
	_hide_pause()
		
func _set_pause(isKey = false) -> void:
	
	if isKey:
		if GameController.isMainMenu:
			if _containerSettings.visible == true:
				_hide_all()
				GameController.timer.paused = false
		else:
			if _menuSettings.visible == false:
				_show_pause()
				GameController.timer.paused = true
			else:
				if _containerSettings.visible == true:
					_hide_settings()
				else:
					_hide_all()
					GameController.timer.paused = false
	else:
		if _containerSettings.visible == true:
			if GameController.isMainMenu:
				_hide_all()
				GameController.timer.paused = false
			else:
				_hide_settings()
		else:
			_hide_all()
			GameController.timer.paused = false
			
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_pause(true)
