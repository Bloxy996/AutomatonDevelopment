extends StaticBody3D #this skript is for the kreator of kreators
class_name Kreator

@onready var area: Area3D = $Area3D
@onready var spawnbox: Marker3D = $spawnbox
@onready var animation_player: AnimationPlayer = $spawnbox/AnimationPlayer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var timer: Timer = $ProgressBar/Timer
@onready var automated: Timer = $ProgressBar/automated
@onready var buttonholder: Marker3D = $buttonholder
@onready var createbox: Button = $buttonholder/createbox
@onready var pause: Button = $buttonholder/pause
@onready var dooranim: AnimationPlayer = $door/AnimationPlayer

@export var original: bool = false #if it's the original or not

var inst: RigidBody3D #varible for creating new boxes because this is a creator and creators just do that

func _ready() -> void:
	set_process(false)
	await get_tree().create_timer(0.2).timeout
	set_process(true)

func _process(_delta: float) -> void: #runs every single nanosecond because your computer is super fast
	if area.get_overlapping_bodies().has(Main.main.get_node('player')) and original and get_tree().get_nodes_in_group('box').size() < Main.maxboxes: #if the player is near the kreator and there's not too much boxes
		createbox.visible = spawnbox.get_child_count() < 2 ##if there are no boxes inside of the creator show button to create box, maybe show either way?
	else:
		createbox.hide() #hide ze button

	if (area.get_overlapping_bodies().has(Main.main.get_node('player')) or pause.text == 'resume') and not original: #if the player nears the creator
		pause.visible = true #show button
	else:
		pause.visible = false
	
	createbox.global_position = get_viewport().get_camera_3d().unproject_position(buttonholder.global_position) - (createbox.size / 2) #move the create box button over the kreator
	pause.global_position = get_viewport().get_camera_3d().unproject_position(buttonholder.global_position) - (pause.size / 2) #move the pause button over the kreator
	progress_bar.global_position = createbox.global_position + Vector2(0, 40) #place the waiting bar under the button
	progress_bar.visible = not timer.is_stopped() #hide the bar if there is nothing to wait for
	
	if original:
		progress_bar.visible = not timer.is_stopped() #hide the bar if there is nothing to wait for
		progress_bar.value = timer.time_left #set the bar to the time left that needs to be waited
		progress_bar.max_value = timer.wait_time #set the max value to the wait time
	else: #same thing as above, but just for the automated timer
		progress_bar.visible = not automated.is_stopped()
		progress_bar.value = automated.time_left
		progress_bar.max_value = automated.wait_time
	
	area.collision_mask = 1 #keep it from lagging, a godot thing
	
	if pause.text == 'pause': #if the machine is unpaused
		#iterates through all the boxes still in the kreator and inactive
		for node: Node in spawnbox.get_children():
			if node is Box and (not node.freeze) and node.top_level:
				send_to_belt(node)
				break
		
		##if you actually paid for this kreator and there are under 1 boxes in it, start the automated timer to make another box (change to under 2?)
		if (not original): #also makes sure that the machine isnt in the queue already
			if spawnbox.get_child_count() < 2 and automated.is_stopped() and not Main.main.boxkreationqueue.has(self): #getchildcount includes the animplayer
				Main.main.boxkreationqueue.append(self) #add a request to the queue to generate boxes

func request_accepted() -> void: #when the kreators's desires have been accepted
	automated.start() #start the timer to make a box
	dooranim.play_backwards('open') #close the doors

func _on_createbox_pressed() -> void: #runs when the create box button is pressed
	timer.start() #begin the timer to wait
	dooranim.play_backwards('open') #close the doors
	if Main.tutorial_progress == 0: #move onto the next tutorial text
		Main.tutorial_progress += 1

func _on_timer_timeout() -> void: #when the waiting time ends and the box is ready, create a box
	create_box()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void: #when the fancy animation is finished
	if inst.get_parent().name != 'hand': #if a mischevious player didnt already pick up the box WHILE THE BOX WAS IN THE ANIMATION,
		#unstatcify the box
		inst.freeze = false
		inst.top_level = true

func send_to_belt(box : RigidBody3D) -> void: #sends boxes to any belt near the kreator
	#if any of the nodes near the kreator is a konveyor belt and it dosent have a box,
	for node: Node in area.get_overlapping_bodies():
		if node is Belt and not node.has_box:
			box.global_position = node.global_position + Vector3.UP #move the new box over to the konveyor belt
			box.reparent(Main.main.get_node('boxes')) #send the box to the global box node so you can move it around
			break #end this twisted loop to save on time

func _on_automated_timeout() -> void: #if the automated timer ends,
	if not original: #if the kreator is actually an automated one, create a box
		create_box()

func create_box() -> void:
	inst = load('res://objekts/box/box.tscn').instantiate() #set the box varible to a box
	spawnbox.add_child(inst) #create the box from the ashes of a lost world and put it in the scene
	#make the box static
	inst.freeze = true
	inst.top_level = false
	dooranim.play('open') #open the doors
	animation_player.play("spawn") #play the spawn animation for fancy stuff

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'parent' : Main.main.get_path_to(get_parent()),
		'rotY' : global_rotation.y,
		'posX' : global_position.x,
		'posY' : global_position.y,
		'posZ' : global_position.z,
		'original' : original,
		'paused' : pause.text
	}

func _on_pause_pressed() -> void:
	pause.release_focus()
	if area.get_overlapping_bodies().has(Main.main.get_node('player')): #if you're near the machine
		automated.paused = !automated.paused #sets true to false and false to true
		if automated.paused: #if player paused it
			pause.text = "resume" #change text
		else: #if player resumed it
			pause.text = "pause" #change text
