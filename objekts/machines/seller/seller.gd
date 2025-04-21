extends CollisionShape3D
class_name Seller

@onready var pausedlight: StandardMaterial3D = preload("res://objekts/pausedlight.tres")
@onready var unpausedlight: StandardMaterial3D = preload("res://objekts/unpausedlight.tres")
@onready var redlight: StandardMaterial3D = preload("res://objekts/machines/seller/redlight.tres")
@onready var greenlight: StandardMaterial3D = preload("res://objekts/machines/seller/greenlight.tres")

@export var original: bool = false #if it's the original or not

@onready var area: Area3D = $Area3D
@onready var timer: Timer = $Timer
@onready var holder: Marker3D = $holder
@onready var button: Button = $holder/Button
@onready var pause: Button = $holder/pause
@onready var area2: Area3D = $Area3D2
@onready var boxholder: Marker3D = $boxholder
@onready var animation: AnimationPlayer = $boxholder/AnimationPlayer
@onready var light: MeshInstance3D = $light
@onready var pauselight: MeshInstance3D = $pause

var offer_avaliable: bool = false #true when a offer is available and YOU arent getting the box
var empty: bool = true #true when the seller is ready to sell a box

var box: RigidBody3D #varible for the box

var area_overlapping_bodies: Array
var area2_overlapping_bodies: Array

func _ready() -> void:
	if original: add_to_group("original") #add to original if original
	global_position.y = 0.299 #bring up the machine for aligning
	
	light.material_override = redlight #machine is inactive
	
	area2.body_entered.connect(func(body: Node3D) -> void:
		if body is Player and (not original) and (not Main.building) and (not Main.irradicating): pause.show())
	area2.body_exited.connect(func(body: Node3D) -> void:
		if body is Player: pause.hide())

func update_overlaps() -> void:
	area_overlapping_bodies = area.get_overlapping_bodies()
	area2_overlapping_bodies = area2.get_overlapping_bodies()

func update(_delta: float) -> void: #runs every microsecond because of how fast your computer is\
	update_overlaps()
	area.collision_mask = 1
	#moves the label and the button over the seller
	if button.visible: button.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (button.size / 2)
	if pause.visible: pause.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position + Vector3.DOWN) - (pause.size / 2)
	
	empty = not is_instance_valid(box) #it's empty if it dosent have a box!
	
	if empty: #run this if it's actually looking for stuff to grab
		for body: Node3D in area_overlapping_bodies: #iterates through all the thingies, ANYTHING that is near the intake
			if body is Box and pause.text == 'pause': #if the thingy is a box and the machine is unpaused,
				if (not box_inmultiplier(body)) and body.get_parent().name == 'boxes': #if the box is not inside a multiplier and if there is no selling stuff going on and it's avaliable for the picking,
					#grab the box to send it to it's utter demise and end the loop
					grab_box(body)
					break
	
	if offer_avaliable: #if the machine is waiting for the player to accept a offer
		if area2_overlapping_bodies.has(Main.main.player): #if the player is near the seller
			#show the button to accept the offer and hide the other button
			button.show() 
		else:
			#vice versa!
			button.hide()
	
	#set the light to the pause state
	pauselight.material_override = pausedlight if pause.text != 'pause' else unpausedlight

func box_inmultiplier(body: Box) -> bool: #just makes sure that the box is not being pulled by a multiplier
	for boxarea: Area3D in body.detector_overlapping_areas:
		if boxarea.is_in_group('inmultiplier'): #the multipliers are in this group to check
			return true
	return false

func _on_timer_timeout() -> void: #runs when that offer finally comes up
	light.material_override = redlight #machine is inactive
	
	if original: #if this is the original machine
		#tell the user that a offer is available, and set the varible for that to true
		offer_avaliable = true
	else:
		#hide the UI and sell the box
		sell_box()

func _on_button_pressed() -> void: #runs when the user decides that now is a great time to accept the offer that has been sitting there for years
	sell_box() #sell ze box

func _on_animation_player_animation_finished(anim_name: StringName) -> void: #when the fancy animation is done
	if anim_name == 'sell' and is_instance_valid(box): #if the animation was actually to take the box away
		Main.sell_box(Main.progression_price * box.price, global_position) #runs the function in the master branch to sell the box
		box.queue_free() #remove the box because it was actually just going to get deleted forever and get turned into money, that 'customer' dosent actually exist

func grab_box(body: Node3D) -> void: #function to grab boxes
	box = body #set the box varible to the 'thing'
	box.reparent(boxholder) #move the box to the node for the seller to take it away into the glorious light of modern society
	#all of this is to get the box from escaping the grasp of the seller's reach
	box.freeze = true
	box.global_position = boxholder.global_position
	box.global_rotation = boxholder.global_rotation
	timer.wait_time = randf_range(Main.progression_demand - Main.selltimediff, Main.progression_demand + Main.selltimediff)
	timer.start() #start the timer to wait for a customer
	#show the waiting label and set it to something that let's the user know that they should wait
	animation.play("set") #do the fancy animation for grabbing the box
	light.material_override = greenlight #machine is active

func sell_box() -> void: #sell ze box
	offer_avaliable = false #make sure that everyone knows that you accepted the offer (you cannot rejekt free money)
	button.hide() #hide the button for it's own sake
	Global._updateleaderboard()
	animation.play("sell") #play the fancy animation to take the box to it's majestik future

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'paused' : pause.text
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
	if data.has('paused'): pause.text = data['paused']

func _on_pause_pressed() -> void:
	pause.release_focus()
	if area2_overlapping_bodies.has(Main.main.player): #if you're near the machine
		if pause.text == "pause": #if seller not paused
			pause.text = "resume" #change button text
		else:
			pause.text = "pause"
