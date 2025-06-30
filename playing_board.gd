extends Control

var cell_quick_access : Array = []
var sol_tab_quick_access : Array = []
var cell_quick_access_BYCOORD : Dictionary = {}
var board_size : int = 0

var cells_per_row : Dictionary = {}
var cells_per_col : Dictionary = {}

var solution_container
var solution_count : int = 0
var solutions : Array = []
var full_cells : Array = []
var rows_in_use : Dictionary = {}
var cols_in_use : Dictionary = {}
var diag1_in_use : Dictionary = {}
var diag2_in_use : Dictionary = {}

const TILE = preload("res://scenes/tile.tscn")
const ROW = preload("res://scenes/row.tscn")
const SOLUTION_TILE = preload("res://scenes/solution_tile.tscn")
const SOLUTION_HOLDERS = preload("res://themes/solution_holders.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#create_board()
	#show_board()
	
	#position -= Vector2(size.x/2, size.y/2)
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_solution(sol):
	var index = 0
	for queen in get_parent().queen_container.get_children():
		var q = queen.get_child(0)
		
		var cell = cell_quick_access_BYCOORD[solutions[sol][index]]
		
		q.targeted_cell = cell
		q.placed = true
		q.reset_index()
	
		index += 1

func create_solution_boxes():
	var sols = SOLUTION_HOLDERS.instantiate()
	get_parent().add_child(sols)
	
	solution_container = sols
	
	for s in solutions:
		var node = Control.new()
		node.custom_minimum_size = Vector2(32,32)
		node.pivot_offset = Vector2(32,14.5)
		var bar = SOLUTION_TILE.instantiate()
		node.add_child(bar)
		bar.position += Vector2(38,14.5)
		sols.get_child(0).add_child(node)
		bar.assign_solution(solutions.find(s) , self)
		sol_tab_quick_access.append(node)
		
		bar.scale = Vector2(0,0)
		
		node.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	
	#get_parent().hide_solutions(sols, 0)

func generate_solutions(index := 0):
	if index >= board_size: # handle copying solution
		solutions.append(full_cells.duplicate())
		solution_count += 1
		return
	
	for col in range(board_size):
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
		
		generate_solutions(index + 1)

		full_cells.erase(cell)
		rows_in_use.erase(r)
		cols_in_use.erase(c)
		diag1_in_use.erase(d1)
		diag2_in_use.erase(d2)

func create_board(size := 5):
	board_size = size
	self.size = Vector2(size * 32,size * 32)
	
	for x in size:
		for y in size:
			if x == 0:
				create_row()
			
			create_tile(x,y)

	generate_solutions()
	
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
	
	create_solution_boxes()



func create_row():
	var row = ROW.instantiate()
	add_child(row)

func create_tile(x, y):
	var tile = TILE.instantiate()
	get_child(y).add_child(tile)
	tile.call_deferred("create", x + y, x, y)
	
	cell_quick_access.append(tile)
	tile.set_globals(x, y)
	
	if cells_per_row.has(x):
		var cells = cells_per_row[x]
		cells.append(tile)
		cells_per_row[x] = cells
	else:
		cells_per_row[x] = [tile]
		
	cell_quick_access.append(tile)
	
	cell_quick_access_BYCOORD[Vector2(x, y)] = tile

func show_board():
	solution_container.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	get_parent().spawn_queens(board_size)
	var cells = cell_quick_access.duplicate()
	cells.shuffle()
	for n in cells:
		n.appear_tile()
		
		await get_tree().create_timer(0).timeout
	
	await get_tree().create_timer(.5).timeout
	
	get_parent().appear_queens()
	get_parent().show_solutions(solution_container)
		
	return

func hide_board():
	solution_container.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	get_parent().hide_queens()
	get_parent().hide_solutions(solution_container)
	
	var cells = cell_quick_access.duplicate()
	cells.shuffle()
	for n in cells:
		n.disappear_tile()
		
		await get_tree().create_timer(0).timeout

	return

func bounce():
	var cells = cell_quick_access.duplicate()
	for n in cell_quick_access.size():
		var chosen_cell = cells.pick_random()
		chosen_cell.bounce_tile()
		cells.erase(chosen_cell)
		
	return
