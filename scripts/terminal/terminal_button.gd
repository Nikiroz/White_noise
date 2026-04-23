extends Button
class_name TerminalButton

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	GameController.play_one_shot(preload("res://sounds/ui/Keyboard.mp3"))
