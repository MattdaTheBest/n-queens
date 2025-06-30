extends Control

var queens_offboard : int = 0
var starting_queens : int = 8

var cell_positions : Dictionary = {}
var cell_quick_access : Array = []
var cell_quick_access_BYCOORD : Dictionary = {}
var sol_tab_quick_access : Array = []

#var rows_in_use : Array = []
#var cols_in_use : Array = []
#var diag1_in_use: Array = []
#var diag2_in_use: Array = []

var queens : Array= []


const ROW = preload("res://scenes/row.tscn")
const TILE = preload("res://scenes/tile.tscn")
const QUEEN = preload("res://scenes/queen.tscn")
const SOLUTION_TILE = preload("res://scenes/solution_tile.tscn")

var rows : Array = []
@onready var row_container: VBoxContainer = $row_container
@onready var queen_container: VBoxContainer = $queen_container
@onready var buttons: HBoxContainer = $buttons
@onready var solutions_scroll: ScrollContainer = $solutions_scroll
@onready var back: Panel = $back

var solutions : Array = []
var shown_solution : int = 0

#@export var board : Array = [
					#"oo",
					#"oo"
					#]
#6
#@export var board : Array = [
					#"oooooo",
					#"oooooo",
					#"oooooo",
					#"oooooo",
					#"oooooo",
					#"000000"
					#]
#7
#@export var board : Array = [
					#"ooooooo",
					#"ooooooo",
					#"ooooooo",
					#"ooooooo",
					#"ooooooo",
					#"ooooooo",
					#"0000000"
					#]
					
@export var board : Array = [
					"oooooooo",
					"oooooooo",
					"oooooooo",
					"oooooooo",
					"oooooooo",
					"oooooooo",
					"oooooooo",
					"00000000"
					]

#@export var board : Array = [
					#"oooo",
					#"oooo",
					#"oooo",
					#"0000"
					#]

#@export var board : Array = [
					#"ooo",
					#"ooo",
					#"000"
					#]

var solution_count = 0
var n = 8

var full_cells : Array = []
var rows_in_use : Dictionary = {}
var cols_in_use : Dictionary = {}
var diag1_in_use : Dictionary = {}
var diag2_in_use : Dictionary = {}

#var rows_in_use : Array = []
#var cols_in_use : Array = []
#var diag1_in_use: Array = []
#var diag2_in_use: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#create_board()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print('!')
	
	if Globals.dragging_queen:
		get_closest_tile()
	else:
		Globals.closest_cell = null
		
	update_selection_visuals()
	adjust_button_positions()
	adjust_queen_index()

func create_solutions():
	
	for s in solutions:
		var node = Control.new()
		node.custom_minimum_size = Vector2(0,16)
		var bar = SOLUTION_TILE.instantiate()
		node.add_child(bar)
		$solutions_scroll/VBoxContainer.add_child(node)
		
		bar.assign_solution(solutions.find(s) , self)
		
		sol_tab_quick_access.append(bar)
		
	#show_board()

func show_board():
	#await get_tree().create_timer(1).timeout
	
	var cells = cell_quick_access.duplicate()
	for n in cell_quick_access.size():
		var chosen_cell = cells.pick_random()
		chosen_cell.appear_tile()
		cells.erase(chosen_cell)
		
		await get_tree().create_timer(0.015).timeout

func hide_board():
	#await get_tree().create_timer(1).timeout
	
	var cells = cell_quick_access.duplicate()
	for n in cell_quick_access.size():
		var chosen_cell = cells.pick_random()
		chosen_cell.disappear_tile()
		cells.erase(chosen_cell)
		
		await get_tree().create_timer(0.015).timeout
	
func solver3(index := 0):
	if index >= queens.size(): # handle copying solution
		solutions.append(full_cells.duplicate())
		solution_count += 1
		return
	
	for col in range(board.size()):
		var cell = cell_quick_access_BYCOORD[Vector2(col, index)]
	
		var r = cell.global_row_pos
		var c = cell.global_col_pos
		var d1 = cell.global_row_pos - cell.global_col_pos
		var d2 = cell.global_row_pos + cell.global_col_pos
		
		if (full_cells.find(cell) != -1 or 
			rows_in_use.has(r) or 
			cols_in_use.has(c) or 
			diag1_in_use.has(d1) or
			diag2_in_use.has(d2)
			): #ignore full, in a used row, col, or diag ~ go next cell

			continue
		
		full_cells.append(cell)
		rows_in_use[r] = true
		cols_in_use[c] = true
		diag1_in_use[d1] = true
		diag2_in_use[d2] = true
		
		solver3(index + 1)

		full_cells.erase(cell)
		rows_in_use.erase(r)
		cols_in_use.erase(c)
		diag1_in_use.erase(d1)
		diag2_in_use.erase(d2)
			
#func solver(index := 0):
	#if index >= queens.size():
		#solutions.append(full_cells.duplicate())
		#solution_count += 1
		#return
	#
	#for cell in cell_quick_access:
		#if full_cells.has(cell) or rows_in_use.has(cell.global_row_pos) or cols_in_use.has(cell.global_col_pos): #ignore full
			#continue
		#
		#if not has_conflict(Vector2(cell.global_row_pos,cell.global_col_pos)):
			#full_cells.append(cell)
			#rows_in_use.append(cell.global_row_pos)
			#cols_in_use.append(cell.global_col_pos)
			#
			#solver(index + 1)
#
			#full_cells.erase(cell)
			#rows_in_use.erase(cell.global_row_pos)
			#cols_in_use.erase(cell.global_col_pos)
	
func has_conflict(coord):	
	var row = coord.x
	var col = coord.y
	
	for cell in full_cells:
		
		#Check Row
		if cell.global_col_pos == col:
			return true #cant go here
		
		#Check Col
		if cell.global_row_pos == row:
			return true #cant go here
		
		#Check Diagonal	
		var cell_x = cell.global_row_pos
		var cell_y = cell.global_col_pos
	
		if abs(cell_x - row) == abs(cell_y - col):
			return true  # same diagonal
	
	return false
		
	#await get_tree().create_timer(0).timeout
	#
	#if index >= queens.size():
		#return true  # done
	#
	#for cell in cell_quick_access:
		#if full_cells.has(cell): #ignore full
			#continue
		#
		#var rect = cell.get_global_rect()
		#var center = rect.position + rect.size / 2
		#var target_pos = center	
		#var queen = queens[index]
		#queen.solving = true
		#
		#queen.global_position = target_pos - queen.center_offset
		#
		#await get_tree().process_frame
		#
		#if not queen.check_colls_solver():
			#full_cells.append(cell)
			#
			#var success := await solver(index + 1)
			#if success:
				#return true
#
			#full_cells.erase(cell)
			#queen.solving = false
			#queen.targeted_cell = null
			#queen.global_position = Vector2(-1000, -1000)
					#
		#await get_tree().create_timer(0).timeout
		#
	#return false

func adjust_queen_index():
	for q in Globals.queens_off_board:
		q.adjust_indexing()

func create_board():
	var line_index = 0
	for line in board:
		
		var char_index = 0
		for char in line:
			
			if char_index == 0:
				create_row()
			
			if char == 'o':
				add_tile(line_index, char_index)
			elif char == '0':
				add_tile_bottom(line_index, char_index)
			
			char_index += 1
			
		line_index += 1
	
	
	Globals.board_reference = row_container
	setup_queens()

func setup_queens():
	queens_offboard = starting_queens
	
	for i in starting_queens:
		var new_queen = QUEEN.instantiate()
		queen_container.add_child(new_queen)
		queens.append(new_queen)
		#new_queen.anchored_pos = row_container.global_position + Vector2(row_container.size.x + 8, 0)
	
	#await get_tree().create_timer(10).timeout
	
	solver3()
	
	var sols = []
	for s in solutions:
		var solution_in_coords = []
		
		for cell in s:
			solution_in_coords.append(Vector2(cell.global_row_pos, cell.global_col_pos))
			solution_in_coords.sort()
		
		if not sols.has(solution_in_coords):	
			sols.append(solution_in_coords)
		
	sols.sort()
	
	solutions.clear()
	solutions = sols
	
	create_solutions()
		
func create_row():
	var row = ROW.instantiate()
	row_container.add_child(row)
	rows.append(row)

func add_tile(line_index,char_index):
	var tile = TILE.instantiate()
	rows[line_index].add_child(tile)
	tile.call_deferred("create", char_index + line_index, char_index, board.size() - line_index)
	
	tile.set_globals(char_index, line_index)
	cell_quick_access.append(tile)
	cell_quick_access_BYCOORD[Vector2(char_index, line_index)] = tile

func add_tile_bottom(line_index,char_index):
	var tile = TILE.instantiate()
	rows[line_index].add_child(tile)
	tile.call_deferred("create", char_index + line_index, char_index, board.size() - line_index, true)
	
	tile.set_globals(char_index, line_index)
	cell_quick_access.append(tile)
	cell_quick_access_BYCOORD[Vector2(char_index, line_index)] = tile
	
func get_closest_tile():
	
	Globals.closest_distance = INF
	
	for cell in cell_quick_access:
	
		var rect = cell.get_global_rect()
		var center = rect.position + rect.size / 2
		var dist = get_global_mouse_position().distance_to(center)
		
		if dist <= Globals.closest_distance and dist <= 32:
			Globals.closest_distance = dist
			Globals.closest_cell = cell
			
		if dist <= Globals.closest_distance and dist >= 32:
			Globals.closest_cell = null
	
func update_selection_visuals():
	for cell in cell_quick_access:
		if not Globals.closest_cell == cell:
			cell.selection_dot_disappear()
		else:
			cell.selection_dot_appear()

func check_solve():
	var solution : Array = []
	for queen in queen_container.get_children():
		if queen.placed or queen.dragging:
			var cell = queen.targeted_cell
			
			#queen.check_collisions()
			
			solution.append(Vector2(cell.global_row_pos,cell.global_col_pos))
	
	solution.sort()

	if solutions.find(solution) != -1:
		var index = solutions.find(solution)
	
		sol_tab_quick_access[index].mark_solved()
	
func _on_solve_pressed() -> void:
	check_solve()

func adjust_button_positions():
	buttons.global_position = row_container.global_position + Vector2(row_container.size.x + 8, 0)
	#solutions_scroll.global_position = Vector2(buttons.global_position.x + 2,buttons.global_position.y + buttons.size.y + 12)
	
	solutions_scroll.global_position = Vector2(buttons.global_position.x + 96/2 - solutions_scroll.size.x/2,buttons.global_position.y + buttons.size.y + 12)
	solutions_scroll.size.y = (board.size() - 1) * 32 - 10
	$top_sols.global_position = solutions_scroll.global_position + Vector2(0, - 8)
	$bot_sols.global_position = solutions_scroll.global_position + Vector2(0, solutions_scroll.size.y + 2)
	back.global_position = row_container.global_position - Vector2(150,10)
	back.size.y = (board.size()) * 32 + 30
	back.size.x = (board[0].length()) * 32 + 300
	pass 

func show_solution(sol := shown_solution):
	var index = 0
	for q in queens:
		
		var cell = cell_quick_access_BYCOORD[solutions[sol][index]]
		
		q.targeted_cell = cell
		q.placed = true
		q.reset_index()
	
		index += 1
	
func _on_show_next_sol_pressed() -> void:
	shown_solution += 1
	if shown_solution >= solutions.size():
		shown_solution = 0
		
	show_solution()

func _on_clear_pressed() -> void:
	for q in queens:
		q.reset_queen()

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_board()
	else:
		hide_board()
