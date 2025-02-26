extends Control

@onready var loader: Loader = $loader

func _ready() -> void:
	loader.showscreen() #show the screen

func _on_exit_pressed() -> void: #goes back to the main scene
	loader.hidescreen(); await loader.anim.animation_finished #hide the screen
	get_tree().change_scene_to_file("res://UI/mainmenu/start menu.tscn")
