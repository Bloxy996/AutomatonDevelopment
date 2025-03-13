extends StaticBody3D #this is the skript for the seller!
class_name Seller

@export var original: bool = false #if it's the original or not

@onready var area: Area3D = $Area3D
@onready var collision2: CollisionShape3D = $Area3D/CollisionShape3D2
@onready var timer: Timer = $Timer
@onready var holder: Marker3D = $holder
@onready var button: Button = $holder/Button
@onready var pause: Button = $holder/pause
@onready var area2: Area3D = $Area3D2
@onready var boxholder: Marker3D = $boxholder
@onready var animation: AnimationPlayer = $boxholder/AnimationPlayer
@onready var collision: CollisionShape3D = $blocker/CollisionShape3D
@onready var light: MeshInstance3D = $light
@onready var pauselight: MeshInstance3D = $pause

var offer_avaliable: bool = false #true when a offer is available and YOU arent getting the box
var empty: bool = true #true when the seller is ready to sell a box

var box: RigidBody3D #varible for the box

func _ready() -> void:
	light.material_override = load("res://objekts/seller/redlight.tres") #machine is inactive

func _process(_delta: float) -> void: #runs every microsecond because of how fast your computer is
	area.collision_mask = 1
	#moves the label and the button over the seller
	button.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (button.size / 2)
	pause.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position + Vector3.DOWN) - (pause.size / 2)
	
	if empty: #run this if it's actually looking for stuff to grab
		for body: Node3D in area.get_overlapping_bodies(): #iterates through all the thingies, ANYTHING that is near the intake
			if body is Box and pause.text == 'pause': #if the thingy is a box and the machine is unpaused,
				if (not box_inmultiplier(body)) and body.get_parent().name == 'boxes': #if the box is not inside a multiplier and if there is no selling stuff going on and it's avaliable for the picking,
					#grab the box to send it to it's utter demise and end the loop
					grab_box(body)
					break
	
	if offer_avaliable: #if the machine is waiting for the player to accept a offer
		if area2.get_overlapping_bodies().has(Main.main.get_node('player')): #if the player is near the seller
			#show the button to accept the offer and hide the other button
			button.show() ##maybe show how much the box is selling for
		else:
			#vice versa!
			button.hide()
	
	collision.disabled = empty #blocker appears when there is something in the machine to stop overflow
	if not original:
		collision2.disabled = false
	
	if area2.get_overlapping_bodies().has(Main.main.get_node('player')) and (not original) and (not Main.building) and (not Main.irradicating): #if player is near button and not original
		pause.visible = true #show button
	else: 
		pause.visible = false #hide button
	
	#set the light to the pause state
	pauselight.material_override = load("res://objekts/pausedlight.tres") if pause.text != 'pause' else load("res://objekts/unpausedlight.tres")

func box_inmultiplier(body: Box) -> bool: #just makes sure that the box is not being pulled by a multiplier
	for boxarea: Area3D in body.detector.get_overlapping_areas():
		if boxarea.is_in_group('inmultiplier'): #the multipliers are in this group to check
			return true
	return false

func _on_timer_timeout() -> void: #runs when that offer finally comes up
	light.material_override = load("res://objekts/seller/redlight.tres") #machine is inactive
	
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
		##price goes down and demand goes up (or is just fluctuates (like 'good' sales make price go up and 'bad' sales make it go down))
		Main.sell_box(Main.progression_price * box.price) #runs the function in the master branch to sell the box
		box.queue_free() #remove the box because it was actually just going to get deleted forever and get turned into money, that 'customer' dosent actually exist
		empty = true #tells everyone else that its ready to pick up more boxes
		
		if Main.tutorial_progress == 3: #move onto the next tutorial text
			Main.tutorial_progress += 1

func grab_box(body: Node3D) -> void: #function to grab boxes
	empty = false #tells this function that the machine has a box in it
	box = body #set the box varible to the 'thing'
	box.reparent(boxholder) #move the box to the node for the seller to take it away into the glorious light of modern society
	#all of this is to get the box from escaping the grasp of the seller's reach
	box.top_level = false
	box.freeze = true
	box.global_position = boxholder.global_position
	box.global_rotation = boxholder.global_rotation
	timer.wait_time = randf_range(Main.progression_demand - 2, Main.progression_demand + 2)
	timer.start() #start the timer to wait for a customer
	#show the waiting label and set it to something that let's the user know that they should wait
	animation.play("set") #do the fancy animation for grabbing the box
	light.material_override = load("res://objekts/seller/greenlight.tres") #machine is active
	
	if Main.tutorial_progress == 2: #move onto the next tutorial text
		Main.tutorial_progress += 1

func sell_box() -> void: #sell ze box
	offer_avaliable = false #make sure that everyone knows that you accepted the offer (you cannot rejekt free money)
	button.hide() #hide the button for it's own sake
	Global._updateleaderboard()
	animation.play("sell") #play the fancy animation to take the box to it's majestik future

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'original' : original,
		'paused' : pause.text
	}

func _on_pause_pressed() -> void:
	pause.release_focus()
	if area2.get_overlapping_bodies().has(Main.main.get_node('player')): #if you're near the machine
		if pause.text == "pause": #if seller not paused
			pause.text = "resume" #change button text
		else:
			pause.text = "pause"
