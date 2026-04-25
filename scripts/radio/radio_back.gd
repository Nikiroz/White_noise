extends CustomRadioButton

func _on_pressed() -> void:
	super();
	var menu := find_parent("Shadow")
	if menu:
		var terminal := menu.get_parent() # это и есть Terminal
		if terminal:
			terminal._escape()
