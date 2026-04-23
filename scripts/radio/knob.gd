extends TextureButton

@export var min_value := 0
@export var max_value := 100
@export var step := 1

@export var degrees_per_step := 8.0
@export var smooth_speed := 12.0

@export var label_path: NodePath
@onready var value_label: Label = get_node_or_null(label_path) as Label
signal value_changed(v: int)

var reached_end_once := false
var dragging := false
var value := 0

var angle_deg := 0.0
var target_angle_deg := 0.0
var prev_mouse_angle_deg := 0.0

@onready var knob_sound := get_node_or_null("%KnobSound2D") as AudioStreamPlayer2D

@export var stop_delay := 0.12
@export var vol_on_db := 0.0
@export var vol_off_db := -80.0
@export var fade_in_db_per_sec := 9999.0   # почти мгновенно
@export var fade_out_db_per_sec := 240.0   # затухание

var stop_timer := 0.0
	
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pivot_offset = size * 0.5
	_update_label()
	var scene := get_tree().current_scene
	knob_sound = scene.get_node("Scene/Radio/KnobSound2D") as AudioStreamPlayer2D

	# Стартуем поток ОДИН раз. Дальше только громкость.
	if knob_sound:
		knob_sound.stream_paused = false
		knob_sound.volume_db = vol_off_db
		if not knob_sound.playing:
			knob_sound.play()  # stream должен быть LOOP


func _process(delta: float) -> void:
	var k := 1.0 - exp(-smooth_speed * delta)
	angle_deg = lerp(angle_deg, target_angle_deg, k)
	rotation = deg_to_rad(angle_deg)

	if stop_timer > 0.0:
		stop_timer -= delta

	if knob_sound:
		var target := vol_on_db if stop_timer > 0.0 else vol_off_db
		var speed := fade_in_db_per_sec if stop_timer > 0.0 else fade_out_db_per_sec
		knob_sound.volume_db = move_toward(knob_sound.volume_db, target, speed * delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			prev_mouse_angle_deg = _mouse_angle_deg(event.position)
		accept_event()
		return

	if event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		var now := _mouse_angle_deg(mm.position)

		var delta := wrapf(now - prev_mouse_angle_deg, -180.0, 180.0)
		prev_mouse_angle_deg = now

		var delta_steps := int(round(delta / degrees_per_step))
		if delta_steps != 0:
			_try_apply_steps(delta_steps)
			_on_steps_changed()

		accept_event()


func _mouse_angle_deg(local_mouse_pos: Vector2) -> float:
	var v := local_mouse_pos - pivot_offset
	return rad_to_deg(atan2(v.y, v.x))


func _try_apply_steps(delta_steps: int) -> void:
	var new_value := value + delta_steps * step

	if new_value > max_value or new_value < min_value:
		if not reached_end_once:
			GameController.play_one_shot(preload("res://sounds/ui/radio-button-click.mp3"))
			reached_end_once = true
		return

	reached_end_once = false
	value = new_value
	emit_signal("value_changed", value)
	_update_label()
	target_angle_deg += float(delta_steps) * degrees_per_step


func _update_label() -> void:
	if value_label:
		value_label.text = str(value)


func _on_steps_changed() -> void:
	stop_timer = stop_delay
