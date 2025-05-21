extends Node

@onready var start = $Start
@onready var cafe = $Cafe
@onready var express = $Express
@onready var continue_button = start.get_node("Control/ContinueGame")

@onready var player_scene := preload("res://scenes/Player.tscn")
var player: Node2D = null
var player_spawned := false  

var previous_location := "" #do escape




func _ready():

	show_location("start")

	start.get_node("Control/ContinueGame").visible = false
	start.connect("continue_pressed", Callable(self, "_on_continue_game_pressed"))


func start_new_game():
	get_tree().paused = false

# jeśli jest już gracz, usuń go
	if player_spawned and player:
		if player.get_parent():
			player.get_parent().remove_child(player)
			player.queue_free()
			player = null
			player_spawned = false

	# stwórz nowego gracza
	player = player_scene.instantiate()
	player_spawned = true

	var cafe_ysort = cafe.get_node("YSortcafe")
	cafe_ysort.add_child(player)
	player.global_position = Vector2(-93, -29)  # pozycja startowa

	await get_tree().process_frame
	print("Player pos:", player.global_position, "Visible:", player.visible)

	cafe.reset_timer()
	cafe.start_timer()
	previous_location = ""  # czyścimy poprzednią lokalizację, bo zaczynamy nową grę
	show_location("cafe")
	print("Cafe pos:", cafe.position)
	print("Player global pos:", player.global_position)

#do escape
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not start.visible:
			previous_location = current_scene_name()
			show_location("start")
			get_tree().paused = true


func _on_continue_game_pressed():
	if previous_location != "":
		show_location(previous_location)
		get_tree().paused = false


func current_scene_name() -> String:
	if cafe.visible:
		return "cafe"
	elif express.visible:
		return "express"
	else:
		return "start"




func show_location(location_name: String):
	start.visible = false
	cafe.visible = false
	express.visible = false

	match location_name:
		"start":
			start.visible = true
			var cam = start.get_node("Camera2D")
			cam.make_current()
			# Pokaż lub ukryj ContinueGame zależnie od tego, czy mamy do czego wracać
			continue_button.visible = previous_location != ""


		"cafe":
			cafe.visible = true
			move_player_to_scene("cafe")
			var cam = cafe.get_node("Camera2D")
			cam.make_current()

		"express":
			express.visible = true
			move_player_to_scene("cafe")
			var cam = express.get_node("Camera2D")
			cam.make_current()


func move_player_to_scene(target_scene: String):
	if not player:
		return

	var target_ysort: Node = null

	match target_scene:
		"cafe":
			target_ysort = cafe.get_node("YSortcafe")

	if target_ysort and player.get_parent() != target_ysort:
		if player.get_parent():
			player.get_parent().remove_child(player)
		target_ysort.add_child(player)
