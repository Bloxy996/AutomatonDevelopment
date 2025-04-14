extends StaticBody3D
class_name Arm

@onready var targetnode: PackedScene = preload("res://objekts/arm/target/target.tscn")
@onready var avoidnode: PackedScene = preload("res://objekts/arm/avoid/avoid.tscn")
@onready var prioritynode: PackedScene = preload("res://objekts/arm/priority/priority.tscn")

@onready var pausedlight: StandardMaterial3D = preload("res://objekts/pausedlight.tres")
@onready var unpausedlight: StandardMaterial3D = preload("res://objekts/unpausedlight.tres")
@onready var settargetmat: StandardMaterial3D = preload("res://objekts/arm/settarget.tres")
@onready var settargetidlemat: StandardMaterial3D = preload("res://objekts/arm/settargetidle.tres")

@onready var skeletonIK: SkeletonIK3D = $Armature/Skeleton3D/SkeletonIK3D
@onready var target: Marker3D = $Target
@onready var boxAoE: Area3D = $boxAoE
@onready var boxAoEcollision: CollisionShape3D = $boxAoE/CollisionShape3D
@onready var settarget: Area3D = $settarget
@onready var holder: Node3D = $holder
@onready var settargetbutton: Button = $holder/UIholder/settarget
@onready var proximity: Area3D = $proximity
@onready var alignleft: Marker3D = $Target/left
@onready var alignright: Marker3D = $Target/right
@onready var boxdetector: Area3D = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/detector
@onready var hand: Marker3D = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/robotichand
@onready var AoEmesh: MeshInstance3D = $mesh
@onready var fingeranim: AnimationPlayer = $Armature/Skeleton3D/Cube_001/Cube_001/grabber/AnimationPlayer
@onready var behaviours: Node3D = $behaviours
@onready var targets: Node3D = $behaviours/targets
@onready var avoids: Node3D = $behaviours/avoids
@onready var priorities: Node3D = $behaviours/priorities
@onready var UIholder: VBoxContainer = $holder/UIholder
@onready var pauselight: MeshInstance3D = $pause
@onready var pause: Button = $holder/UIholder/pause

var finaltargetpos: Vector3 = Vector3.ZERO #the target where the arm should end up putting stuff
var targetpos: Vector3 #the target the arm will lerp towards

var settingbehavior: bool = false #if the user is setting the target

enum GrabState { SEARCHING, GRABBING, MOVING }
var grabstate: GrabState = GrabState.SEARCHING

var grabbed: Box #the box that is being grabbed

var boxAoE_overlapping_bodies: Array
var boxdetector_overlapping_bodies: Array
var proximity_overlapping_areas: Array
var settarget_overlapping_bodies: Array
var settarget_overlapping_areas: Array

var target_children: Array
var priority_children: Array

func _ready() -> void:
	skeletonIK.start() #start the ik thingy to go to the target
	update_children()

func update_overlaps() -> void:
	##this is slow, dont constantly call this
	boxAoE_overlapping_bodies = boxAoE.get_overlapping_bodies()
	boxdetector_overlapping_bodies = boxdetector.get_overlapping_bodies()
	proximity_overlapping_areas = proximity.get_overlapping_areas()
	settarget_overlapping_bodies = settarget.get_overlapping_bodies()
	settarget_overlapping_areas = settarget.get_overlapping_areas()

func update_children() -> void:
	await get_tree().create_timer(0.5).timeout
	target_children = targets.get_children()
	priority_children = priorities.get_children()

func _process(delta: float) -> void:
	var targ_from_finalpos: ArmTarget = get_target_from_pos(finaltargetpos)
	var finalpos_overlapping_bodies: Array = targ_from_finalpos.get_overlapping_bodies() if is_instance_valid(targ_from_finalpos) else []
	update_overlaps()
	
	boxAoE.collision_mask = 1 #godot thingy
	
	#sets the position and visibility of the button to set target
	UIholder.visible = global_position.distance_to(Main.main.player.global_position) < boxAoEcollision.shape.radius and (not Main.building) and (not Main.irradicating) and (not Main.settingbehavior)
	if UIholder.visible: UIholder.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (UIholder.size / 2)
	
	if settingbehavior: #show all of the stuff to set the target if the user is setting a target and the user is close
		AoEmesh.show()
		if boxAoE_overlapping_bodies.has(Main.main.player):
			behaviours.show()
			AoEmesh.material_override = settargetmat
			#moves the targeting thingy to the mouse
			settarget.global_position = snapped(Main.main.mouse3Dpos, Vector3.ONE)
			settarget.global_position.y = 0
		else:
			behaviours.hide()
			AoEmesh.material_override = settargetidlemat
	else: #hide everything if not
		AoEmesh.hide()
		behaviours.hide()
	
	#keep it from pointing to the origin
	if targetpos.distance_to(Vector3.ZERO) == 0: 
		targetpos = global_position + Vector3(0, 3, 0.01)
		target.global_position = targetpos
	
	if pause.text == 'pause': #if not paused
		if finaltargetpos.length_squared() < 0.0001: #if there is no active target for the arm, get one!
			var avaliabletargets: Array[Vector3] #array for all the targets that the arm can go to
			for armtarget: ArmTarget in target_children: #iterates through all the targets
				var avaliable: bool = true #tempoarily variable
				avaliable = armtarget.get_overlapping_bodies().filter(func(node: Node3D) -> bool: #iterates through everything in the area
					return node.is_in_group('machine') and not_viable_target(node)).is_empty() #if it's a machine
				
				if avaliable: avaliabletargets.append(armtarget.global_position) #if it's available, add it to the available machines
			if not avaliabletargets.is_empty(): #if there are available targets to choose from, get one!
				finaltargetpos = avaliabletargets.pick_random()
			
		else: #if there is an active target
			if is_instance_valid(targ_from_finalpos): #if there's a targeter at the position
				for node: Node3D in finalpos_overlapping_bodies: #checks to make sure the current target is still viable
					if not_viable_target(node): finaltargetpos = Vector3.ZERO; break
			else: unselect_box() #if there's no targeter, there's nothing there to go to!!
			
			if grabstate == GrabState.SEARCHING: #if the arm is looking to pick a box
				for priority: ArmPriority in priority_children: #iterates through boxes in priority first
					search_for_boxes(priority)
					if grabstate == GrabState.GRABBING: break
				if grabstate == GrabState.SEARCHING: #if there's no priority boxes
					search_for_boxes(boxAoE)
			
			elif grabstate == GrabState.GRABBING and grabbed and is_instance_valid(grabbed): #if a box to be grabbed exists
				#if the box is in the main world and it dosent intersect with any targets, and if it's inside the area of effect (if it's outside it should still be ungrabbed so) and the target still exists
				if grabbed.get_parent() == Main.main.boxes and (not overlaps_targets(grabbed)) and (not overlaps_avoids(grabbed)) and (not box_inmultiplier(grabbed)) and boxAoE_overlapping_bodies.has(grabbed) and targ_from_finalpos:
					targetpos = grabbed.global_position #move the arm towards it
					
					if boxdetector_overlapping_bodies.has(grabbed): #if the box is very, very close to the detector
						grabbed.reparent(hand) #put it onto the hand
						grabbed.freeze = true
						fingeranim.play('grab') #animation to grasp the box
						grabstate = GrabState.MOVING #next stage... bring the box to it's destination!
				else: #unselect the box if it's not viable
					unselect_box()
			
			elif grabstate == GrabState.MOVING: #the the box is being brought to it's destination
				if is_instance_valid(grabbed) and grabbed.get_parent() == hand and targ_from_finalpos: #if still on the arm (not grabbed by a player or seller or something) and the target still exists
					grabbed.global_transform = hand.global_transform #make the box being grabbed go to where the hand is
					targetpos = finaltargetpos + Vector3.UP #bring the arm towards the final destination
					if finalpos_overlapping_bodies.has(grabbed): #if the destination target has the box (it has been brought to it's destination)
						unselect_box() #reset the arm's stuff
						fingeranim.play_backwards('grab') #release animation
				else: #unselect the box if it left
					fingeranim.play_backwards('grab') #release animation
					unselect_box()
	
		target.look_at(global_position) #point the target node at the machine so left/right are in the correct positions
		#sets which target to align to based on how close they are
		var aligntarget: Vector3 = alignleft.global_position if targetpos.distance_to(alignleft.global_position) < targetpos.distance_to(alignright.global_position) else alignright.global_position
		#move to either the actual target or the alignment target based on whether it's needed or not
		target.global_position = (lerp(target.global_position, aligntarget, delta * (Main.armspeed / 2)) if proximity_overlapping_areas.has(boxdetector) else lerp(target.global_position, targetpos, delta * Main.armspeed))
	
	#set the light to the pause state
	pauselight.material_override = pausedlight if pause.text != 'pause' else unpausedlight

func not_viable_target(node : Node3D) -> bool: #if the target is viable
	if node is Seller and (not node.empty) and node.pause.text == 'pause': return true #cannot put boxes on active sellers or if theyre paused
	elif node is Kreator or node is Multiplier: return true #you cant put boxes into kreators or multipliers
	elif (node is Belt or node is SplitBelt) and node.has_box: return true #you cant put boxes onto belts that have boxes already
	return false

func search_for_boxes(area: Area3D) -> void:
	for node: Node3D in (area.get_overlapping_bodies() if area != boxAoE else boxAoE_overlapping_bodies):
		#if it's a box in the main world and it dosent intersect with any targets/avoids/multipliers
		if not (node is Box and node.get_parent() == Main.main.boxes): continue
		if overlaps_targets(node) or overlaps_avoids(node) or box_inmultiplier(node): continue
		grabstate = GrabState.GRABBING #a box has just been notified to be grabbed
		grabbed = node #set grabbed to this box
		return

func box_inmultiplier(body: Box) -> bool: #just makes sure that the box is not being pulled by a multiplier
	for boxarea: Area3D in body.detector_overlapping_areas:
		if boxarea.is_in_group('inmultiplier'): #the multipliers are in this group to check
			return true
	return false

func unselect_box() -> void: #when a box is being unselected
	if is_instance_valid(grabbed) and grabbed.get_parent() == hand: #if the box is being held by the arm
		grabbed.reparent(Main.main.boxes) #put the box back into the world
		grabbed.freeze = false
	
	grabbed = null #no more box to grab
	finaltargetpos = Vector3.ZERO #look for a new target
	targetpos = global_position + Vector3(0, 3, 0.001) #make the arm go up so it's not in the way of anything
	grabstate = GrabState.SEARCHING #go back to searching phase

func get_target_from_pos(pos : Vector3) -> ArmTarget: #gets the target from a position
	for armtarget: ArmTarget in target_children:
		if armtarget.global_position.distance_to(pos) < 0.5:
			return armtarget
	return null

func overlaps_targets(box : Box) -> bool: #if the box overlaps any of the arm's targets
	for area: Area3D in box.detector_overlapping_areas:
		if area is ArmTarget: return true #does all targets so the arms can work in harmony! (hopefully I dont regret this)
	return false

func overlaps_avoids(box : Box) -> bool: #if the box overlaps any of the arm's avoid thingies
	for area: Area3D in box.detector_overlapping_areas:
		if area.get_parent() == avoids: return true #gets just this arm's avoids
	return false

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'targets' : armnodes(targets),
		'avoids' : armnodes(avoids),
		'priorities' : armnodes(priorities),
		'paused' : pause.text,
		'targetpos' : [targetpos.x, targetpos.y, targetpos.z]
	}

func armnodes(parent: Node3D, final: Array = []) -> Array: #just for saving
	for node: Node3D in parent.get_children():
		final.append([node.global_position.x, node.global_position.z]) #technically I dont actually need the y value
	return final

func primaryload(data : Dictionary) -> void: #load before the node is institnated
	if data.has('targetpos'): targetpos = Vector3(data.targetpos[0], data.targetpos[1], data.targetpos[2])

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
	if data.has('paused'): pause.text = data['paused']
	
	if data.has('targets') and data.has('avoids') and data.has('priorities'):
		for savedbehaviours: Array in [
			[data.targets, targets, targetnode], 
			[data.avoids, avoids, avoidnode], 
			[data.priorities, priorities, prioritynode]
		]: 
			for behaviour: Array in savedbehaviours[0]:
				var inst: Area3D = savedbehaviours[2].instantiate()
				savedbehaviours[1].add_child(inst)
				inst.global_position = Vector3(behaviour[0], 0, behaviour[1])

func _input(event: InputEvent) -> void:
	if settingbehavior: #stuff for adding the behaviour area thingies
		if event.is_action_pressed('armtarget'): add_behaviours(targetnode, targets)
		elif event.is_action_pressed('armavoid'): add_behaviours(avoidnode, avoids)
		elif event.is_action_pressed('armprioritization'): add_behaviours(prioritynode, priorities)
		elif event.is_action_pressed('esc'): #when the user is done
			Main.main.exitdelay.start() #start the timer so the pause menu dosent show
			settingbehavior = false #disable the setting target thingy
			Main.settingbehavior = false #other arms can set their behaviours now

func add_behaviours(node : PackedScene, parent : Node3D) -> void:
	if settarget_overlapping_areas.has(boxAoE): #if the target setter thingy is inside the area of effect
		for check: Node3D in settarget_overlapping_bodies:
			if check.is_in_group('wall'): return #stops adding behaviours if the area is colliding with a wall
		
		for area: Area3D in settarget_overlapping_areas:
			if area.get_parent() == targets or area.get_parent() == avoids or  area.get_parent() == priorities:
				area.queue_free() #remove a behaviour if the user selects one
				if area.get_parent() == parent: return #keep it from making a new one right after if it's another arm behaviour
		
		#add it
		var inst: Area3D = node.instantiate()
		parent.add_child(inst)
		inst.global_position = settarget.global_position

func _on_settarget_pressed() -> void:
	Main.settingbehavior = true #make sure that only one arm can set it's behaviours at a time
	#if the player presses to set a target, start the setting target process
	settargetbutton.release_focus()
	settingbehavior = true

func _on_pause_pressed() -> void:
	#toggle pausing
	pause.release_focus()
	pause.text = 'resume' if pause.text == 'pause' else 'pause'
