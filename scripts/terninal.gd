extends Control
class_name CustomTerminal

@onready var out: RichTextLabel = %Output
@onready var inp: Label = %Input
@onready var keys: GridContainer = %Keys
const MAX_LEN := 6

var buffer := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in keys.get_children():
		if child is BaseButton:
			var b := child as BaseButton
			b.pressed.connect(_on_key_pressed.bind(b.text))
	_refresh()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey

		# цифры с верхнего ряда и numpad
		var digit := _digit_from_keycode(key.keycode)
		if digit != "":
			if buffer.length() < MAX_LEN:
				GameController.play_one_shot(preload("res://sounds/Keyboard.mp3"))
				buffer += digit
				_refresh()
			get_viewport().set_input_as_handled()
			return

		# Backspace
		if key.keycode == KEY_BACKSPACE:
			if buffer.length() > 0:
				buffer = buffer.substr(0, buffer.length() - 1)
				_refresh()
			get_viewport().set_input_as_handled()
			return

		# Enter
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			_on_key_pressed("Enter")
			get_viewport().set_input_as_handled()
			return
		
		if key.keycode == KEY_ESCAPE:
			# что сделать на Esc:
			buffer = ""
			_refresh()
			# или закрыть терминал:
			_escape()
			return
			
func _digit_from_keycode(code: Key) -> String:
	match code:
		KEY_0, KEY_KP_0: return "0"
		KEY_1, KEY_KP_1: return "1"
		KEY_2, KEY_KP_2: return "2"
		KEY_3, KEY_KP_3: return "3"
		KEY_4, KEY_KP_4: return "4"
		KEY_5, KEY_KP_5: return "5"
		KEY_6, KEY_KP_6: return "6"
		KEY_7, KEY_KP_7: return "7"
		KEY_8, KEY_KP_8: return "8"
		KEY_9, KEY_KP_9: return "9"
		_: return ""

func _on_key_pressed(t: String) -> void:
	match t:
		"←":
			if buffer.length() > 0:
				buffer = buffer.substr(0, buffer.length() - 1)
		
		"↲":
			_entered()
		"Clear":
			buffer = ""
			out.clear()
		_:
			if buffer.length() < MAX_LEN:
				buffer += t
	
	_refresh()

func _entered()->void:
	if buffer.length() == MAX_LEN:
				out.append_text("> %s\n" % buffer)
				# тут можно “обработать команду”
				out.append_text("OK\n")
				buffer = ""

func _refresh() -> void:
	inp.text = buffer

func _escape() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set_can_move(true)
	visible = false
