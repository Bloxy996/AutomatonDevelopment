extends RigidBody3D #this script is for the box
class_name Box

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var marker: Marker3D = $Marker3D
@onready var pickup: Button = $"Marker3D/pick up"
@onready var drop: Button = $Marker3D/drop
@onready var label: Label = $Marker3D/Label
@onready var forceapplier: Marker3D = $forceapplier

var player_position: Vector3 #varible for player position

var onmouse: bool = false #varible for when the mouse is on the box

var price: int = 1

var used_multipliers: Array = [StaticBody3D] ##find out how to save this

func _process(delta: float) -> void: #runs every nanosecond because this is a fast computer
	player_position = Main.main.get_node('player').global_position #set the player position to the actual player position
	collision.disabled = false
	
	#these 2 lines of code just put the buttons over the box and that's all I'm going to say
	pickup.global_position = get_viewport().get_camera_3d().unproject_position(marker.global_position) - (pickup.size / 2)
	drop.global_position = get_viewport().get_camera_3d().unproject_position(marker.global_position) - (drop.size / 2)
	label.global_position = get_viewport().get_camera_3d().unproject_position(marker.global_position) - (label.size / 2) + Vector2(5, 30)
	label.text = str('x', price)
	
	if onmouse and get_parent().name != 'boxholder' and global_position.distance_to(player_position) <= 2 and Main.picked == false: #if the box is ready to pick up (mouse is on it, it's not inside of a seller, its close enough to the player, and the player has not picked it up)
		pickup.show() #show button to pick the box up
		drop.hide() #hide the button to drop the box
	elif Main.picked == true and get_parent().name == "hand": #if the box is picked up and it's actually in the player's hand
		global_position = lerp(global_position, get_parent().global_position, delta * 16) #move the position to the player's hand, but lerp it
		global_rotation = get_parent().global_rotation #keep original rotations as the hand
		pickup.hide() #hide the pick up button
		drop.show() #show the drop button
		collision.disabled = true
	else:
		#hide both buttons to keep the screen from being cluttered with buttons
		pickup.hide()
		drop.hide()
	
	label.visible = onmouse and global_position.distance_to(player_position) <= 2 #show the price only when near the box and the mouse is on it
	
	#boxes are just removed if they fall out
	if global_position.y < -2: queue_free()
	
	#a node to reference to when applying forces from a belt or something
	forceapplier.global_position = global_position + Vector3(0, -0.25, 0)

func _on_mouse_entered() -> void: #runs when the mouse touches the box
	onmouse = true #self explainatory

func _on_mouse_exited() -> void: #runs when the mouse leaves the box
	onmouse = false #self explainatory

func _on_pick_up_pressed() -> void: #when the player presses the button to pick it up
	reparent(Main.main.get_node('player/CollisionShape3D/hand')) #move the box to the player's hand
	#set the position/rotation to the hand
	global_position = get_parent().global_position
	global_rotation = get_parent().global_rotation
	Main.picked = true #tell ze master branch that the player has already picked up something so it dosent pick up something else
	#keep the box from doing goofy ahh stuff like flying around
	freeze = true
	top_level = true
	
	if Main.tutorial_progress == 1: #move onto the next tutorial text
		Main.tutorial_progress += 1

func _on_drop_pressed() -> void: #when the player presses the button to drop it
	dropbox() #drops the box from the player

func dropbox() -> void: #drop a box
	reparent(Main.main.get_node('boxes')) #send the box back to where it came from because it's useless now
	Main.picked = false #tell ze master branch that the player is capable of picking up boxes again!
	freeze = false #let the box go back to doing it's goofy ahh stuff

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'parent' : Main.main.get_path_to(get_parent()),
		'rotY' : global_rotation.y,
		'posX' : global_position.x,
		'posY' : global_position.y,
		'posZ' : global_position.z,
		'price' : price
	}

func _on_delete_pressed() -> void:
	dropbox(); queue_free() #drop and remove the box when the user clicks to remove it
