extends Control
class_name CustomRadio

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey

		if key.keycode == KEY_ESCAPE:
			_escape()
			return
			
func _escape() -> void:
	var bus := AudioServer.get_bus_index("Radio")
	AudioServer.set_bus_volume_db(bus, 0.0)
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set_can_move(true)
	visible = false
