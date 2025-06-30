extends Control

var colliding_rays_IN : Array = []
var colliding_rays_OUT : Array = []

var valid_placement : bool = false
var placed : bool = false
var solving : bool = false
var targeted_cell 
var last_mouse_pos := Vector2.ZERO
var target_rotation := 0.0
var target_pos : Vector2
var dragging : bool = false
var anchored_pos : Vector2 = Vector2.ZERO
var center_offset : Vector2 = Vector2(16,16)
var shadow_tween : Tween
@onready var raycasts: Node2D = $raycasts
@onready var texture_rect: TextureRect = $TextureRect
@onready var shadow: TextureRect = $TextureRect/shadow
@onready var area_2d: Area2D = $Area2D

const BLACK_QUEEN_STYLE_2 = preload("res://sprites/black_queen_style2.png")
const WHITE_QUEEN_STYLE_2 = preload("res://sprites/white_queen_style2.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_color()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if placed or dragging:
		
		if Globals.queens_off_board.find(self) != -1:
			Globals.queens_off_board.erase(self)
			
	else:
		
		if Globals.queens_off_board.find(self) == -1:
			Globals.queens_off_board.append(self)
	
	if is_colliding():
		if Input.is_action_just_pressed("left_click") and not Globals.dragging_queen:
			Globals.dragging_queen = true
			dragging = true
			bring_front()
		
		if Input.is_action_just_pressed("right_click"):
			reset_queen()
			
	if dragging and Input.is_action_just_released("left_click"):
		Globals.dragging_queen = false
		dragging = false
		
		reset_index()
		
		if (Globals.closest_cell and not Globals.closest_cell.full) or (Globals.closest_cell and Globals.closest_cell == targeted_cell):
			
			if targeted_cell and targeted_cell != Globals.closest_cell and targeted_cell.placed_queen == self:
				targeted_cell.placed_queen = null
				targeted_cell.full = false	
			
			Globals.closest_cell.placed_queen = self
			Globals.closest_cell.full = true
			targeted_cell = Globals.closest_cell
			placed = true
			
			
		
		elif targeted_cell:
			reset_queen()	
		
	if dragging:
		target_pos = get_global_mouse_position()
	elif placed:
		get_cell_pos()
	#elif solving:
	#	get_cell_pos()
	elif not solving:
		target_pos = Vector2.ZERO
		#var index = Globals.queens_off_board.find(self)
		#target_pos = Vector2(-Globals.board_reference.size.x/2 - size.x/2 - 4, -8.5 + (index * 12))
		
	smooth_lerping()
	drag_sway()
	
	if colliding_rays_IN.size() > 0:
		texture_rect.modulate = Color.RED
	else:
		texture_rect.modulate = Color.WHITE

func appear():
	var tween = create_tween()
	tween.tween_property(texture_rect, "scale", Vector2(.9, .9), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func disappear():
	var tween = create_tween()
	tween.tween_property(texture_rect, "scale", Vector2(0, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	get_parent().call_deferred("free")


func adjust_indexing():
	texture_rect.z_index = 1 + (Globals.queens_off_board.size() - Globals.queens_off_board.find(self))

func is_colliding():
	var mos_pos = get_global_mouse_position()
	var rect = texture_rect.get_global_rect()
	
	if (
		mos_pos.x > rect.position.x and 
		mos_pos.x < rect.size.x + rect.position.x and
		mos_pos.y > rect.position.y and 
		mos_pos.y < rect.size.y + rect.position.y
		):
		
		return true
		
	return false

func smooth_lerping():
	
	if dragging or placed:
		global_position = global_position.lerp(target_pos - center_offset*2, .25)
	#elif solving:
	#	global_position = target_pos - center_offset
	elif not solving:
		position = position.lerp(target_pos, .125)
	
func get_cell_pos():
	var rect = targeted_cell.get_global_rect()
	var center = rect.position + rect.size / 2
	target_pos = center	

func reset_queen():
	if targeted_cell:
		targeted_cell.placed_queen = null
		targeted_cell.full = false
		placed = false

	reset_index()

func check_collisions():
	var currently_hit_queens := []

	for ray: RayCast2D in raycasts.get_children():
		if ray.is_colliding():
			var hit_queen = ray.get_collider().get_parent()

			if hit_queen.placed or hit_queen.dragging or hit_queen.solving:
				currently_hit_queens.append(hit_queen)
				print("!")
				if hit_queen.colliding_rays_IN.find(self) == -1:
					hit_queen.colliding_rays_IN.append(self)

				if colliding_rays_OUT.find(hit_queen) == -1:
					colliding_rays_OUT.append(hit_queen)

	for queen in colliding_rays_OUT.duplicate():
		if queen not in currently_hit_queens:
			if queen.colliding_rays_IN.has(self):
				queen.colliding_rays_IN.erase(self)

			colliding_rays_OUT.erase(queen)

func check_colls_solver():
	for ray: RayCast2D in raycasts.get_children():
		ray.force_raycast_update()
		if ray.is_colliding():
			var hit_queen = ray.get_collider().get_parent()
			if hit_queen.placed or hit_queen.dragging or hit_queen.solving:
				print("!")
				return true
	
	print("?")
	return false

func on_ray_hit(coll):
	colliding_rays_IN.append(coll)

func bring_front():
	lerp_shadow_up()
	z_index = 15
	
func reset_index():
	lerp_shadow_down()
	z_index = 1

func set_color():
	if randi_range(0,2) == 0:
		texture_rect.texture = BLACK_QUEEN_STYLE_2
	else:
		texture_rect.texture = WHITE_QUEEN_STYLE_2

func drag_sway():
	var current_mouse_pos = get_global_mouse_position()
	var mouse_delta = current_mouse_pos - last_mouse_pos

	if dragging:
		target_rotation = clamp(-mouse_delta.x * 0.08, -0.5, 0.5)
	else:
		target_rotation = 0.0

	texture_rect.rotation = lerp(texture_rect.rotation, target_rotation, 0.1)

	last_mouse_pos = current_mouse_pos
	
func lerp_shadow_up():
	var mat = shadow.material
	
	if shadow_tween:
		shadow_tween.kill()
		
	shadow_tween = create_tween()
		
	shadow_tween.parallel().tween_property(mat, "shader_parameter/shadow_offset", Vector2(0,5), .15)
	shadow_tween.parallel().tween_property(texture_rect, "scale", Vector2(1,1), .15)

func lerp_shadow_down():
	var mat = shadow.material
	
	if shadow_tween:
		shadow_tween.kill()
		
	shadow_tween = create_tween()
		
	shadow_tween.parallel().tween_property(mat, "shader_parameter/shadow_offset", Vector2(0,0), .125)
	shadow_tween.parallel().tween_property(texture_rect, "scale", Vector2(.9,.9), .125)
