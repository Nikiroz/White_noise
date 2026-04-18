extends Area2D

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("set_current_ladder"):
		body.set_current_ladder(self)

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("clear_current_ladder"):
		body.clear_current_ladder(self)
