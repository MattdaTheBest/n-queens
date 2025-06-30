extends Control

var selection_visible = false

var full : bool = false
var placed_queen 

var global_row_pos 
var global_col_pos 
var global_pos : Vector2

@onready var texture: TextureRect = $texture
@onready var texture_bottom: TextureRect = $texture_bottom
@onready var selection: TextureRect = $selection
@onready var pos: RichTextLabel = $texture/pos

var selection_tween : Tween

const BLACK_TILE = preload("res://sprites/black_tile.png")
const WHITE_TILE = preload("res://sprites/white_tile.png")
const SELECTION_DOT_W = preload("res://sprites/selection_dot.png")
const SELECTION_DOT_B = preload("res://sprites/selection_dot_b.png")
const BLACK_TILE_BOTTOM = preload("res://sprites/black_tile_bottom.png")
const WHITE_TILE_BOTTOM = preload("res://sprites/white_tile_bottom.png")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:

	pass

func create(index, row_index, col_index, bottom := false):
	if index % 2 == 1:
		texture.texture = BLACK_TILE
		selection.texture = SELECTION_DOT_W
		
		if bottom:
			texture_bottom.texture = BLACK_TILE_BOTTOM
		
	else:
		texture.texture = WHITE_TILE
		selection.texture = SELECTION_DOT_B
		
		if bottom:
			texture_bottom.texture = WHITE_TILE_BOTTOM
		
	descipher_pos(Vector2(row_index, col_index))

func bounce_tile():
	var tween = create_tween()
	tween.tween_property(texture, "scale", Vector2(.8, .8), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(texture, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func appear_tile():
	var tween = create_tween()
	tween.tween_property(texture, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func disappear_tile():
	var tween = create_tween()
	tween.tween_property(texture, "scale", Vector2(0, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
func descipher_pos(position):
	var x = int_to_letter(position.x)
	var y = position.y
	
	pos.text = str(x,y)
	
func int_to_letter(i: int) -> String:
	return char(97 + i)

func set_globals(row, col):
	global_col_pos = col
	global_row_pos = row

func highlight():
	selection.visible = true

func selection_dot_appear():
	if selection_visible:
		return
	selection_visible = true

	if selection_tween:
		selection_tween.kill()

	selection_tween = create_tween()
	selection_tween.tween_property(selection, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func selection_dot_disappear():
	if not selection_visible:
		return
	selection_visible = false

	if selection_tween:
		selection_tween.kill()

	selection_tween = create_tween()
	selection_tween.tween_property(selection, "scale", Vector2(0, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
