extends StaticBody3D #skript for the konveyor belt
class_name Belt

@onready var effect: Area3D = $Area3D
@onready var nextbeltdetector: Area3D = $nextbelt
@onready var area: Area3D = $Area3D2

var has_box: bool = false #true when there is a box on it

var nextbelt: StaticBody3D #the next machine to the belt

var effect_overlapping_boxes: Array

func _ready() -> void:
	nextbeltdetector.body_entered.connect(func(body : Node3D) -> void:
		if body.is_in_group('machine') and body != self: nextbelt = body)
	nextbeltdetector.body_exited.connect(func(body : Node3D) -> void:
		if body == nextbelt: nextbelt = null)
	
	effect.body_entered.connect(func(body : Node3D) -> void:
		if body is Box and not effect_overlapping_boxes.has(body): 
			effect_overlapping_boxes.append(body))
	effect.body_exited.connect(func(body : Node3D) -> void:
		if effect_overlapping_boxes.has(body): 
			effect_overlapping_boxes.erase(body))

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1; nextbeltdetector.collision_mask = 1
	
	if not is_instance_valid(nextbelt): #if there is no machine to go to
		nextbelt = null #then there IS no machine
	
	var transbasis: Basis = transform.basis #just for optimization
	var globaltransbasis: Basis = global_transform.basis
	var globalpos: Vector3 = global_position
	
	has_box = false
	for body: Node3D in effect_overlapping_boxes: #finds out what is on top of the belt
		if body is Box and body.get_parent().name != 'hand': #if it's a box and not being held, move it
			has_box = true
			var forces: Vector3 = (globalpos - body.global_position).normalized() / Main.aligndivisor #force variable
			if movefoward(body): forces += transbasis.z * -Main.beltspeed #foward force if it can move foward
			#force to align the box to the center
			var dist: float = (body.global_position - globalpos).dot(globaltransbasis.x.normalized())
			forces += (transbasis * Vector3(dist, 0, 0)).normalized() * -abs(dist * 2) ##apparently this could be optimized?
			#set the forces
			if forces.length() > 0.01: body.vel += forces

func movefoward(box : Box) -> bool:
	if is_instance_valid(nextbelt): #if there's a machine
		if "has_box" in nextbelt: #if it moves boxes
			if not nextbelt.has_box: return true #if it dosent have a box, go ahead!
			elif nextbelt.effect_overlapping_boxes.has(box): return true #if the box on it is the current box, go ahead too!
			else: return false #pauses for everything else
		elif "empty" in nextbelt: return (nextbelt.empty if nextbelt.pause.text == 'pause' else false) #if it grabs boxes, moves based on if it's empty or not
		else: return false #dont collide into any other machine please
	else: return true #move if there's nothing at all!

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
