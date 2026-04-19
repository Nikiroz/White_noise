extends CharacterBody2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var head_ray: RayCast2D = $HeadRay

const SPEED = 300.0
const CLIMB_SPEED = 100.0

@export var ONE_WAY_LAYER := 2
@export var DROP_TIME := 0.15

var in_ladder := false
var climb_mode := false

var drop_timer := 0.0
var one_way_ignored := false
var current_ladder: Area2D = null
var can_move := true

func set_can_move(v: bool) -> void:
	can_move = v
	if not can_move:
		velocity.x = 0.0

func set_current_ladder(ladder: Area2D) -> void:
	current_ladder = ladder
	in_ladder = true

func clear_current_ladder(ladder: Area2D) -> void:
	if ladder == current_ladder:
		current_ladder = null
	in_ladder = false
	climb_mode = false

func _snap_to_ladder_center() -> void:
	if current_ladder == null:
		return
	var shape := current_ladder.get_node_or_null("CollisionShape2D") as CollisionShape2D
	global_position.x = shape.global_position.x if shape else current_ladder.global_position.x

func _physics_process(delta: float) -> void:
	if not can_move:
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	var dir_x := Input.get_axis("ui_left", "ui_right")
	var dir_y := Input.get_axis("ui_up", "ui_down")

	if drop_timer > 0.0:
		drop_timer -= delta
		if drop_timer <= 0.0 and one_way_ignored:
			one_way_ignored = false
			set_collision_mask_value(ONE_WAY_LAYER, true)

	if dir_x != 0:
		velocity.x = dir_x * SPEED
		sprite.flip_h = dir_x < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	var head_in_ladder := head_ray.is_colliding()

	if in_ladder and not climb_mode and dir_y != 0 and (dir_y < 0 or dir_x == 0):
		
		if dir_y < 0 and not head_in_ladder:
			pass
		else:
			climb_mode = true
			_snap_to_ladder_center()
	
	if climb_mode and is_on_floor() and dir_y > 0 and dir_x != 0:
		climb_mode = false
	
	if climb_mode and is_on_floor() and dir_y > 0:
		climb_mode = false
		_start_drop_through()
		velocity.y = max(velocity.y, 60.0)
	
	if climb_mode:
		velocity.y = dir_y * CLIMB_SPEED
		velocity.x = 0.0
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0.0

	move_and_slide()

	if climb_mode:
		if sprite.animation != "climb":
			sprite.play("climb")
		if dir_y == 0:
			sprite.pause()
		else:
			sprite.play("climb")
	else:
		if abs(velocity.x) > 1.0:
			if sprite.animation != "walk":
				sprite.play("walk")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

func _start_drop_through() -> void:
	drop_timer = DROP_TIME
	if not one_way_ignored:
		one_way_ignored = true
		set_collision_mask_value(ONE_WAY_LAYER, false)
