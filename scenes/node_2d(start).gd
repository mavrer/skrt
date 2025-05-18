extends Node2D

@onready var play_button = $Control/Play



func _on_play_pressed():
	var game_root = get_node("/root/GameRoot")
	game_root.start_new_game()
