extends RigidBody3D #this script is for the box
class_name Box

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var marker: Marker3D = $Marker3D
@onready var detector: Area3D = $detector

@onready var hand_node: Node3D = Main.main.get_node("player/CollisionShape3D/hand")

var onmouse: bool = false #varible for when the mouse is on the box

var price: float = 1

var used_multipliers: Array = [StaticBody3D]

var vel: Vector3

var detector_overlapping_areas: Array

var parent: Node3D

func update_overlaps() -> void:
	##pls dont run this on every frame
	detector_overlapping_areas = detector.get_overlapping_areas()

func _process(delta: float) -> void: #runs every nanosecond because this is a fast computer
	update_overlaps()
	parent = get_parent()
	
	if Main.picked and parent.name == "hand": #if the box is picked up and it's actually in the player's hand
		global_position = lerp(global_position, parent.global_position, delta * Main.grabspeed) #move the position to the player's hand, but lerp it
		global_rotation = parent.global_rotation #keep original rotations as the hand
		collision.disabled = true
		top_level = true
	else:
		collision.disabled = false
		top_level = false
	
	##boxes are just removed if they fall out, this check may be causing too much lag
	if global_position.y < -2: queue_free()
	
	if being_used():
	#	sleeping = true
		if linear_velocity != vel:
			linear_velocity = vel
	#else:
	#	sleeping = false
	vel = Vector3.ZERO

func being_used() -> bool:
	for area: Area3D in detector_overlapping_areas:
		if area.is_in_group('usingbox'): return true
	return false

func _on_mouse_entered() -> void: #runs when the mouse touches the box
	onmouse = true #self explainatory

func _on_mouse_exited() -> void: #runs when the mouse leaves the box
	onmouse = false #self explainatory

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton): return
	if onmouse and global_position.distance_to(Main.main.player.global_position) < Main.grabdist:
		if event.is_action_pressed('leftclick'): #when the player presses the button to pick it up
			if parent != hand_node:
				if not Main.picked: #if the player isnt already holding a box and the box isnt in the hand
					reparent(hand_node) #move the box to the player's hand
					Main.picked = true #tell ze master branch that the player has already picked up something so it dosent pick up something else
					#keep the box from doing goofy ahh stuff like flying around
					freeze = true
			else:
				dropbox()
		##i dont like how the tutorial is here, but it's ok i guess
		elif event.is_action_pressed('rightclick') and Main.kredits >= Main.deleteboxcost and Main.main.ui.tutorial.box != self:
			dropbox() #drop and remove the box when the user clicks to remove it
			Main.kredits -= Main.deleteboxcost #take away money
			
			#indicate the change of kredits
			if Main.settings.indikator.kredit:
				var indkinst: Indikator = indikator.instantiate()
				Main.main.ui.kreditindikator.add_child(indkinst)
				indkinst.start(-Main.deleteboxcost, global_position)
			
			queue_free()

func dropbox() -> void: #drop a box
	Main.picked = false #tell ze master branch that the player is capable of picking up boxes again!
	freeze = false #let the box go back to doing it's goofy ahh stuff
	
	if parent == Main.main.boxes:
		return
	reparent(Main.main.boxes) #send the box back to where it came from because it's useless now

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'price' : price
	}

func primaryload(data : Dictionary) -> void: #load before the node is institnated
	if data.has('price'): price = data['price']

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
