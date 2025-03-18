extends StaticBody3D #skript for the konveyor belt
class_name SplitBelt

@onready var effect: Area3D = $Area3D
@onready var adjustL: Area3D = $adjustL
@onready var adjustR: Area3D = $adjustR
@onready var area: Area3D = $Area3D2
@onready var flip: Area3D = $flip
@onready var positive: MeshInstance3D = $positive
@onready var negative: MeshInstance3D = $negative

var nextdir: float = 1 #toggles between -1 and 1 for pushing boxes back and forth
var currentboxes: Dictionary = {} #dict that will hold all the boxes inside of the belt and store the direction theyre supposed to go in

var onmouse: bool = false

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1; adjustL.collision_mask = 1; adjustR.collision_mask = 1
	
	var overlapping: Array = effect.get_overlapping_bodies() + adjustL.get_overlapping_bodies() + adjustR.get_overlapping_bodies()
	
	for body: Node3D in overlapping:
		if body is Box and (not currentboxes.keys().has(body)) and body.get_parent().name != 'hand': 
			currentboxes[body] = nextdir
			nextdir *= -1
	
	for box: Box in currentboxes.keys():
		if not overlapping.has(box):
			currentboxes.erase(box)
		else:
			#the forces to apply, starts with nothing
			var forces: Vector3 = Vector3.ZERO
			#force from the foward area of the belt
			if effect.get_overlapping_bodies().has(box): forces += (transform.basis * Vector3.FORWARD).normalized() * Main.beltspeed * currentboxes[box]
			#adds forces from adjusters
			if adjustL.get_overlapping_bodies().has(box): forces += (transform.basis * Vector3.RIGHT).normalized() * 4
			elif adjustR.get_overlapping_bodies().has(box): forces += (transform.basis * Vector3.LEFT).normalized() * 4
			##applies the forces needed with dampner, linear_velocities has won the fight for now
			##body.apply_impulse(forces - body.linear_velocity, body.forceapplier.position)
			box.linear_velocity = forces
	
	#manual flipping of the belt
	if area.get_overlapping_bodies().has(Main.main.get_node('player')):
		if onmouse and Input.is_action_just_pressed('rightclick'):
			nextdir *= -1
			for box: Box in currentboxes.keys():
				currentboxes[box] = nextdir
	
	#set the directional lights for the next direction
	positive.material_override = load("res://objekts/pausedlight.tres") if nextdir == -1 else load("res://objekts/unpausedlight.tres")
	negative.material_override = load("res://objekts/pausedlight.tres") if nextdir == 1 else load("res://objekts/unpausedlight.tres")

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
		##maybe save nextdir?
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
	global_rotation.y = data["transform"][3]

func _on_flip_mouse_entered() -> void:
	onmouse = true

func _on_flip_mouse_exited() -> void:
	onmouse = false
