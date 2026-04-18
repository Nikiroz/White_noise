extends Menu_button
@export var _container: Node

func _on_pressed() -> void:
	super();
	_container.visible = true
