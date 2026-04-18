extends Button
class_name Menu_button

@onready var ui_player: AudioStreamPlayer = %UiPlayer

func _ready() -> void:
	mouse_entered.connect(_on_hover)
	pressed.connect(_on_pressed)

func _on_hover() -> void:
	ui_player.stream = preload("res://sounds/click.wav")
	ui_player.play()

func _on_pressed() -> void:
	ui_player.stream = preload("res://sounds/click_2.wav")
	ui_player.play()
