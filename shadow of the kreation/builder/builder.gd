extends StaticBody3D
class_name Builder

@onready var shadows: Node3D = $shadows #all of the shadow meshes
@onready var wait: Timer = $Timer
@onready var holder: Marker3D = $holder
@onready var bar: ProgressBar = $holder/ProgressBar

var node: Node3D ##machine to remove, FIND A WAY TO SAVE THIS IN JSON SO I CAN SAVE THE SHADOWS OF THE DESTROYER

var type: String #the machine that is being created
var mode: String = 'builder' #on deafault it creates

var type_to_scene: Dictionary = { #gives a scene file to the name of the machine
	'kreator' : preload("res://objekts/kreator/kreator.tscn"),
	'seller' : preload("res://objekts/seller/seller.tscn"),
	'belt' : preload("res://objekts/konveyorbelt/konveyorbelt.tscn"),
	'multiplier' : preload("res://objekts/multiplier/mutiplier.tscn")
}

func _ready() -> void: #runs when it appears
	bar.modulate = Color(0, 1, 1) if mode == 'builder' else Color(1, 0, 0) #set's the bar color
	
	for shadow: Node3D in shadows.get_children(): #set the shadow mesh to the one of the type of the machine
		if shadow.name == type:
			shadow.show()
			for mesh: MeshInstance3D in shadow.get_children():
				mesh.material_override.albedo_color = Color(0, 0.749, 1, 0.498) if mode == 'builder' else Color(1, 0, 0, 0.498) #sets the colors
				if mesh.name == 'arrow' and mode == 'destroyer': mesh.queue_free() #arrows are not needed!
			break

func _process(_delta: float) -> void: #UI for the timer!
	bar.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (bar.size / 2)
	bar.value = wait.time_left

func _on_timer_timeout() -> void:
	if mode == 'builder': #if it's being used to create
		var inst: StaticBody3D = type_to_scene[type].instantiate() #get the scene file for the machine
		Main.main.get_node('machines').add_child(inst) #add the machine to the scene
		
		#move it to the right position
		inst.global_position = global_position
		inst.global_rotation = global_rotation
	
	elif mode == 'destroyer': #if it's being used to destroy
		Main.progressions('sellmachine', '', node)
		
		node.queue_free() #IRRADIKATE ZE MACHINE!!
	
	queue_free() #remove the shadow

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'parent' : Main.main.get_path_to(get_parent()),
		'rotY' : global_rotation.y,
		'posX' : global_position.x,
		'posY' : global_position.y,
		'posZ' : global_position.z,
		'type' : type,
		'mode' : mode,
		'waittime' : wait.wait_time,
		'timeleft' : wait.time_left
	}
