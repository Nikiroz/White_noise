extends TextureButton

func _on_pressed() -> void:
	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		texture_normal = preload("res://sprites/fullscreen_on.png")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		texture_normal = preload("res://sprites/fullscreen_off.png")
