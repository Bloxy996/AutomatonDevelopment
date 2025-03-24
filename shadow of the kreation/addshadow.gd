extends Area3D #skript for the shadow of the creator of creators
class_name CreationShadow

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

@onready var buildradius_detection: Area3D = $buildradius_detection

var type: String #the machine that is being created

func _ready() -> void: #runs when it appears
	Main.building = true #tell the main skript that something is being created
	add_child(Main.machinedata[type]['shadow'].instantiate()) #add the shadow for visuals

func _process(_delta: float) -> void: #runs on every frame
	#move it to the mouse, and keep it on the ground
	global_position = snapped(Main.main.mouse_3d_pos(), Vector3.ONE)
	global_position.y = 0
	
	Main.main.ui.buildingtext.text = str('[right]cost ', round(Main.prices[type])) #display the price when building
	
	if Input.is_action_just_pressed("R"): #rotate the shadow when R is pressed
		global_rotation_degrees.y += 90
		
	if buildradius_detection.get_overlapping_areas().has(Main.main.player.buildradius): #if the shadow is in the radius
		if Input.is_action_just_pressed('leftclick') and (not has_overlapping_bodies()) and (not Main.main.spawn.get_overlapping_areas().has(self)): #if you click to place it and it's not touching other machines or the spawn area
			var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to make a machine
			inst.type = type #set the shadow to the type needed
			Main.main.get_node('machines').add_child(inst) ##add to the machines, maybe add to a seperate shadow node instead
			inst.wait.start(Main.machinedata[type]['type_to_waittime']) #start the timer, when it finished a machine will be created
			inst.bar.max_value = Main.machinedata[type]['type_to_waittime'] #sets the max value for UI purposes
			
			#move the build shadow to the shadow's position/rotation
			inst.global_position = global_position
			inst.global_rotation = global_rotation
			
			Main.kredits -= Main.prices[type] #take away money!
			
			#indicate the change of kredits
			var indkinst: Indikator = indikator.instantiate()
			Main.main.ui.kreditindikator.add_child(indkinst)
			indkinst.start(-Main.prices[type], global_position)
			
			Main.progressions('buymachine', type, null, null, global_position)
		
		if Input.is_action_just_pressed('rightclick') and has_overlapping_bodies(): #removing machines while building
			var builderinarea: bool = false
			for node: Node3D in get_overlapping_bodies():
				if node is Builder: builderinarea = true
			
			if not builderinarea:
				for node: Node3D in get_overlapping_bodies():
					if node.is_in_group('machine'):
						if not node.is_in_group('original'):
							var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to remove a machine
							inst.mode = 'destroyer' #set all of the settings
							inst.node = node
							inst.type = Main.group_to_type(node)
							
							Main.main.get_node('machines').add_child(inst) #add the node and set the timer stuff
							inst.wait.start(Main.machinedata[inst.type]['type_to_waittime'] / Main.deletetimerspeedup)
							inst.bar.max_value = Main.machinedata[inst.type]['type_to_waittime'] / Main.deletetimerspeedup
							
							inst.global_position = global_position #move it to the correct position
							inst.global_rotation = global_rotation
							
							break
	
	if Input.is_action_just_pressed("esc") or Main.kredits - Main.prices[type] < 0: #if the user ends the creation or they dont have enough money,
		Main.main.exitdelay.start() #start the timer so the pause menu dosent show
		Main.building = false #tell main skript that the shadow is done with it's job
		queue_free() #do what needs to be done; remove it from the mortal plane of existence
