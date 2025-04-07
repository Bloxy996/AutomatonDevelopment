extends StaticBody3D #skript for the multiplier 
class_name Multiplier

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var effect: Area3D = $Area3D
@onready var nextbeltdetector: Area3D = $nextbelt

var has_box: bool = false #true when there is a box on it

var nextbelt: StaticBody3D #the next machine to the belt

func _process(_delta: float) -> void: #runs on every frame
	effect.collision_mask = 1; nextbeltdetector.collision_mask = 1 #keep it from doing goofy stuff
	
	if not is_instance_valid(nextbelt): #if there is no machine to go to
		for node: Node3D in nextbeltdetector.get_overlapping_bodies():
			if node.is_in_group('machine') and node != self:
				nextbelt = node #get one that isnt itself!
				break
	
	var temphasbox: bool = false #tempoarily variable for if there's a box
	for body: Node3D in effect.get_overlapping_bodies(): #finds out what is on top of the multiplier
		if body is RigidBody3D: #if it can be moved,
			if body.is_in_group('box') and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				if movefoward(body): #set the force, if it is allowed to move foward
					body.vel += (transform.basis * Vector3.FORWARD).normalized() * -Main.beltspeed
				else: #align if there's nothing else to do
					body.vel = (global_position - body.global_position) / 4
				temphasbox = true #there is a box
	
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

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group('box') and not body.used_multipliers.has(self):
		body.used_multipliers.append(self)
		
		var oldprice: float = body.price
		body.price *= Main.machinepricemultiplier #expodential increase of price
		body.price = clamp(body.price, 0, 100) #clamp the price so ppl cant do crazy stuff
		
		if oldprice != body.price: #if the price actually changed
			#indicate the change of kredits in the box
			if Main.settings.indikator.multiplier:
				var indkinst: Indikator = indikator.instantiate()
				Main.main.ui.kreditindikator.add_child(indkinst)
				indkinst.start(round(body.price * 100) / 100, body.global_position, true)

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
