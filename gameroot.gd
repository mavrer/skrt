extends Node

@onready var start = $Start
@onready var cafe = $Cafe
@onready var express = $Express
@onready var home = $Home
@onready var city = $City
@onready var day_number = $Day_Number
@onready var ending = $Ending

var pierce_out := false  #glob

@onready var continue_button = start.get_node("Control/ContinueGame")

@onready var player_scene := preload("res://scenes/Player.tscn")
var player: Node2D = null
var player_spawned := false  

var previous_location := "" #do escape
var current_location := ""

@onready var day_number_scene := preload("res://scenes/daynumber.tscn")

func _ready():
	show_location("start")
	start.get_node("Control/ContinueGame").visible = false
	start.connect("continue_pressed", Callable(self, "_on_continue_game_pressed"))


func next_day():
	Global.current_day += 1

	if Global.current_day < 6:
		show_location("day_number")
	else:
		show_location("ending")


func _on_day_number_timeout():
	for child in get_children():
		if child.name == "DayNumber":
			remove_child(child)
			child.queue_free()
			break
	show_location("home")


func start_new_game():
	get_tree().paused = false
	player = player_scene.instantiate()
	player_spawned = true
	show_location("home")
	


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not start.visible:
			#previous_location = current_scene_name()
			show_location("start")
			get_tree().paused = true


func _on_continue_game_pressed():
	if previous_location != "":
		show_location(previous_location)
		get_tree().paused = false


func show_location(location_name: String, ysort_name: String = "", spawn_name: String = ""):
	start.visible = false
	cafe.visible = false
	express.visible = false
	home.visible = false
	city.visible = false
	day_number.visible =false
	ending.visible =false

	# save
	if location_name != "":
		previous_location = current_location
	current_location = location_name

	match location_name:
		"start":
			start.visible = true
			var cam = start.get_node("Camera2D")
			cam.make_current()
			continue_button.visible = previous_location != ""
			previous_location="start"
		
		"cafe":
			cafe.visible = true
			print("day: ", Global.current_day)  
			if previous_location == "city":
				cafe.start_day(Global.current_day)
			move_player_to_scene("cafe", "YSortCafe", "PlayerSpawn")  # poprawione
			cafe.get_node("Camera2D").make_current()
			previous_location="cafe"
		"express":
			express.visible = true
			express.get_node("Camera2D").make_current()
			previous_location="express"


		"home":
			home.visible = true
			move_player_to_scene("home", "YSortHome", "PlayerSpawn") 
			home.get_node("Camera2D").make_current()
			previous_location="home"
			
		"day_number":
			day_number.visible=true
			day_number.get_node("Label").text = "Dzień %d" % Global.current_day
			day_number.get_node("Camera2D").make_current()
			day_number.get_node("2secTimer").connect("timeout", Callable(self, "_on_day_number_timeout"), CONNECT_ONE_SHOT)
			day_number.get_node("2secTimer").start()
			previous_location="day_number"
		"ending":
			ending.visible=true
			ending.get_node("Camera2D").make_current()

			DialogueManager.show_example_dialogue_balloon(
			load("res://dialogi/1ending.dialogue"))

		"city":
			city.visible = true
			if previous_location == "home":
				spawn_name = "PlayerSpawn1"
			elif previous_location == "cafe":
				spawn_name = "PlayerSpawn2"
			else:
				spawn_name = "PlayerSpawn"  

			move_player_to_scene("city", "YSortCity", spawn_name)

			if player:
				var follow_cam := player.get_node("FollowCam") as Camera2D
				var city_cam := city.get_node_or_null("Camera2D") as Camera2D
				if follow_cam and city_cam:
					var screen_size = get_viewport().get_visible_rect().size / city_cam.zoom
					var cam_center = city_cam.global_position

					follow_cam.limit_left = int(cam_center.x - screen_size.x / 2)
					follow_cam.limit_right = int(cam_center.x + screen_size.x / 2)
					follow_cam.limit_top = int(cam_center.y - screen_size.y / 2)
					follow_cam.limit_bottom = int(cam_center.y + screen_size.y / 2)

					follow_cam.make_current()





func move_player_to_scene(scene_name: String, ysort_name: String, spawn_name: String):
	var scene_dict = {
		"start": start,
		"home": home,
		"cafe": cafe,
		"express": express,
		"city": city
	}

	var scene = scene_dict.get(scene_name, null)

	var ysort = scene.get_node_or_null(ysort_name)

	var spawn = ysort.get_node_or_null(spawn_name)
	
	if player.get_parent() != ysort:
		if player.get_parent():
			player.get_parent().remove_child(player)
		ysort.add_child(player)

	player.global_position = spawn.global_position
	print("Poz pl", player.global_position)
