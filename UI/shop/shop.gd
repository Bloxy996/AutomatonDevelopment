extends Control #script for the shop UI!
class_name Shop

@onready var container: VBoxContainer = $container/container

func _ready() -> void: #runs when the game first appears on your screen
	for panel: Panel in container.get_children(): #connects all the selling button stuff
		panel.get_node('button').connect('pressed', func() -> void: 
			if Main.kredits >= Main.prices[panel.name]:
				add_machine(panel.name)
		)
	
	visible = false #hide the shop

func _process(_delta: float) -> void: #sets the prices on the buttons to what the prices are
	for panel: Panel in container.get_children():
		panel.get_node('button').text = str('buy for ', round(Main.prices[panel.name]), ' kredits')

func _input(_event: InputEvent) -> void: #runs when the user presses something
	if Input.is_action_just_pressed("tab") and (not Main.building) and (not Main.irradicating): #if the user presed the 'tab' key,
		visible = not visible #show/hide the shop!
		if visible: Main.savegame()
		
		if Main.tutorial_progress == 5: #move onto the next tutorial text
			Main.tutorial_progress += 1
	
	if visible and Input.is_action_just_pressed("esc"): #esc shortcut to hide the shop
		Main.main.exitdelay.start() #start the timer so the pause menu dosent show
		hide()

func _on_exit_pressed() -> void: #runs when the user preses the button to hide the shop
	visible = false #I think you know where this is going, hide the shop!

func add_machine(type : String) -> void: #add a machine
	visible = false #hide the shop
	#create the machine, set it to the right type, and add it to the scene
	var inst: CreationShadow = load("res://shadow of the kreation/addshadow.tscn").instantiate()
	inst.type = type
	Main.main.get_node('machines').add_child(inst)
	
	if Main.tutorial_progress == 6: #move onto the next tutorial text
		Main.tutorial_progress += 1

func _on_create_pressed() -> void: #if the user presed the button to create a machine,
	Main.main.get_node("UI/create").release_focus()
	if (not Main.building) and (not Main.irradicating):
		visible = true #show the shop!
		
		if Main.tutorial_progress == 5: #move onto the next tutorial text
			Main.tutorial_progress += 1
