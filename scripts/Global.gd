extends Node

var customer_queue: Array = []
var current_order_combo: Array = []
var player_combo: Array = []
var order_successful: bool = false
var current_customer = null

var dialogue_balloon_manager: Node = null
var queue_size := 0

func _ready():
	dialogue_balloon_manager = get_node("/root/DialogueManager")

var coffee_buttons = {
	"Cappuccino": [2, 5, 7],
	"Espresso": [1, 4, 6],
	"Latte": [3, 5, 8],
}

var npc_orders = {
	"Astrid": "Cappuccino",
	"Caroline": "Latte"
}

var npc_seat_markers := {
	"Astrid": "S1",
	"Caroline": "S2",
	"Lucas": "S3"
}

var npc_drink_positions := {
	"Astrid": "D1",
	"Caroline": "D2",  
	# itd.
}


func set_order_for_customer(npc_name: String):
	match npc_name:
		"Astrid": current_order_combo = [2, 5, 7]
		"Caroline": current_order_combo = [1, 3, 6, 7]
		_: current_order_combo = []
	player_combo.clear()

func handle_customer_after_order():
	if customer_queue.size() == 0:
		return
	var npc = customer_queue[0]
	if npc and is_instance_valid(npc):
		if order_successful:
			npc.on_order_done()
		await npc.move_to_seat()
		customer_queue.remove_at(0)
		npc.process_queue()

func shift_queue():
	for i in range(customer_queue.size()):
		var npc = customer_queue[i]
		npc.queue_index = i
		var cafe = get_tree().root.get_node("GameRoot/Cafe")
		var target_pos = cafe.get_queue_position(i)
		npc.move_to_marker(target_pos)
