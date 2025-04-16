extends Area3D #skript for the shadow of the creator of creators
class_name CreationShadow

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var buildradius_detection: Area3D = $buildradius_detection

var type: String #the machine that is being created

var buildradius_overlapping_areas: Array
var overlapping_bodies: Array

func _ready() -> void: #runs when it appears
	Main.main.start_building.emit() #tell the main skript that something is being created
	add_child(Main.machinedata[type]['shadow'].instantiate()) #add the shadow for visuals

func _process(_delta: float) -> void: #runs on every frame
	if Input.is_action_just_pressed("esc") or Main.kredits - Main.prices[type] < 0: #if the user ends the creation or they dont have enough money,
		Main.main.exitdelay.start() #start the timer so the pause menu dosent show
		Main.main.stop_building.emit() #tell main skript that the shadow is done with it's job
		queue_free() #do what needs to be done; remove it from the mortal plane of existence
		return
	
	update_overlaps()
	
	#move it to the mouse, and keep it on the ground
	global_position = snapped(Main.main.mouse3Dpos, Vector3.ONE)
	global_position.y = 0
	
	Main.main.ui.buildingtext.text = str('[right]cost ', int(Main.prices[type])) #display the price when building

func _input(event: InputEvent) -> void:
	update_overlaps()
	
	if event.is_action_pressed("R"): #rotate the shadow when R is pressed
		global_rotation_degrees.y += 90
		
	if buildradius_overlapping_areas.has(Main.main.player.buildradius): #if the shadow is in the radius
		if event.is_action_pressed('leftclick') and overlapping_bodies.is_empty() and (not Main.main.spawn.get_overlapping_areas().has(self)) and clear_for_arm(): #if you click to place it and it's not touching other machines or the spawn area or near another arm if it's an arm
			place_machine()
		
		elif event.is_action_pressed('rightclick') and not overlapping_bodies.is_empty(): #removing machines while building
			if not builderpresent():
				for node: Node3D in overlapping_bodies:
					if node.is_in_group('machine') and not node.is_in_group('original'):
						remove_machine(node)
						break

func update_overlaps() -> void:
	buildradius_overlapping_areas = buildradius_detection.get_overlapping_areas()
	overlapping_bodies = get_overlapping_bodies()

func clear_for_arm() -> bool: #if there's another arm in the area
	if type == 'arm': #only does this if the type is an arm
		for area : Area3D in buildradius_overlapping_areas:
			if area.is_in_group('arm_teritory') and area.get_parent().get_parent() != self: return false #if any of the areas are in another's arm territory, return false
		return true
	else: return true

func place_machine() -> void:
	var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to make a machine
	inst.type = type #set the shadow to the type needed
	Main.main.machines.add_child(inst) #add to the machines
	
	var buildtime: float = Main.machinedata[inst.type].type_to_waittime + randf_range(-Main.buildtimediff, Main.buildtimediff)
	inst.wait.start(buildtime) #start the timer, when it finished a machine will be created
	inst.bar.max_value = buildtime #sets the max value for UI purposes
	
	#move the build shadow to the shadow's position/rotation
	inst.global_position = global_position
	inst.global_rotation = global_rotation
	
	Main.kredits -= Main.prices[type] #take away money!
	
	#indicate the change of kredits
	if Main.settings.indikator.kredit:
		var indkinst: Indikator = indikator.instantiate()
		Main.main.ui.kreditindikator.add_child(indkinst)
		indkinst.start(-Main.prices[type], global_position)
		
	Main.progressions('buymachine', type, null, null, global_position)

func remove_machine(node : StaticBody3D) -> void:
	var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to remove a machine
	inst.mode = 'destroyer' #set all of the settings
	inst.node = node
	inst.type = Main.group_to_type(node)
	
	Main.main.machines.add_child(inst) #add the node and set the timer stuff
	var buildtime: float = Main.machinedata[inst.type].type_to_waittime + randf_range(-Main.buildtimediff, Main.buildtimediff)
	inst.wait.start(buildtime / Main.deletetimerspeedup)
	inst.bar.max_value = buildtime / Main.deletetimerspeedup
	
	inst.global_position = global_position #move it to the correct position
	inst.global_rotation = global_rotation

func builderpresent() -> bool:
	return !overlapping_bodies.filter(func(node : Node3D) -> bool: 
		return node is Builder).is_empty()
