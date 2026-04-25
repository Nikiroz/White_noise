extends Label
var time_left: float

func _process(delta: float) -> void:
	time_left = GameController.time_left
	var seconds := int(ceil(time_left))
	var minutes := seconds / 60
	var secs := seconds % 60
	if not GameController.isNuke:
		text = "%02d:%02d" % [minutes, secs]
	else:
		text = "God appears and God is light\n"