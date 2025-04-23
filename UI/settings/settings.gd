extends Control
class_name Settings

@onready var kreditindikator: CheckButton = $indikators/container/kredits/kreditindikator
@onready var multiplierindikator: CheckButton = $indikators/container/multipliers/multiplierindikator
@onready var daynight: CheckButton = $daynight/daynight
@onready var slider: HSlider = $HSlider
@onready var sliderlabel: Label = $Label

func _ready() -> void:
	#update all the settings based on what is already in the main thingy
	kreditindikator.button_pressed = Main.settings.indikator.kredit
	multiplierindikator.button_pressed = Main.settings.indikator.multiplier
	daynight.button_pressed = Main.settings.daynight
	slider.value = Main.settings.sunvalue
	if daynight.button_pressed:
		slider.visible = false
		sliderlabel.visible = false
	else:
		slider.visible = true
		sliderlabel.visible = true

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
	Main.settings.sunvalue = slider.value
	#actually save the game
	Main.savegame(true)

func _on_daynight_pressed() -> void:
	if daynight.button_pressed:
		slider.visible = false
		sliderlabel.visible = false
	else:
		slider.visible = true
		sliderlabel.visible = true

func returntime() -> Dictionary:
	var timecalc: float = slider.value - fmod(slider.value, 60) #subtracts seconds from time
	var timedict: Dictionary = { 'hr' : 0, 'min' : 0 }
	timedict['min'] = int(fmod(timecalc, 3600) / 60)
	timecalc = timecalc - fmod(timecalc, 3600)
	timedict['hr'] = int((timecalc / 3600))
	return timedict


func _on_h_slider_value_changed(_value: float) -> void:
	if returntime()['min'] < 10:
		sliderlabel.text = str(returntime()['hr']) + ":0" + str(returntime()['min'])
	else:
		sliderlabel.text = str(returntime()['hr']) + ":" + str(returntime()['min'])
