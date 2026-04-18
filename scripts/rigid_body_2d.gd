extends RigidBody2D

@export var interval := 5.0          # раз в сколько секунд
@export var randomize_dir := true    # менять направление влево/вправо

var _timer: Timer

func _ready() -> void:
	input_pickable = true  # можно и в инспекторе
	_timer = Timer.new()
	_timer.wait_time = interval
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_kick)

func _kick() -> void:
	var dir := -500.0
	apply_impulse(Vector2(0.0, dir))

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_kick()
		_timer.start()
