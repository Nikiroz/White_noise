extends Button
class_name Menu_button

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	pressed.connect(_on_pressed)

func _on_hover() -> void:
	GameController.play_one_shot(preload("res://sounds/click.wav"))

func _on_pressed() -> void:
	GameController.play_one_shot(preload("res://sounds/click_2.wav"))
