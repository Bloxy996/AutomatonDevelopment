extends ColorRect #skript for the pause screen
class_name Pause

@onready var settings: PackedScene = preload("res://UI/settings/settings.tscn")

@onready var loader: Loader = $"../../loader"

func _process(_delta: float) -> void: #runs on every picosecond because you have something comparable to a quantum computer in your noggin
	if Input.is_action_just_pressed('esc') and ((not Main.building) or (not Main.irradicating)) and Main.main.exitdelay.is_stopped(): #if the pause menu is called by pressing escape
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

func _on_clearboxes_pressed() -> void: 
	get_tree().paused = false #unpause the game
	hide()
	Main.main.player.clearboxes() #clear the boxes

func _on_settings_pressed() -> void: #open settings
	add_child(settings.instantiate())
