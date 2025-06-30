extends Node2D

var solution_complete : bool = false
var assigned_solution : int = 0
@onready var label: Label = $Label

var reference_to_board

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func assign_solution(num, referenece):
	assigned_solution = num
	label.text = str(assigned_solution + 1)
	reference_to_board = referenece

func mark_solved():
	solution_complete = true
	$CheckMark.visible = true
	$Button2.disabled = false
	
	get_parent().get_parent().move_child(get_parent(), 0)
	
func _on_button_2_pressed() -> void:
	reference_to_board.show_solution(assigned_solution)

func _hide():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
