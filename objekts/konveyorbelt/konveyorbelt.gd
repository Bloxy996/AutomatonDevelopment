extends StaticBody3D #skript for the konveyor belt
class_name Belt

@onready var effect: Area3D = $Area3D
@onready var adjustL: Area3D = $adjustL
@onready var adjustR: Area3D = $adjustR

var has_box: bool = false #true when there is a box on it

func _process(_delta: float) -> void: #runs on every frame
	#keep it from doing goofy stuff
	effect.collision_mask = 1; adjustL.collision_mask = 1; adjustR.collision_mask = 1
	
	for body: Node3D in effect.get_overlapping_bodies() + adjustL.get_overlapping_bodies() + adjustR.get_overlapping_bodies(): #finds out what is on top of the belt
		if body is RigidBody3D: #if it can be moved,
			if body is Box and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				has_box = true #tell everyone that there is a box on the belt
				
				#the forces to apply, starts with nothing
				var forces: Vector3 = Vector3.ZERO
				#force from the foward area of the belt
				if effect.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.FORWARD).normalized() * 5
				#adds forces from adjusters
				if adjustL.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.RIGHT).normalized() * 4
				elif adjustR.get_overlapping_bodies().has(body): forces += (transform.basis * Vector3.LEFT).normalized() * 4
				#applies the forces needed with dampner
				body.apply_impulse(forces - body.linear_velocity, body.forceapplier.position) ##maybe use a lin velocity setter instead? (more stable)
				
			elif body.is_in_group('player'): #if it's the player also move it, for funsies!
				body.apply_impulse(((transform.basis * Vector3.FORWARD).normalized() * 5) - body.linear_velocity)

func _on_area_3d_body_exited(body: Node3D) -> void: #if a box leaves the belt, set the has box varible to 0 because there is no box anymore
	if body is Box:
		has_box = false

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'parent' : Main.main.get_path_to(get_parent()),
		'rotY' : global_rotation.y,
		'posX' : global_position.x,
		'posY' : global_position.y,
		'posZ' : global_position.z
	}
