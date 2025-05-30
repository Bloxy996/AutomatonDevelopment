extends StaticBody3D
class_name Builder

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var wait: Timer = $Timer
@onready var reversion: Timer = $reversion
@onready var holder: Marker3D = $holder
@onready var bar: ProgressBar = $holder/ProgressBar

var node: Node3D #machine to remove

var type: String #the machine that is being created
var mode: String = 'builder' #on deafault it creates

var onmouse: bool = false
var revert: bool = false

var price: int

func _ready() -> void: #runs when it appears
	bar.modulate = Color(0, 1, 1) if mode == 'builder' else Color(1, 0, 0) #set's the bar color
	
	var shadow: Node3D = Main.machinedata[type]['shadow'].instantiate()
	add_child(shadow) #add the shadow for visuals
	
	for mesh: Node3D in shadow.get_children():
		if mesh is MeshInstance3D:
			mesh.material_override.albedo_color = Color(0, 0.749, 1, 0.498) if mode == 'builder' else Color(1, 0, 0, 0.498) #sets the colors
			if mesh.name.contains('arrow') and mode == 'destroyer': mesh.queue_free() #arrows are not needed!
	
	shadow.scale *= 1.02 #make it a tad bit bigger
	
	mouse_entered.connect(func() -> void: onmouse = true)
	mouse_exited.connect(func() -> void: onmouse = false)

func _process(_delta: float) -> void: #UI for the timer!
	bar.visible = global_position.distance_to(Main.main.player.global_position) < Main.builderbardistancevisible
	if bar.visible: 
		bar.global_position = get_viewport().get_camera_3d().unproject_position(holder.global_position) - (bar.size / 2)
		bar.value = (wait.time_left) if !revert else (abs(reversion.time_left - reversion.wait_time))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rightclick") and onmouse and !revert:
		revert = true
		wait.stop()
		reversion.wait_time = (wait.wait_time - wait.time_left) / 4
		reversion.start()
		bar.max_value = reversion.wait_time

func _on_timer_timeout() -> void:
	if mode == 'builder': #if it's being used to create
		var inst: CollisionShape3D = Main.machinedata[type]['type_to_scene'].instantiate() #get the scene file for the machine
		Main.main.machines.add_child(inst) #add the machine to the scene
		
		#move it to the right position
		inst.global_position.x = global_position.x
		inst.global_position.z = global_position.z
		inst.global_rotation.y = global_rotation.y
		
		Main.main.machines.map[Vector2(inst.global_position.x, inst.global_position.z)] = inst
	
	elif mode == 'destroyer': #if it's being used to destroy
		if not is_instance_valid(node):
			if Main.main.machines.map.has(Vector2(global_position.x, global_position.z)):
				node = Main.main.machines.map[Vector2(global_position.x, global_position.z)]
			else: queue_free()
		
		Main.progressions('sellmachine', '', node, null, global_position)
		Main.main.machines.map.erase(Vector2(node.global_position.x, node.global_position.z))
		node.queue_free() #IRRADIKATE ZE MACHINE!!
	
	Main.main.machines.map_updated.emit()
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
	
	#start the timer stuff
	if data.has('timeleft'): wait.start(data['timeleft'])
	if data.has('waittime'): bar.max_value = data['waittime']

func _on_reversion_timeout() -> void:
	Main.kredits += price
	
	if Main.settings.indikator.kredit:
		var indkinst: Indikator = indikator.instantiate()
		Main.main.ui.kreditindikator.add_child(indkinst)
		indkinst.start(price, global_position)
	
	queue_free()
