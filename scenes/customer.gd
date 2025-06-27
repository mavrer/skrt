extends CharacterBody2D

@export var npc_name: String = ""
@export var animation_data: Resource

@onready var drink_timer: Timer = $DrinkTimer


var target: Vector2 = Vector2.ZERO
var last_direction := Vector2.DOWN
var moving := false
var waiting_in_queue := false
var finished_drinking := false
var can_talk := false
var queue_index := -1
var order_successful := false
var exiting := false  # zabezpieczenie przed wielokrotnym move_to_exit()
#var dialogue_resource = null
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var area: Area2D = $InteractArea



func _ready():
	last_direction = Vector2.DOWN
	load_animation_data()
	agent.radius = 8
	#area.body_entered.connect(_on_interact_area_body_entered)
	area.monitoring = false
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

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
	sprite.stop()
	sprite.frame = 1

func move_to_queue():
	if self in Global.customer_queue:
		print("BLADmove to queue")
		return
	
	queue_index = Global.customer_queue.size()
	Global.customer_queue.append(self)

	var queue_pos = get_cafe().get_queue_position(queue_index)
	print("idzie ", npc_name, )
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


func move_to_seat() -> void:
	moving = true

	var middle = get_cafe().get_queue_seat_position()
	target = middle
	agent.target_position = middle
	update_walk_animation(global_position, middle)
	await agent.navigation_finished

	var seat_pos = get_cafe().get_seat_position(npc_name)
	target = seat_pos
	agent.target_position = seat_pos
	update_walk_animation(middle, seat_pos)
	await agent.navigation_finished

	sprite.position.y += 10
	sprite.play("drink")
	area.monitoring = true;
	can_talk = true 
	var wait_time = 20.0 if order_successful else 10.0
	drink_timer.wait_time = wait_time
	drink_timer.timeout.connect(_on_drink_finished, CONNECT_ONE_SHOT)
	drink_timer.start()
	
func _on_drink_finished():
	sprite.position.y -= 10
	finished_drinking = true
	await move_to_exit()

func move_to_exit():
	if exiting:
		return
	exiting = true

	var exit_pos = get_cafe().get_exit_position()

	target = exit_pos
	agent.target_position = exit_pos
	update_walk_animation(global_position, exit_pos)

	moving = true  
	await agent.navigation_finished
	queue_free()

	if npc_name == "Pierce" and Global.current_day == 5:
		get_node("/root/GameRoot").pierce_out = true



func start_dialog():
	can_talk = false

	var npc_name = self.npc_name
	var visit_count = Global.npc_dialogue_counters.get(npc_name, 1)
	var dialogue_list = Global.dialogues.get(npc_name, [])

	if dialogue_list.is_empty():
		print("Brak dial")
		return

	var index = clamp(visit_count - 1, 0, dialogue_list.size() - 1)
	var dialogue = dialogue_list[index]
	var file_name = dialogue.resource_path.get_file().get_basename()

	print("d nr", "dla", npc_name, "fn: ", file_name)

	DialogueManager.show_example_dialogue_balloon(
	dialogue,
	"start",
	[{ "npc_name": npc_name }],
	preload("res://scenes/copydialogueballon/copyballoon.tscn"))

func _on_dialogue_finished(dialogue_resource):
	var file_name = dialogue_resource.resource_path.get_file().get_basename()
	#po zakonczeniu dialogu
	drink_timer.paused = false

	if not Global.npc_dialogue_counters.has(self.npc_name):
		Global.npc_dialogue_counters[self.npc_name] = 1
	else:
		Global.npc_dialogue_counters[self.npc_name] += 1

func move_to_marker(pos: Vector2):
	moving = true
	waiting_in_queue = true
	target = pos
	agent.target_position = pos
	update_walk_animation(global_position, pos)


func _on_interact_area_body_entered(body: Node2D) -> void:	
	if body.name == "Player" and order_successful and can_talk and not finished_drinking:
		drink_timer.paused = true
		start_dialog()

	if body.name == "Player" and npc_name=="Pierce" and Global.current_day==5 and not finished_drinking:
		start_dialog()


func get_cafe() -> Node:
	return get_tree().root.get_node("GameRoot/Cafe")
