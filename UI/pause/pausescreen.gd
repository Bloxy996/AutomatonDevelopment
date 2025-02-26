extends ColorRect #skript for the pause screen, sadly it's not its own scene
class_name Pause

@onready var loader: Loader = $"../../loader"

func _process(_delta: float) -> void: #runs on every picosecond because you have something comparable to a quantum computer in your noggin
	if Input.is_action_just_pressed('pause'): #if the pause menu is called by pressing escape
		if get_tree().paused:
			resume() #resume the game
		else:
			get_tree().paused = true #pause the game
			show() #show the menu

func _on_resume_pressed() -> void: #runs when someone presses the resume button
	resume() #resume the game

func resume() -> void: #resume the game
	get_tree().paused = false #unpause the game
	hide() #hide the menu

func _on_quit_pressed() -> void: #runs when someone presses the quit button
	get_tree().paused = false #unpause the game
	Main.savegame()
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://UI/mainmenu/start menu.tscn") #go to the start menu

func _on_save_pressed() -> void: #save the game when the savegame button is pressed
	get_tree().paused = false #unpause the game
	Main.savegame()
	hide() #hide the menu

func _on_reset_pressed() -> void: #reset the player
	get_tree().paused = false #unpause the game
	Main.main.player.reset() #do the reset thingy
