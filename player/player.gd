extends RigidBody3D #skript for the player!
class_name Player

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var hand: Marker3D = $CollisionShape3D/hand
@onready var area3d: Area3D = $Area3D
@onready var boxcollision: CollisionShape3D = $boxcollision
@onready var buildradius: Area3D = $buildradius
@onready var removeradius: Area3D = $removeradius
@onready var deathradius: Area3D = $deathradius
@onready var deathanim: AnimationPlayer = $death/AnimationPlayer
@onready var floorcast: ShapeCast3D = $floor
@onready var deathconfirmation: Timer = $deathradius/confirmation
@onready var boxdetection: Area3D = $boxdetection

@onready var loader: Loader = $"../loader"

var waitforrestart: bool = false
var dead: bool = false

func _physics_process(delta: float) -> void: #runs every microsecond because you have a pretty fast computer
	var input_dir: Vector2 = Input.get_vector("S", "W", "A", "D") #gets all the WASD inputs to move the player
	var direction: Vector3 = ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * 7.5).rotated(Vector3.UP, deg_to_rad(-45)) #turns the inputs into a vector direction with hyper komplex ap calculus bc math, and make it directional to the camera
	var jump: int = int(Input.is_action_just_pressed("space") and floorcast.is_colliding()) #a integer that is 1 when the player presses space to jump and if it's not floating, 0 if not
	
	direction /= 1 + 0.75 * int(not get_contact_count() > 0) #make the player slow when it's in the air
	if not dead: apply_impulse(Vector3(direction.x - linear_velocity.x, jump * 100, direction.z - linear_velocity.z)) #move the actual player itself with the direction and jump varibles, also keep it from flinging away with the subtraction of velocities
	
	if input_dir and linear_velocity.length() / 3 > 0.25: #if someone pressed W, A, S, or D and the player is moving
		collision.global_rotation.y = lerp_angle(collision.global_rotation.y, Vector2(linear_velocity.x, -linear_velocity.z).angle(), delta * 8) #rotate the player to the direction that it's facing
	
func _process(_delta: float) -> void:
	hand.position.y = 0 #move the hand position to eye level
	#if the player is near a machine that requests it to lift the box its holding, lift it
	for area: Node3D in area3d.get_overlapping_areas():
		if area.is_in_group('liftbox'):
			hand.position.y = 0.5
			break
	
	boxcollision.global_position = hand.global_position
	boxcollision.global_rotation = hand.global_rotation
	boxcollision.disabled = not Main.picked
	
	buildradius.global_position.y = 0.5 #keep the radius on the ground
	removeradius.global_position.y = 0.5 #keep the radius on the ground
	
	buildradius.visible = Main.building #shows the build radius thingy when building stuff
	removeradius.visible = Main.irradicating #shows the remove radius thingy when destorying stuff
	
	if global_position.y < -2 and not dead: #die if you fall out of the map
		die()
	
	if deathradius.get_overlapping_bodies().size() - 1 > 0: #get clipped body count not including the player, if it's larger (the player is clipping)
		if deathconfirmation.is_stopped(): deathconfirmation.start() #start the timer to confirm the death

func die() -> void:
	if Main.picked: hand.get_child(0).dropbox() #drops any held boxes
	Main.building = false #resets these because why not?
	Main.irradicating = false
	
	deathanim.play('death') #play the animation for the death screen
	dead = true #kill the player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("R") and waitforrestart: #reset the game when the death screen is there
		reset()

func reset() -> void:
	global_position = Vector3(4, 1, 4) #reset position
	Main.savegame() #save the game
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().reload_current_scene()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	waitforrestart = true #set to true to wait for the user to press R

func _on_confirmation_timeout() -> void: #if the confirmation timer is over and the player is still clipped, kill it
	if deathradius.get_overlapping_bodies().size() - 1 > 0: die()

func clearboxes() -> void: #delete unused boxes in immediate area
	for node: Node3D in boxdetection.get_overlapping_bodies():
		if Main.kredits >= Main.deleteboxcost:
			if node is Box and node.get_parent().name != 'hand': #iterates through all the boxes that arent being held
				var usingbox: bool = false
				
				for area: Area3D in node.detector.get_overlapping_areas():
					if area.is_in_group('usingbox'):
						usingbox = true #sets this to true when the box is in an area used for a machine (it's being used)
						break
				
				if not usingbox: 
					Main.kredits -= Main.deleteboxcost #take away kredits
					
					#indicate the change of kredits
					if Main.settings.indikator.kredit:
						var indkinst: Indikator = indikator.instantiate()
						Main.main.ui.kreditindikator.add_child(indkinst)
						indkinst.start(-Main.deleteboxcost, node.global_position)
					
					node.queue_free() #if it's not being used, remove it
		else: #stop the removal of boxes if you would run out of kredits
			break
	
	Main.savegame() #idk it just seems like a good time to save ig
