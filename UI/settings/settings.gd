extends Control
class_name Settings

@onready var kreditindikator: CheckButton = $indikators/container/kredits/kreditindikator
@onready var multiplierindikator: CheckButton = $indikators/container/multipliers/multiplierindikator
@onready var daynight: CheckButton = $daynight/daynight

func _ready() -> void:
	#update all the settings based on what is already in the main thingy
	kreditindikator.button_pressed = Main.settings.indikator.kredit
	multiplierindikator.button_pressed = Main.settings.indikator.multiplier
	daynight.button_pressed = Main.settings.daynight

func _on_exit_pressed() -> void: #save and remove the menu on exit
	save(); queue_free()

func _on_save_pressed() -> void: #save when the user presses the save button
	save()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('esc'): #esc also closes the menu
		save(); queue_free()

func save() -> void:
	#sets all of the settings in the main thingy based on what's in the menu
	Main.settings.indikator.kredit = kreditindikator.button_pressed
	Main.settings.indikator.multiplier = multiplierindikator.button_pressed
	Main.settings.daynight = daynight.button_pressed
	#actually save the game
	Main.savegame(true)
