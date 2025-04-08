extends StaticBody3D #skript for the konveyor belt
class_name Belt

@onready var effect: Area3D = $Area3D
@onready var nextbeltdetector: Area3D = $nextbelt

var has_box: bool = false #true when there is a box on it

var nextbelt: StaticBody3D #the next machine to the belt

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1; nextbeltdetector.collision_mask = 1
	
	if not is_instance_valid(nextbelt): #if there is no machine to go to
		for node: Node3D in nextbeltdetector.get_overlapping_bodies():
			if node.is_in_group('machine') and node != self:
				nextbelt = node #get one that isnt itself!
				break
	
	var temphasbox: bool = false #tempoarily variable for if there's a box
	for body: Node3D in effect.get_overlapping_bodies(): #finds out what is on top of the belt
		if body is Box and body.get_parent().name != 'hand': #if it's a box and not being held, move it
			temphasbox = true #there is a box
			
			var forces: Vector3 = (global_position - body.global_position).normalized() / Main.aligndivisor #force variable
			if movefoward(body): forces += (transform.basis * Vector3.FORWARD).normalized() * Main.beltspeed #foward force if it can move foward
			#force to align the box to the center
			var dist: float = (body.global_position - global_position).dot(global_transform.basis.x.normalized())
			forces += (transform.basis * Vector3(dist, 0, 0)).normalized() * -abs(dist * 2)
			#set the forces
			body.vel += forces
	
	has_box = temphasbox #update the actual has box variable

func movefoward(box : Box) -> bool:
	if is_instance_valid(nextbelt): #if there's a machine
		if nextbelt.get('has_box') != null: #if it moves boxes
			if not nextbelt.has_box: return true #if it dosent have a box, go ahead!
			elif getboxes(nextbelt.effect.get_overlapping_bodies()).has(box): return true #if the box on it is the current box, go ahead too!
			else: return false #pauses for everything else
		elif nextbelt.get('empty') != null: return (nextbelt.empty if nextbelt.pause.text == 'pause' else false) #if it grabs boxes, moves based on if it's empty or not
		else: return false #dont collide into any other machine please
	else: return true #move if there's nothing at all!

func getboxes(overlaps : Array) -> Array[Box]:
	var final: Array[Box] = []
	for node: Node3D in overlaps:
		if node is Box: final.append(node)
	return final

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
