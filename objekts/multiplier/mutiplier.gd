extends StaticBody3D #skript for the multiplier 
class_name Multiplier

@onready var area: Area3D = $Area3D

var has_box: bool = false #true when there is a box on it

func _process(_delta: float) -> void: #runs on every frame
	area.collision_mask = 1 #keep it from doing goofy stuff
	var temphasbox: bool = false #tempoarily variable for if there's a box
	
	for body: Node3D in area.get_overlapping_bodies(): #finds out what is on top of the multiplier
		if body is RigidBody3D: #if it can be moved,
			if body.is_in_group('box') and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				##apply forces (linear_velocity has won the fight for now), maybe it should be slower than the conveyor belt
				##body.apply_impulse(((transform.basis * Vector3.FORWARD).normalized() * -Main.beltspeed) - body.linear_velocity, body.forceapplier.position)
				
				body.linear_velocity = (transform.basis * Vector3.FORWARD).normalized() * -Main.beltspeed
				temphasbox = true #there is a box
	
	has_box = temphasbox #update the actual has box variable

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group('box') and not body.used_multipliers.has(self):
		body.used_multipliers.append(self)
		body.price *= Main.machinepricemultiplier ##made expodential, maybe put in the progressions thingy
		body.price = clampi(body.price, 0, 100) ##clamp the price so ppl cant do crazy stuff, show that this is the max somewhere?

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y]
	}

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
	global_rotation.y = data["transform"][3]
