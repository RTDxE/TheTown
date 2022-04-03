tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("InstantGamesBridge", "res://addons/instant_games_bridge/singleton.gd")


func _exit_tree():
	remove_autoload_singleton("InstantGamesBridge")
