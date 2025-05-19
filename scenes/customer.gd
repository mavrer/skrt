extends CharacterBody2D

@export var npc_name: String = ""
@export var animation_data: Resource

var target: Vector2 = Vector2.ZERO
var last_direction := Vector2.DOWN
var moving := false
var waiting_in_queue := false
var finished_drinking := false
var can_talk := false
var queue_index := -1
var order_successful := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var area: Area2D = $InteractionArea

func _ready():
	last_direction = Vector2.DOWN
	load_animation_data()
	agent.radius = 8
	area.body_entered.connect(_on_interaction_area_body_entered)

func load_animation_data():
	if animation_data and animation_data is SpriteFrames:
		sprite.sprite_frames = animation_data
		var animations = sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			sprite.play(animations[0])

func trigger_entry():
	moving = true
	target = get_cafe().get_spawn_queue_position()
	agent.target_position = target
	update_walk_animation(global_position, target)

func _physics_process(delta):
	if moving:
		var next_path = agent.get_next_path_position()
		if next_path != Vector2.ZERO:
			var direction = (next_path - global_position).normalized()
			velocity = direction * 50.0
			update_animation(direction)
			move_and_collide(velocity * delta)

		if agent.is_navigation_finished():
			stop_movement()

func update_animation(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if direction.y > 0 else "walk_up")
	last_direction = direction

func update_walk_animation(from_position: Vector2, to_position: Vector2):
	var direction = (to_position - from_position).normalized()
	update_animation(direction)

func stop_movement():
	moving = false
	velocity = Vector2.ZERO

	if sprite.animation.begins_with("walk_"):
		sprite.stop()
		sprite.frame = 1

	if last_direction.x > 0:
		sprite.animation = "walk_right"
	elif last_direction.x < 0:
		sprite.animation = "walk_left"
	elif last_direction.y > 0:
		sprite.animation = "walk_down"
	else:
		sprite.animation = "walk_up"

	sprite.stop()
	sprite.frame = 1

func move_to_queue():
	queue_index = Global.customer_queue.size()
	Global.customer_queue.append(self)

	var queue_pos = get_cafe().get_queue_position(queue_index)
	target = queue_pos
	agent.target_position = target
	update_walk_animation(global_position, target)

	moving = true
	waiting_in_queue = true

	await agent.navigation_finished
	stop_movement()
	sprite.frame = 0

func process_queue():
	Global.queue_size -= 1
	for i in range(Global.queue_size):
		var cust = Global.customer_queue[i]
		cust.queue_index = i
		var new_pos = get_cafe().get_queue_position(i)
		cust.agent.target_position = new_pos
		cust.update_walk_animation(cust.global_position, new_pos)

func on_order_done():
	pass

func move_to_seat() -> void:
	moving = true

	# najpierw przejście do QueueSeat
	var middle = get_cafe().get_queue_seat_position()
	target = middle
	agent.target_position = target
	update_walk_animation(global_position, target)
	await agent.navigation_finished

	# potem do swojego stolika (S1, S2, ...)
	var seat_pos = get_cafe().get_seat_position(npc_name)
	target = seat_pos
	agent.target_position = seat_pos
	update_walk_animation(middle, seat_pos)
	await agent.navigation_finished



# Przejście do miejsca picia
	var marker_name = Global.npc_drink_positions.get(npc_name, null)
	if marker_name:
		var marker_path = "GameRoot/Drink/Positions/" + marker_name
		var marker_node = get_tree().root.get_node_or_null(marker_path)
		if marker_node:
			global_position = marker_node.global_position
			play_drink_animation()
			on_coffee_ready()
	






func play_drink_animation():
	var marker_name = Global.npc_drink_positions.get(npc_name, null)
	if marker_name:
		var marker_path = "GameRoot/Drink/Positions/" + marker_name
		var marker_node = get_tree().root.get_node_or_null(marker_path)
		if marker_node:
			var drink_pos = marker_node.global_position
			target = drink_pos
			agent.target_position = drink_pos
			sprite.play("drink")
		


func on_coffee_ready():
	check_order_success()
	if order_successful:
		await get_tree().create_timer(10.0).timeout
		if can_talk:
			start_dialog()
	else:
		handle_wrong_order()

func check_order_success():
	if Global.order_successful:
		order_successful = true
		wait_for_player_interaction()

func wait_for_player_interaction():
	can_talk = true

func start_dialog():
	var dialogue_manager = get_node("/root/DialogueManager")
	dialogue_manager.start_dialogue("res://dialogi/" + npc_name + "_dialogue.dialogue", { "npc_name": npc_name })
	await get_tree().create_timer(5.0).timeout
	move_to_exit()

func move_to_exit():
	var exit_pos = get_cafe().get_exit_position()
	target = exit_pos
	agent.target_position = exit_pos
	update_walk_animation(global_position, exit_pos)
	await agent.navigation_finished
	queue_free()

func handle_wrong_order():
	sprite.play("drink")
	await get_tree().create_timer(5.0).timeout
	sprite.stop()
	move_to_exit()

func show_order():
	if not is_inside_tree() or has_node("DialogueBubble"):
		return
	var order = Global.npc_orders.get(npc_name, "coffee")
	var dialogue_manager = get_node("/root/DialogueManager")
	dialogue_manager.start_dialogue("res://dialogi/orders.dialogue", { "order": order })

func move_to_marker(pos: Vector2):
	moving = true
	waiting_in_queue = true
	target = pos
	agent.target_position = pos
	update_walk_animation(global_position, pos)

func _on_interaction_area_body_entered(body: Node2D):
	if body.name == "Player" and order_successful:
		can_talk = true

func get_cafe() -> Node:
	return get_tree().root.get_node("GameRoot/Cafe")
