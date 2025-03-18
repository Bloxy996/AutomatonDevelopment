extends StaticBody3D
class_name Arm

@onready var targetnode: PackedScene = preload("res://objekts/arm/target/target.tscn")

@onready var skeletonIK: SkeletonIK3D = $Armature/Skeleton3D/SkeletonIK3D
@onready var target: Marker3D = $Target
@onready var boxAoE: Area3D = $boxAoE
@onready var settarget: Area3D = $settarget
@onready var holder: Node3D = $holder
@onready var settargetbutton: Button = $holder/settarget
@onready var proximity: Area3D = $proximity
@onready var alignleft: Marker3D = $Target/left
@onready var alignright: Marker3D = $Target/right
@onready var boxdetector: Area3D = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/detector
@onready var hand: Marker3D = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/robotichand
@onready var AoEmesh: MeshInstance3D = $mesh
@onready var fingeranim: AnimationPlayer = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/AnimationPlayer
@onready var targets: Node3D = $targets

var finaltargetpos: Vector3 = Vector3.ZERO ##the target where the arm should end up putting stuff, maybe make dynamic
var targetpos: Vector3 #the target the arm will lerp towards

var settingtarget: bool = false #if the user is setting the target
var grabstate: int = 0 #the stages of grabbing and dropping a box

var grabbed: Box #the box that is being grabbed

func _ready() -> void:
	skeletonIK.start() #start the ik thingy to go to the target

func _process(delta: float) -> void:
	boxAoE.collision_mask = 1 #godot thingy
	
	#sets the position and visibility of the button to set target
	settargetbutton.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (settargetbutton.size / 2)
	settargetbutton.visible = global_position.distance_to(Main.main.player.global_position) < 2.5 and (not Main.building) and (not Main.irradicating) and (not settingtarget)
	
	if settingtarget: #show all of the stuff to set the target if the user is setting a target
		AoEmesh.show()
		settarget.show()
		targets.show()
		settarget.global_position = snapped(Main.main.mouse_3d_pos(), Vector3.ONE)
		settarget.global_position.y = 0
	else: #hide everything if not
		AoEmesh.hide()
		settarget.hide()
		targets.hide()
	
	#keep it from pointing to the origin
	if targetpos.distance_to(Vector3.ZERO) == 0: 
		targetpos = global_position + Vector3(0, 3, 0.01)
		target.global_position = targetpos
	
	if finaltargetpos == Vector3.ZERO: #if there is no active target for the arm, get one!
		var avaliabletargets: Array[Vector3] #array for all the targets that the arm can go to
		for armtarget: ArmTarget in targets.get_children(): #iterates through all the targets
			var avaliable: bool = true #tempoarily variable
			for node: Node3D in armtarget.get_overlapping_bodies(): #iterates through everything in the area
				if node.is_in_group('machine'): ##if it's a machine, this is awfully specific, I dont like it (or just put it in main ig)
					if node is Seller and not node.empty: avaliable = false ##cannot put boxes on active sellers, also take pausing into account
					elif node is Kreator or node is Multiplier or node is SplitBelt: avaliable = false ##you cant put boxes into kreators or multipliers (make it so that you can put boxes onto splitbelts, I need the hasbox thingy on it)
					elif node is Belt and node.has_box: avaliable = false #you cant put boxes onto belts that have boxes already
			
			if avaliable: avaliabletargets.append(armtarget.global_position) #if it's available, add it to the available machines
		if not avaliabletargets.is_empty(): #if there are available targets to choose from, get one!
			finaltargetpos = avaliabletargets.pick_random() ##or pick the closest one
		
	else: #if there is an active target
		if grabstate == 0: #if the arm is looking to pick a box
			for node: Node3D in boxAoE.get_overlapping_bodies(): #search through all nodes in the area of effect
				#if it's a box in the main world and it dosent intersect with any targets
				if node is Box and node.get_parent().name == 'boxes' and not overlaps_targets(node):
						grabstate = 1 #a box has just been notified to be grabbed
						grabbed = node ##set grabbed to this box, or find a way to pick the closest box
		
		elif grabstate == 1 and grabbed and is_instance_valid(grabbed): #if a box to be grabbed exists
			#if the box is in the main world and it dosent intersect with any targets, and if it's inside the area of effect (if it's outside it should still be ungrabbed so) and the target still exists
			if grabbed.get_parent().name == 'boxes' and (not overlaps_targets(grabbed)) and (not ((not boxAoE.get_overlapping_bodies().has(grabbed)) and grabbed.get_parent() != hand)) and get_target_from_pos(finaltargetpos):
				targetpos = grabbed.global_position #move the arm towards it
				
				if boxdetector.get_overlapping_bodies().has(grabbed): #if the box is very, very close to the detector
					grabbed.reparent(hand) #put it onto the hand
					grabbed.top_level = true #keep it from escaping
					grabbed.freeze = true
					fingeranim.play('grab') #animation to grasp the box
					grabstate = 2 #next stage... bring the box to it's destination!
			else: #unselect the box if it's not viable
				unselect_box()
		
		elif grabstate == 2: #state where the the box is being brought to it's destination
			if grabbed.get_parent() == hand and get_target_from_pos(finaltargetpos): #if still on the arm (not grabbed by a player or seller or something) and the target still exists
				grabbed.global_transform = hand.global_transform #make the box being grabbed go to where the hand is
				targetpos = finaltargetpos + Vector3.UP #bring the arm towards the final destination
				if get_target_from_pos(finaltargetpos).get_overlapping_bodies().has(grabbed): #if the destination target has the box (it has been brought to it's destination)
					grabbed.reparent(Main.main.boxes) #put the box back into the world
					grabbed.top_level = false #allow it to escape
					grabbed.freeze = false
					unselect_box() #reset the arm's stuff
					fingeranim.play_backwards('grab') #release animation
			else: #unselect the box if it left
				fingeranim.play_backwards('grab') #release animation
				unselect_box()
	
	target.look_at(global_position) #point the target node at the machine so left/right are in the correct positions
	##sets which target to align to based on how close they are, maybe add an align target that is 'up' (above the target thingy), and also use this to make sure the arm dosent go through other objects too
	var aligntarget: Vector3 = alignleft.global_position if targetpos.distance_to(alignleft.global_position) < targetpos.distance_to(alignright.global_position) else alignright.global_position
	#move to either the actual target or the alignment target based on whether it's needed or not
	target.global_position = (lerp(target.global_position, aligntarget, delta * 2) if proximity.get_overlapping_areas().has(boxdetector) else lerp(target.global_position, targetpos, delta * 4))

func unselect_box() -> void: #when a box is being unselected
	grabbed = null #no more box to grab
	finaltargetpos = Vector3.ZERO #look for a new target
	grabstate = 0 #go back to searching phase

func get_target_from_pos(pos : Vector3) -> ArmTarget: #gets the target from a position
	for armtarget: ArmTarget in targets.get_children():
		if armtarget.global_position.distance_to(pos) < 0.5:
			return armtarget
	return null

func overlaps_targets(box : Box) -> bool: #if the box overlaps any of the arm's targets
	for area: Area3D in box.detector.get_overlapping_areas():
		if area is ArmTarget: return true ##maybe just this arm's targets?? (get children of 'targets' to do that)
	return false

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'targets' : armtargets()
	}

func armtargets(final: Array = []) -> Array: #just for saving
	for armtarget: ArmTarget in targets.get_children():
		final.append([armtarget.global_position.x, armtarget.global_position.z]) #technically I dont actually need the y value
	return final

##func primaryload(data : Dictionary) -> void: #load before the node is institnated
##	finaltargetpos = Vector3(data.finaltargetpos[0], data.finaltargetpos[1], data.finaltargetpos[2])

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
	global_rotation.y = data["transform"][3]
	
	for armtarget: Array in data.targets:
		var inst: ArmTarget = targetnode.instantiate()
		targets.add_child(inst)
		inst.global_position = Vector3(armtarget[0], 0, armtarget[1])

func _input(event: InputEvent) -> void:
	if settingtarget:
		if event.is_action_pressed('leftclick'): #if a target is set inside the area of effect
			if settarget.get_overlapping_areas().has(boxAoE): ##also make sure you cant put the target inside a wall, you should be able to put it over machines though so
				for area: Area3D in settarget.get_overlapping_areas():
					if area is ArmTarget:
						area.queue_free() #remove a target if the user selects one
						return #keep it from making a new one right after
				
				var inst: ArmTarget = targetnode.instantiate()
				targets.add_child(inst)
				inst.global_position = settarget.global_position
		
		elif event.is_action_pressed('esc'): #when the user is done
			Main.main.exitdelay.start() #start the timer so the pause menu dosent show
			settingtarget = false #disable the setting target thingy

func _on_settarget_pressed() -> void:
	#if the player presses to set a target, start the setting target process
	settargetbutton.release_focus()
	settingtarget = true

func flatten(vector : Vector3) -> Vector3:
	return Vector3(vector.x, 0, vector.z)
