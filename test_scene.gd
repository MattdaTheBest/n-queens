extends Control

var current_board 
var current_board_size 
var stored_boards : Dictionary = {}
var current_solutions : Control
const PLAYING_BOARD = preload("res://playing_board.tscn")
const QUEEN = preload("res://scenes/queen.tscn")
@onready var board_nav: HBoxContainer = $board_nav
@onready var submit_clear: HBoxContainer = $submit_clear
@onready var queen_container: VBoxContainer = $queen_container

var button_lock : bool = false

var last_scroll := 0.0
var scroll_timer := 0.0
var scroll_step := 64 
var snap_delay := 0.2

@export var zoom_root : Node
var zoom := 2  # Your desired zoom level



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_zoom_root()
	spawn_board()
	await get_tree().create_timer(1).timeout
	current_board.show_board()
	
		# Apply zoom
	zoom_root.scale = Vector2(zoom, zoom)
	# Center on screen at start
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if current_solutions:
		if current_solutions.scroll_vertical != last_scroll:
			scroll_timer = 0
		last_scroll = current_solutions.scroll_vertical

		scroll_timer += delta
		if scroll_timer > 0.2:
			var step = 32
			var sv = current_solutions.scroll_vertical
			current_solutions.scroll_vertical = int(round(sv / step)) * step
	
	if current_board:
		board_nav.position.y = lerpf(board_nav.position.y, current_board.position.y - (board_nav.size.y + 8), .125) 
		submit_clear.position.y = lerpf(submit_clear.position.y, current_board.position.y + current_board.size.y + 16, .125)
		queen_container.position.x = lerpf(queen_container.position.x, current_board.position.x - 40, .125)
		queen_container.position.y = lerpf(queen_container.position.y, current_board.position.y + 1, .125)
		if current_solutions:
			current_solutions.position.x = lerpf(current_solutions.position.x, current_board.position.x + current_board.size.x + 6, .125)
			current_solutions.position.y = lerpf(current_solutions.position.y, current_board.position.y, .125)
			current_solutions.size.y = current_board_size * 32
			
	if Globals.dragging_queen:
		get_closest_tile()
	else:
		Globals.closest_cell = null
		
	update_selection_visuals()
	center_zoom_root()
	
func center_zoom_root():
	var viewport_size = get_viewport_rect().size
	var zoomed_size = zoom_root.size * zoom
	zoom_root.position = (viewport_size - zoomed_size) / 2

func update_block_buttons():
	$board_nav/left.disabled = button_lock
	$board_nav/right.disabled = button_lock
	$submit_clear/input.disabled = button_lock
	$submit_clear/clear.disabled = button_lock
		

func hide_solutions(sols := current_solutions, speed := 0.25):
	var index = 0
	sols.set_deferred("scroll_vertical" , 0)
	for n in sols.get_child(0).get_children():
		var tween = create_tween()
		tween.tween_property(n.get_child(0), "scale", Vector2(0, 0), speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		#if index < 10:
		#	await get_tree().create_timer(clamp(0.125 - index/10, 0, 5)).timeout
		
		index += 1
			
func show_solutions(sols := current_solutions,speed := 0.25):
	var index = 0
	sols.set_deferred("scroll_vertical" , 0)
	for n in sols.get_child(0).get_children():
		var tween = create_tween()
		tween.tween_property(n.get_child(0), "scale", Vector2(1, 1),speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		if index < 10:
			await get_tree().create_timer(0.125).timeout
		
		index += 1

func appear_queens():
	for n in queen_container.get_children():
		n.get_child(0).appear()
		await get_tree().create_timer(0.125).timeout
		
	button_lock = false
	update_block_buttons()

func hide_queens():
	for n in queen_container.get_children():
		n.get_child(0).disappear()

func update_selection_visuals():
	for cell in current_board.cell_quick_access:
		if not Globals.closest_cell == cell:
			cell.selection_dot_disappear()
		else:
			cell.selection_dot_appear()

func get_closest_tile():
	
	Globals.closest_distance = INF
	
	for cell in current_board.cell_quick_access:
	
		var rect = cell.get_global_rect()
		var center = rect.position + rect.size / 2
		var dist = get_global_mouse_position().distance_to(center)
		
		if dist <= Globals.closest_distance and dist <= 32:
			Globals.closest_distance = dist
			Globals.closest_cell = cell
			
		if dist <= Globals.closest_distance and dist >= 32:
			Globals.closest_cell = null

func spawn_queens(size := 3):
	for n in size:
		var place_holder_cell = Control.new()
		place_holder_cell.custom_minimum_size = Vector2(32,32)
		var queen = QUEEN.instantiate()
		place_holder_cell.add_child(queen)
		queen_container.add_child(place_holder_cell)

func spawn_board(size := 4):
	var board = PLAYING_BOARD.instantiate()
	add_child(board)	
	
	board.create_board(size)
	board.position -= Vector2(board.size.x/2, board.size.y/2)
	
	current_board = board
	current_board_size = size
	stored_boards[size] = current_board
	current_solutions = current_board.solution_container
	
func _on_right_pressed() -> void:
	button_lock = true
	update_block_buttons()
	
	await current_board.hide_board()
	
	await get_tree().create_timer(.25).timeout
	
	var new_size = current_board_size + 1
	current_board_size = new_size
	if stored_boards.has(new_size):
		current_board = stored_boards[new_size]
	else:
		spawn_board(new_size)
		
	current_solutions = current_board.solution_container
	
	await get_tree().create_timer(.5).timeout
	
	current_board.show_board()
	
func _on_left_pressed() -> void:
	if current_board_size > 4:		
		button_lock = true
		update_block_buttons()
		
		await current_board.hide_board()
	
		var new_size = current_board_size - 1
		current_board_size = new_size
		if stored_boards.has(new_size):
			current_board = stored_boards[new_size]
		else:
			spawn_board(new_size)
		
		current_solutions = current_board.solution_container
		
		await get_tree().create_timer(.5).timeout
		
		current_board.show_board()
	else:
		current_board.bounce()

func _on_input_pressed() -> void:
	check_solve()
	
func check_solve():
	var solution : Array = []
	for queens in queen_container.get_children():
		var queen = queens.get_child(0)
		if queen.placed or queen.dragging:
			var cell = queen.targeted_cell
			
			#queen.check_collisions()
			
			solution.append(Vector2(cell.global_row_pos,cell.global_col_pos))
	
	solution.sort()
	if current_board.solutions.find(solution) != -1:
		var index = current_board.solutions.find(solution)
	
		current_board.sol_tab_quick_access[index].get_child(0).mark_solved()

func _on_clear_pressed() -> void:
	for queen in queen_container.get_children():
		var q = queen.get_child(0)
		
		q.reset_queen()
