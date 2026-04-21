extends Control
class_name CustomTerminal

@onready var out: RichTextLabel = %Output
@onready var inp: Label = %Input
@onready var keys: GridContainer = %Keys

# Длина кода. Лучше держать в одном месте.
# Если у тебя генерится 7-значный код — ставь 7.
const MAX_LEN := 7

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
			_on_key_pressed("↲")
			get_viewport().set_input_as_handled()
			return

		# Esc
		if key.keycode == KEY_ESCAPE:
			buffer = ""
			_refresh()
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
			# защита от кнопок не-цифр (если вдруг есть)
			if t.length() == 1 and t >= "0" and t <= "9":
				if buffer.length() < MAX_LEN:
					buffer += t

	_refresh()

func _entered() -> void:
	# ввод не полный — не проверяем
	if buffer.length() != MAX_LEN:
		return

	out.append_text("> %s\n" % buffer)

	# Сгенерированный код (строка из цифр), который ты записываешь в GameController
	var correct: String = GameController.radio_code

	if buffer == correct:
		out.append_text("God appears and God is light...\n")
		GameController.on_terminal_success()
	else:
		out.append_text("Wrong numbers\n")
		# Если хочешь подсказку (сколько позиций совпало) — раскомментируй:


	buffer = ""
	_refresh()

func _count_matches(a: String, b: String) -> int:
	var n : int = min(a.length(), b.length())
	var m := 0
	for i in range(n):
		if a[i] == b[i]:
			m += 1
	return m

func _refresh() -> void:
	inp.text = buffer

func _escape() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set_can_move(true)
	visible = false
