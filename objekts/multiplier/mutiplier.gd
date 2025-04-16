extends StaticBody3D #skript for the multiplier 
class_name Multiplier

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

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
	effect.collision_mask = 1; nextbeltdetector.collision_mask = 1 #keep it from doing goofy stuff
	
	if not is_instance_valid(nextbelt): #if there is no machine to go to
		nextbelt = null #then there IS no machine
	
	var globalpos: Vector3 = global_position
	var forward: Vector3 = transform.basis.z * Main.beltspeed
	
	has_box = false
	for body: Node3D in effect_overlapping_boxes: #finds out what is on top of the multiplier
		if body is RigidBody3D: #if it can be moved,
			if body.is_in_group('box') and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				has_box = true
				if movefoward(body): #set the force, if it is allowed to move foward
					body.vel += forward
				else: #align if there's nothing else to do
					body.vel = (globalpos - body.global_position).normalized() / Main.aligndivisor

func movefoward(box : Box) -> bool:
	if is_instance_valid(nextbelt): #if there's a machine
		if "has_box" in nextbelt: #if it moves boxes
			if not nextbelt.has_box: return true #if it dosent have a box, go ahead!
			elif nextbelt.effect_overlapping_boxes.has(box): return true #if the box on it is the current box, go ahead too!
			else: return false #pauses for everything else
		elif "empty" in nextbelt: return (nextbelt.empty if nextbelt.pause.text == 'pause' else false) #if it grabs boxes, moves based on if it's empty or not
		else: return false #dont collide into any other machine please
	else: return true #move if there's nothing at all!

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group('box') and not body.used_multipliers.has(self):
		body.used_multipliers.append(self)
		
		var oldprice: float = body.price
		body.price *= Main.machinepricemultiplier #expodential increase of price
		body.price = clamp(body.price, 0, Main.multiplierpricecap) #clamp the price so ppl cant do crazy stuff
		
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
