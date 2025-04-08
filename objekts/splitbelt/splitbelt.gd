extends StaticBody3D #skript for the konveyor belt
class_name SplitBelt

@onready var effect: Area3D = $Area3D
@onready var area: Area3D = $Area3D2
@onready var nextbelts: Node3D = $nextbelts

var has_box: bool = false #true when there is a box on it

var onmouses: Dictionary = { #all of the onmouse thingies for each of the directions
	'foward' : false,
	'back' : false,
	'left' : false,
	'right' : false
}

var active: Dictionary = { #which directions are active or not, all start as active
	'foward' : true,
	'back' : true,
	'left' : true,
	'right' : true
}

func _ready() -> void:
	for nextbelt: Area3D in nextbelts.get_children(): #iterates through all the detection areas (clicking on the lights basically)
		var detect: Area3D = nextbelt.get_node('MeshInstance3D/Area3D')
		#when the mouse enters/exits, its respective value will be set
		detect.mouse_entered.connect(func() -> void: onmouses[nextbelt.name] = true)
		detect.mouse_exited.connect(func() -> void: onmouses[nextbelt.name] = false)

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1
	var temphasbox: bool = false #tempoarily variable for if there's a box
	
	var options: Array[Vector3] = []
	var priority: int = -1
	
	for NBD: Area3D in nextbelts.get_children():
		NBD.collision_mask = 1
		if active[NBD.name]:
			NBD.get_node('MeshInstance3D').material_override = load("res://objekts/unpausedlight.tres")
			for body: Node3D in NBD.get_overlapping_bodies():
				if body.is_in_group('machine') and body != self and movefoward(body):
					if body.get('empty') != null: priority = options.size()
					options.append(Vector3(NBD.global_position.x - global_position.x, 0, NBD.global_position.z - global_position.z).normalized())
					break
		else:
			NBD.get_node('MeshInstance3D').material_override = load("res://objekts/pausedlight.tres")
	##if there's nowhere to go, move into empty spaces? (this only detects machines)
	
	for body: Node3D in effect.get_overlapping_bodies():
		if body is Box: #iterates through all boxes
			#the forces to apply, starts with the force from the options
			var forces: Vector3 = ((options[0 if priority == -1 else priority] * Main.beltspeed) if not options.is_empty() else Vector3.ZERO) + ((global_position - body.global_position).normalized() / Main.aligndivisor)
			options.erase(forces) #remvoe the option so the next box cant use it
			##sets the force, add adusters
			body.vel += forces
			temphasbox = true #there is a box
	
	has_box = temphasbox #update the actual has box variable

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('leftclick') and area.get_overlapping_bodies().has(Main.main.get_node('player')):
		for dir: String in onmouses:
			if onmouses[dir]:
				active[dir] = !active[dir]

func movefoward(belt : StaticBody3D) -> bool:
	if belt.get('has_box') != null: #if it moves boxes
		if (belt.get('nextbeltdetector') and not belt.nextbeltdetector.get_overlapping_bodies().has(self)) or belt is SplitBelt:
			if not belt.has_box: return true #if it dosent have a box, go ahead!
			elif arraymatch(getboxes(belt.effect.get_overlapping_bodies()), getboxes(effect.get_overlapping_bodies())): return true #if the box on it is the current box, go ahead too!
			else: return false #pauses for everything else
		else: return false
	elif belt.get('empty') != null: return (belt.empty if belt.pause.text == 'pause' else false) #if it grabs boxes, moves based on if it's empty or not
	else: return false #dont collide into any other machine please

func arraymatch(a : Array, b : Array) -> bool:
	for i: Variant in a:
		if b.has(i): return true
	return false

func getboxes(overlaps : Array) -> Array[Box]:
	var final: Array[Box] = []
	for node: Node3D in overlaps:
		if node is Box: final.append(node)
	return final

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'active' : active
	}

func primaryload(data : Dictionary) -> void: #load before the node is institnated
	if data.has('active'): active = data.active

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
