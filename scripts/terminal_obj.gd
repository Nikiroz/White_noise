extends Area2D

@onready var terminal_sprite: Sprite2D = $TerminalSprite
@onready var mat: ShaderMaterial = terminal_sprite.material as ShaderMaterial
var terminal: Control
var player_inside := false

func _ready() -> void:
	if mat == null:
		push_warning("TerminalSprite has no ShaderMaterial!")
	

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	if mat:
		mat.set_shader_parameter("enabled", true)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	if mat:
		mat.set_shader_parameter("enabled", false)

func find_terminal() -> CustomTerminal:
	for n in get_tree().current_scene.find_children("*", "CustomTerminal", true, false):
		return n as CustomTerminal
	return null

func _process(_delta: float) -> void:
	if not player_inside:
		return

	if Input.is_action_just_pressed("interact"):
		var terminal := find_terminal()
		var p := get_tree().get_first_node_in_group("player")
		if p:
			p.set_can_move(false)
		if terminal:
			terminal.visible = true
