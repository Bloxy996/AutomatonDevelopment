extends CollisionShape3D
class_name Belt

@onready var effect: Area3D = $Area3D
@onready var nextbeltdetector: Marker3D = $nextbelt
@onready var area: Area3D = $Area3D2

var has_box: bool = false #true when there is a box on it

var nextbelt: CollisionShape3D #the next machine to the belt

var effect_overlapping_boxes: Array

func _ready() -> void:
	global_position.y = 0.299
	
	Main.main.machines.map_updated.connect(func() -> void:
		var pos: Vector2 = Vector2(nextbeltdetector.global_position.x, nextbeltdetector.global_position.z)
		if Main.main.machines.map.has(pos): nextbelt =  Main.main.machines.map[pos]
		else: nextbelt = null)
	
	effect.body_entered.connect(func(body : Node3D) -> void:
		if body is Box and not effect_overlapping_boxes.has(body): 
			effect_overlapping_boxes.append(body))
	effect.body_exited.connect(func(body : Node3D) -> void:
		if effect_overlapping_boxes.has(body): 
			effect_overlapping_boxes.erase(body))

func update(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1
	
	if not is_instance_valid(nextbelt): #if there is no machine to go to
		nextbelt = null #then there IS no machine
	
	has_box = !effect_overlapping_boxes.is_empty()

func movefoward(box : Box) -> bool:
	if is_instance_valid(nextbelt): #if there's a machine
		if "has_box" in nextbelt: #if it moves boxes
			if not nextbelt.has_box: return true #if it dosent have a box, go ahead!
			elif nextbelt.effect_overlapping_boxes.has(box): return true #if the box on it is the current box, go ahead too!
			##removed to keep boxes from sticking to each other, but now phantom traffic jams are back
			##elif nextbelt is not SplitBelt and !nextbelt.effect_overlapping_boxes.is_empty() and nextbelt.movefoward(nextbelt.effect_overlapping_boxes[0]): return true
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
