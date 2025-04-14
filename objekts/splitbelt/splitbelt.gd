extends StaticBody3D #skript for the konveyor belt
class_name SplitBelt

@onready var pausedlight: StandardMaterial3D = preload("res://objekts/pausedlight.tres")
@onready var unpausedlight: StandardMaterial3D = preload("res://objekts/unpausedlight.tres")

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

var effect_overlapping_boxes: Array
var nextbelt_children: Array
var nextbelt_directions: Dictionary

func update_children() -> void:
	await get_tree().create_timer(0.5).timeout
	nextbelt_children = nextbelts.get_children()

func _ready() -> void:
	update_children()
	for nextbelt: Area3D in nextbelt_children: #iterates through all the detection areas (clicking on the lights basically)
		var detect: Area3D = nextbelt.get_node('MeshInstance3D/Area3D')
		#when the mouse enters/exits, its respective value will be set
		detect.mouse_entered.connect(func() -> void: onmouses[nextbelt.name] = true)
		detect.mouse_exited.connect(func() -> void: onmouses[nextbelt.name] = false)
		nextbelt_directions[nextbelt.name] = Vector3(nextbelt.global_position.x - global_position.x, 0, nextbelt.global_position.z - global_position.z).normalized()
	
	effect.body_entered.connect(func(body : Node3D) -> void:
		if body is Box and not effect_overlapping_boxes.has(body): effect_overlapping_boxes.append(body))
	effect.body_exited.connect(func(body : Node3D) -> void:
		if effect_overlapping_boxes.has(body): effect_overlapping_boxes.erase(body))

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1
	
	var options: Array[Vector3] = []
	var priority: int = -1
	
	if has_box:
		for NBD: Area3D in nextbelt_children:
			NBD.collision_mask = 1
			if active[NBD.name]:
				NBD.get_node('MeshInstance3D').material_override = unpausedlight
				for body: Node3D in NBD.get_overlapping_bodies():
					if body.is_in_group('machine') and body != self and movefoward(body):
						if body.get('empty') != null: priority = options.size()
						options.append(nextbelt_directions[NBD.name])
						break
			else:
				NBD.get_node('MeshInstance3D').material_override = pausedlight
	##if there's nowhere to go, move into empty spaces? (this only detects machines)
	
	has_box = false
	for body: Node3D in effect_overlapping_boxes:
		if options.is_empty(): break
		if body is Box: #iterates through all boxes
			has_box = true
			#the forces to apply, starts with the force from the options
			var option: Vector3 = options[0 if priority == -1 else (priority if options.size() > priority else 0)]
			var forces: Vector3 = (option * Main.beltspeed) + ((global_position - body.global_position).normalized() / Main.aligndivisor)
			options.erase(option) #remvoe the option so the next box cant use it
			##sets the force, add adusters
			body.vel += forces

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('leftclick') and area.get_overlapping_bodies().has(Main.main.player):
		for dir: String in onmouses:
			if onmouses[dir]:
				active[dir] = !active[dir]

func movefoward(belt : StaticBody3D) -> bool:
	if "has_box" in belt: #if it moves boxes
		if (belt.get('nextbeltdetector') and not belt.nextbeltdetector.get_overlapping_bodies().has(self)) or belt is SplitBelt:
			if not belt.has_box: return true #if it dosent have a box, go ahead!
			elif arraymatch(belt.effect_overlapping_boxes, effect_overlapping_boxes): return true #if the box on it is the current box, go ahead too!
			else: return false #pauses for everything else
		else: return false
	elif "empty" in belt: return (belt.empty if belt.pause.text == 'pause' else false) #if it grabs boxes, moves based on if it's empty or not
	else: return false #dont collide into any other machine please

func arraymatch(a : Array, b : Array) -> bool: ##EXTREMELY LAGGY
	for i: Variant in a:
		if b.has(i): return true
	return false

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
