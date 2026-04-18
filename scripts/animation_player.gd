extends Node

@onready var anim: AnimationPlayer = %player

func _ready() -> void:
	anim.play("test")
