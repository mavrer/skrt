extends Node

@onready var start = $Start
@onready var cafe = $Cafe
@onready var express = $Express

@onready var player_scene := preload("res://scenes/Player.tscn")
var player: Node2D = null
var player_spawned := false  # Flaga czy gracz już istnieje



func _ready():
	show_location("start")

func start_new_game():
	if not player_spawned:
		player = player_scene.instantiate()
		player_spawned = true
		var cafe_ysort = cafe.get_node("YSortcafe")
		cafe_ysort.add_child(player)
		player.global_position = Vector2(-93, -29)
	else:
		move_player_to_scene("cafe")

	await get_tree().process_frame  # <-- odczekaj jedną klatkę
	print("Player pos:", player.global_position, "Visible:", player.visible)

	cafe.reset_timer()
	cafe.start_timer()
	show_location("cafe")
	print("Cafe pos:", cafe.position)
	print("Player global pos:", player.global_position)





func show_location(location_name: String):
	start.visible = false
	cafe.visible = false
	express.visible = false

	match location_name:
		"start":
			start.visible = true
			var cam = start.get_node("Camera2D")
			cam.make_current()

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
