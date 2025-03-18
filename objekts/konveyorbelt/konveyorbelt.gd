extends StaticBody3D #skript for the konveyor belt
class_name Belt

@onready var effect: Area3D = $Area3D
@onready var adjustL: Area3D = $adjustL
@onready var adjustR: Area3D = $adjustR

var has_box: bool = false #true when there is a box on it

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1; adjustL.collision_mask = 1; adjustR.collision_mask = 1
	var temphasbox: bool = false #tempoarily variable for if there's a box
	
	for body: Node3D in effect.get_overlapping_bodies() + adjustL.get_overlapping_bodies() + adjustR.get_overlapping_bodies(): #finds out what is on top of the belt
		if body is RigidBody3D: #if it can be moved,
			if body is Box and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				#the forces to apply, starts with nothing
				var forces: Vector3 = Vector3.ZERO
				#force from the foward area of the belt
				if effect.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.FORWARD).normalized() * Main.beltspeed
				#adds forces from adjusters
				if adjustL.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.RIGHT).normalized() * 4
				elif adjustR.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.LEFT).normalized() * 4
				##applies the forces needed with dampner, linear_velocities has won the fight for now
				##body.apply_impulse(forces - body.linear_velocity, body.forceapplier.position)
				body.linear_velocity = forces 
				
				temphasbox = true #there is a box
				
			##elif body.is_in_group('player'): #if it's the player also move it, for funsies! (maybe bring back some ppl liked it as transportation so)
			##body.apply_impulse(((transform.basis * Vector3.FORWARD).normalized() * Main.beltspeed) - body.linear_velocity)
	
	has_box = temphasbox #update the actual has box variable

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
	global_rotation.y = data["transform"][3]
