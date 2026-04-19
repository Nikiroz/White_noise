extends Area2D

@export var bus_name: String = "Ambient"
@export var lowpass_effect_index: int = 0
@export var cutoff_enter: float = 20000.0
@export var tween_time: float = 0.1

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_set_lowpass_cutoff(cutoff_enter, true)

func _set_lowpass_cutoff(target_cutoff: float, b:bool) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	var fx := AudioServer.get_bus_effect(bus, lowpass_effect_index)
	if fx == null:
		return
	AudioServer.set_bus_effect_enabled(bus, 0, b)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_set_lowpass_cutoff(cutoff_enter, false)
