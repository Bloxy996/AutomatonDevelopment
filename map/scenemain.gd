extends Node3D
class_name MainScene

@onready var room: PackedScene = preload("res://map/room.tscn")
@onready var buildshadow: PackedScene = preload('res://shadow of the kreation/builder/builder.tscn')

@onready var irradicate: Area3D = $irradicate
@onready var factory: Node3D = $factory
@onready var camera: Camera3D = $Camera3D
@onready var irradicatebutton: Button = $UI/irradicate
@onready var autosave: Timer = $UI/autosave
@onready var irradicating_buildradius_detection: Area3D = $irradicate/buildradius_detection
@onready var univground: MeshInstance3D = $univground
@onready var loader: Loader = $loader
@onready var boxkreationdelay: Timer = $boxkreationdelay
@onready var boxsenddelay: Timer = $boxsenddelay
@onready var spawn: Area3D = $spawn
@onready var exitdelay: Timer = $exitdelay
@onready var boxes: Node3D = $boxes
@onready var machines: Node3D = $machines
@onready var light: DirectionalLight3D = $DirectionalLight3D
@onready var shop: Shop = $UI/Shop

@onready var ui: UI = $UI
@onready var player: Player = $player

var room_size: int = 14 #the size of the rooms for the generator

var zoom: float = 10 #size of the camera

var boxkreationqueue: Array[Kreator] = [] #the box kreation queue, all boxes go here to be created
var boxsendqueue: Array[Box] = [] #the queue for sending boxes to belts bc now I apparently need one

var boxamount: float = 0

func _ready() -> void:
	Main.main = self #set the main scene in the master branch
	Main.loadgame() #load the game when starting
	loader.showscreen()

func mouse_3d_pos() -> Vector3: #advanced math stuff to get the mouse position
	var mousepos: Vector2 = get_viewport().get_mouse_position()
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray.exclude = get_rids(get_tree().get_nodes_in_group("exclude_from_raycast"))
	ray.from = get_viewport().get_camera_3d().project_ray_origin(mousepos)
	ray.to = ray.from + get_viewport().get_camera_3d().project_ray_normal(mousepos) * 5000
	var ray_results: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	if not ray_results.is_empty():
		return ray_results['position']
	return Vector3.ZERO

func _on_irradicate_pressed() -> void: #if the user pressed the delete machines button
	if (not Main.building) and (not Main.settingbehavior): #if the player is not building somethings, tell main that something will be IRRADICATED FROM THE FACE OF THIS FACKTORY
		Main.irradicating = true

func _process(delta: float) -> void: #runs every ~milisecond
	irradicate.visible = Main.irradicating #show the irradikating shadow if something is being irradicated
	
	if Main.irradicating: #if something is being irradicated
		#move the irradicating shadow to the position of the mouse
		irradicate.global_position = snapped(mouse_3d_pos(), Vector3.ONE)
		irradicate.global_position.y = 0
		irradicatebutton.release_focus() #release fokus from the button to solve the bug of pressing space
		
		if Input.is_action_just_pressed("leftclick") and irradicating_buildradius_detection.get_overlapping_areas().has(Main.main.player.removeradius): #if the mouse is clicked and in range
			#if there are any machines in the shadow's area, it's GRASP OF DESTRUKTION... (and if it's also not an original machine)
			
			var builderinarea: bool = false
			for node: Node3D in irradicate.get_overlapping_bodies():
				if node is Builder: builderinarea = true
			
			if not builderinarea:
				for node: Node3D in irradicate.get_overlapping_bodies():
					if node.is_in_group('machine'):
						if not node.is_in_group('original'):
							var inst: Builder = buildshadow.instantiate() #create the builder to remove a machine
							inst.mode = 'destroyer' #set all of the settings
							inst.node = node
							inst.type = Main.group_to_type(node)
							
							Main.main.get_node('machines').add_child(inst) #add the node and set the timer stuff
							var buildtime: float = Main.machinedata[inst.type].type_to_waittime + randf_range(-2, 2)
							inst.wait.start(buildtime / Main.deletetimerspeedup)
							inst.bar.max_value = buildtime / Main.deletetimerspeedup
							
							inst.global_position = node.global_position #move it to the correct position
							inst.global_rotation = node.global_rotation
							
							break
		
		if Input.is_action_just_pressed("esc"):
			exitdelay.start() #start the timer so the pause menu dosent show
			Main.irradicating = false #tell main that the shadow is done doing it's horrible things
	
	camera.global_position = lerp(camera.global_position, Vector3(player.global_position.x - 10, 15, player.global_position.z - 10), delta * 4) #set the camera position
	camera.size = lerpf(camera.size, zoom, delta * 4) #set camera zoom on the actual size
	
	univground.global_position = Vector3(player.global_position.x, -0.55, player.global_position.z) #set the position for the visual ground
	
	#number of boxes also includes the ones being generated
	boxamount = get_tree().get_nodes_in_group('box').size()
	for kreator: Kreator in get_tree().get_nodes_in_group('kreator'):
		if (not kreator.timer.is_stopped()) or (not kreator.automated.is_stopped()):
			boxamount += 1
	
	if boxkreationdelay.is_stopped(): #the code in here will run periodically for however long the wait time for the timer is
		boxkreationdelay.start()
		if boxamount < Main.maxboxes: #if there's enough space to add more boxes and there's stuff in the queue
			if not boxkreationqueue.is_empty():
				if is_instance_valid(boxkreationqueue[0]): #if it's still there
					var latest: Kreator = boxkreationqueue.pop_front()
					if is_instance_valid(latest): latest.request_accepted() #accept the oldest item in the queue and delete it
				else: boxkreationqueue.pop_front() #if it's not valid just get rid of it
	
	if boxsenddelay.is_stopped():
		boxsenddelay.start()
		if not boxsendqueue.is_empty():
			if is_instance_valid(boxsendqueue[0]):
				var latest: Box = boxsendqueue.pop_front()
				for area: Area3D in latest.detector.get_overlapping_areas():
					if area.is_in_group('inkreator'):
						area.get_parent().send_request_accepted(latest)
						break
	
	if Main.settings.daynight: light.rotation_degrees += Vector3(2, 1, 0) * 0.001 #day night cycle
	else: light.rotation_degrees = Vector3(-60, 135, 0) #if the cycle is disabled, go to default

func _input(event: InputEvent) -> void:
	if not shop.visible: #if the user isnt in the shop
		if (event is InputEventMouseButton) and event.is_pressed(): #zoom camera
			zoom = clampf(zoom + (int(event.button_index == MOUSE_BUTTON_WHEEL_DOWN) - int(event.button_index == MOUSE_BUTTON_WHEEL_UP)), 5, 25)
		elif event.is_action_pressed("delete"): #delete key can also be used to delete machines
			if (not Main.building) and (not Main.settingbehavior): #if the player is not building somethings, tell main that something will be IRRADICATED FROM THE FACE OF THIS FACKTORY
				Main.irradicating = true

func _on_autosave_timeout() -> void: #save the game periodically
	Main.savegame()
	autosave.start() #then start the timer again

func get_rids(nodes: Array[Node]) -> Array[RID]:
	var rids: Array[RID] = []
	for node: Node in nodes:
		rids.append(node.get_rid())
	return rids

func add_room(location : Vector2i) -> void:
	Main.factory_map[str([location.x, location.y])] = null #add the room
	print(Main.factory_map)
	
	var inst: Room = room.instantiate() #create the room
	inst.location = location #set it's position on the map
	factory.add_child(inst) #add the factory!
	inst.global_position = Vector3(location.x, 0, location.y) * room_size #set the physical position
	
	remove_walls_for_room(location, inst) #removes the walls
	
	Main.maxboxes += Main.boxesperroom #increases the max amount of boxes when you expand

func generate_rooms() -> void: #generate rooms from factory map
	#clear everything in there already except for the original room
	for node: Node3D in factory.get_children():
		if node.name != 'original': node.queue_free()
	
	#generate the rooms
	for pos: String in Main.factory_map.keys():
		if pos != '[0, 0]': #the starting room already exists!
			var inst: Room = room.instantiate() #create the room
			inst.location = Vector2i(str_to_var(pos)[0], str_to_var(pos)[1]) #set it's position on the map
			factory.add_child(inst) #add the factory!
			
			inst.global_position = Vector3(inst.location.x, 0, inst.location.y) * room_size #set the phsyical position
			remove_walls_for_room(inst.location, inst)

func remove_walls_for_room(location : Vector2i, roominst : Room) -> void:
	for node: Room in factory.get_children(): #removes the walls if it's connecting to another room
		var mapos: Vector2i = Vector2i(int(node.global_position.x), int(node.global_position.z)) / room_size
		if location + Vector2i(-1, 0) == mapos: #back right to current
			if is_instance_valid(roominst.wallBR): roominst.wallBR.queue_free()
			if is_instance_valid(node.wallFL): node.wallFL.queue_free()
		elif location + Vector2i(0, -1) == mapos: #back left to current
			if is_instance_valid(roominst.wallBL): roominst.wallBL.queue_free()
			if is_instance_valid(node.wallFR): node.wallFR.queue_free()
		elif location + Vector2i(1, 0) == mapos: #front left to current
			if is_instance_valid(roominst.wallFL): roominst.wallFL.queue_free()
			if is_instance_valid(node.wallBR): node.wallBR.queue_free()
		elif location + Vector2i(0, 1) == mapos: #front right to current
			if is_instance_valid(roominst.wallFR): roominst.wallFR.queue_free()
			if is_instance_valid(node.wallBL): node.wallBL.queue_free()
