extends Node2D

@export var digits_texture: Texture2D
@export var cell_size := Vector2i(9, 12) 

@onready var m1: Sprite2D = $M1
@onready var m2: Sprite2D = $M2
@onready var s1: Sprite2D = $S1
@onready var s2: Sprite2D = $S2

func _ready() -> void:
	for sp in [m1, m2, s1, s2]:
		sp.texture = digits_texture
		sp.region_enabled = true

func _update_timer_sprites(time_left: float) -> void:
	var seconds := int(ceil(time_left))
	seconds = max(seconds, 0)
	
	var minutes := seconds / 60
	var secs := seconds % 60

	var mm1 := minutes / 10
	var mm2 := minutes % 10
	var ss1 := secs / 10
	var ss2 := secs % 10

	_set_glyph(m1, mm1)
	_set_glyph(m2, mm2)
	_set_glyph(s1, ss1)
	_set_glyph(s2, ss2)

func _set_glyph(sp: Sprite2D, index: int) -> void:
	var x := index * cell_size.x
	sp.region_rect = Rect2(Vector2(x, 0), Vector2(cell_size))
