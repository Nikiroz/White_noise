extends Button
class_name CustomRadioButton

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	GameController.play_one_shot(preload("res://sounds/radio-button-click.mp3"))
