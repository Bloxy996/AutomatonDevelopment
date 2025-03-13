extends StaticBody3D #skript for the multiplier 
class_name Multiplier

@onready var area: Area3D = $Area3D

var has_box: bool = false #true when there is a box on it

func _process(_delta: float) -> void: #runs on every frame
	area.collision_mask = 1 #keep it from doing goofy stuff
	for body: Node3D in area.get_overlapping_bodies(): #finds out what is on top of the multiplier
		if body is RigidBody3D: #if it can be moved,
			if body.is_in_group('box') and body.get_parent().name != 'hand': #if it's a box and not being held, move it
				has_box = true #tell everyone that there is a box on the multiplier
				##apply forces (linear_velocity has won the fight for now), maybe it should be slower than the conveyor belt
				##body.apply_impulse(((transform.basis * Vector3.FORWARD).normalized() * -Main.beltspeed) - body.linear_velocity, body.forceapplier.position)
				body.linear_velocity = (transform.basis * Vector3.FORWARD).normalized() * -Main.beltspeed

func _on_area_3d_body_exited(body: Node3D) -> void: #if a box leaves the multiplier, set the has box varible to 0 because there is no box anymore
	if body.is_in_group('box'):
		has_box = false

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
