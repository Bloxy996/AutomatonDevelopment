extends Control #script for the shop UI!
class_name Shop

@onready var creatorB: Button = $container/creator/creator
@onready var sellerB: Button = $container/seller/seller
@onready var beltB: Button = $container/belt/belt
@onready var multiplierB: Button = $container/multiplier/multiplier

func _ready() -> void: #runs when the game first appears on your screen
	visible = false #hide the shop

func _process(_delta: float) -> void: #sets the prices on the buttons to what the prices are
	creatorB.text = str(round(Main.prices['kreator']), ' kredits')
	sellerB.text = str(round(Main.prices['seller']), ' kredits')
	beltB.text = str(round(Main.prices['belt']), ' kredits')
	multiplierB.text = str(round(Main.prices['multiplier']), ' kredits')

func _input(_event: InputEvent) -> void: #runs when the user presses something
	if Input.is_action_just_pressed("tab") and (not Main.building) and (not Main.irradicating): #if the user presed the 'tab' key,
		visible = not visible #show/hide the shop!
		if visible: Main.savegame()
		
		if Main.tutorial_progress == 5: #move onto the next tutorial text
			Main.tutorial_progress += 1

func _on_button_pressed() -> void: #runs when the user preses the button to hide the shop
	visible = false #I think you know where this is going, hide the shop!

func _on_creator_pressed() -> void: #runs when the player presses the button to buy a kreator
	if Main.kredits >= Main.prices['kreator']:
		add_machine('kreator')

func _on_seller_pressed() -> void: #runs when the player presses the button to buy a seller
	if Main.kredits >= Main.prices['seller']:
		add_machine('seller')

func _on_belt_pressed() -> void: #runs when the player presses the button to buy a konveyor belt
	if Main.kredits >= Main.prices['belt']:
		add_machine('belt')

func _on_multiplier_pressed() -> void: #runs when the player presses the button to buy a multiplier
	if Main.kredits >= Main.prices['multiplier']:
		add_machine('multiplier')

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
