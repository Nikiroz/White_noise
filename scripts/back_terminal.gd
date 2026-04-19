extends TerminalButton

func _on_pressed() -> void:
	super();
	var menu := find_parent("MenuContainer")
	if menu:
		var terminal := menu.get_parent() # это и есть Terminal
		if terminal:
			terminal._escape()
