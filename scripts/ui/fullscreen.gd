extends TextureButton
func _ready() -> void:
	if not GameController.is_desktop:
		visible = false

func _on_pressed() -> void:
	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		texture_normal = preload("uid://b6d1el8ovw3tf")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		texture_normal = preload("uid://b3gl5uj1ecn2g")
