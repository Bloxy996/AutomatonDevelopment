extends Control
class_name Tutorial

@onready var text: RichTextLabel = $text
@onready var basic: RichTextLabel = $text/basic

@onready var originalcreator: Kreator = $"../../machines/originalcreator"
@onready var originalseller: Seller = $"../../machines/originalseller"
@onready var shop: Shop = $"../Shop"

var texts: Array[String] = [ #all of the tutorial texts
"walk over to this machine, this is a kreator
press create a box to create a box",

"after a few seconds, a box should appear
pick it up by left clicking on it",

"walk over to the seller machine, and drop the box in it by left clicking on the box over it
if you want you can delete the box you can right click on it (costs 5 kredits)",

"the light turns green; when it turns red again, an offer is available
press click to sell to sell the box when it does",

"you get kredits and 1 XP for every box you sell
repeat this process manually until you get enough kredits, I'll notify you",

"you can now buy your first automated machine!
press tab or press add machines to open the shop",

"you can choose a machine that you have enough kredits to buy
buy a seller so you can place it near your creator
make sure to read the machine descriptions!",

"the blue shadow follows your mouse, and you can left click to place your machine; you can press R to rotate the machine if you want
later on you can right click to remove machines and press escape to stop building",

"if you want, you can press the delete machines button or the delete key to remove machines
have fun making your factory! press T to close the tutorial"
]

var progress: int = 0 #how much progress is made through the tutorial

var box: Box

func _process(_delta: float) -> void:
	text.global_position = [ #sets the positions based on what stage of the tutorial the user is on
		get_viewport().get_camera_3d().unproject_position(originalcreator.global_position + Vector3.DOWN) - (text.size / 2),
		Vector2(8, get_viewport().size.y - 95),
		Vector2(8, get_viewport().size.y - 140),
		get_viewport().get_camera_3d().unproject_position(originalseller.global_position + Vector3.DOWN) - (text.size / 2),
		Vector2(8, get_viewport().size.y - 140),
		Vector2(8, get_viewport().size.y - 140),
		Vector2(8, get_viewport().size.y - 140),
		Vector2(8, get_viewport().size.y - 140),
		Vector2(8, get_viewport().size.y - 140)
	][progress]
	
	text.text = "[center]" + texts[progress] #sets the text on the tutorial
	
	if progress == 0: #create a box
		originalcreator.createbox.pressed.connect(func() -> void:
			progress = 1
			basic.hide()
			
			while not is_instance_valid(originalcreator.inst): await get_tree().process_frame
			box = originalcreator.inst
		)
	
	elif progress == 1: #pick up the box
		while not Main.picked: await get_tree().process_frame
		progress = 2
	
	elif progress == 2: #drop the box in the seller
		while not box.get_parent() == originalseller.boxholder: await get_tree().process_frame
		progress = 3
	
	elif progress == 3: #press the sell box button
		originalseller.button.pressed.connect(func() -> void:
			progress = 4
		)
	
	elif progress == 4: #get enough credits to buy a seller
		while Main.kredits < Main.machinedata.seller.originalprice: await get_tree().process_frame
		progress = 5
	
	elif progress == 5: #open the shop
		while not shop.visible: await get_tree().process_frame
		progress = 6
	
	elif progress == 6: #buy a seller
		shop.container.get_node('seller/button').pressed.connect(func() -> void:
			progress = 7
		)
	
	elif progress == 7: #finish placing the seller
		while Main.building: await get_tree().process_frame
		progress = 8

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('end_tutorial'): #hides the tutorial and stops it from running if the user wants it to stop
		text.hide()
		set_process(false)
