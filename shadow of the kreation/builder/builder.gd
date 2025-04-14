extends StaticBody3D
class_name Builder

@onready var wait: Timer = $Timer
@onready var holder: Marker3D = $holder
@onready var bar: ProgressBar = $holder/ProgressBar

var node: Node3D #machine to remove

var type: String #the machine that is being created
var mode: String = 'builder' #on deafault it creates

func _ready() -> void: #runs when it appears
	bar.modulate = Color(0, 1, 1) if mode == 'builder' else Color(1, 0, 0) #set's the bar color
	
	var shadow: Node3D = Main.machinedata[type]['shadow'].instantiate()
	add_child(shadow) #add the shadow for visuals
	
	for mesh: Node3D in shadow.get_children():
		if mesh is MeshInstance3D:
			mesh.material_override.albedo_color = Color(0, 0.749, 1, 0.498) if mode == 'builder' else Color(1, 0, 0, 0.498) #sets the colors
			if mesh.name.contains('arrow') and mode == 'destroyer': mesh.queue_free() #arrows are not needed!
	
	shadow.scale *= 1.02 #make it a tad bit bigger

func _process(_delta: float) -> void: #UI for the timer!
	bar.visible = global_position.distance_to(Main.main.player.global_position) < Main.builderbardistancevisible
	if bar.visible: 
		bar.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (bar.size / 2)
		bar.value = wait.time_left

func _on_timer_timeout() -> void:
	if mode == 'builder': #if it's being used to create
		var inst: StaticBody3D = Main.machinedata[type]['type_to_scene'].instantiate() #get the scene file for the machine
		Main.main.machines.add_child(inst) #add the machine to the scene
		
		#move it to the right position
		inst.global_position = global_position
		inst.global_rotation = global_rotation
	
	elif mode == 'destroyer': #if it's being used to destroy
		Main.progressions('sellmachine', '', node, null, global_position)
		
		node.queue_free() #IRRADIKATE ZE MACHINE!!
	
	queue_free() #remove the shadow

func save() -> Dictionary: #saving function called from main, gets all the data from the node and pushes it to main
	return {
		'filename' : get_scene_file_path(),
		'transform' : [global_position.x, global_position.y, global_position.z, global_rotation.y],
		'type' : type,
		'mode' : mode,
		'waittime' : wait.wait_time,
		'timeleft' : wait.time_left
	}

func primaryload(data : Dictionary) -> void: #load before the node is institnated
	if data.has('type'): type = data['type']
	if data.has('mode'): mode = data['mode']

func secondaryload(data : Dictionary) -> void: #load after the node has been institnated
	if data.has('transform'):
		global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
		global_rotation.y = data["transform"][3]
	
	if mode == 'builder': #start the timer stuff for the build shadow stuff
		if data.has('timeleft'): wait.start(data['timeleft'])
		if data.has('waittime'): bar.max_value = data['waittime']
	elif mode == 'destroyer': #destroyer shadows cant be saved yet 
		queue_free()
