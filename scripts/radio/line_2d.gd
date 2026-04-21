extends Line2D

@export var from_node: Node2D
@export var to_node: Node2D

func _process(_delta: float) -> void:
	if not from_node or not to_node:
		return

	points = [
		to_local(from_node.global_position),
		to_local(to_node.global_position)
	]
