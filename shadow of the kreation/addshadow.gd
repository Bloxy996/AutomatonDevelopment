extends Area3D #skript for the shadow of the creator of creators
class_name CreationShadow

@onready var shadows: Node3D = $shadows #all of the shadow meshes
@onready var buildradius_detection: Area3D = $buildradius_detection

var type: String #the machine that is being created

func _ready() -> void: #runs when it appears
	Main.building = true #tell the main skript that something is being created
	for shadow: Node3D in shadows.get_children(): #set the shadow mesh to the one of the type of the machine
		if shadow.name == type:
			shadow.show()
			break

func _process(_delta: float) -> void: #runs on every frame
	#move it to the mouse, and keep it on the ground
	global_position = snapped(Main.main.mouse_3d_pos(), Vector3.ONE)
	global_position.y = 0
	
	if Input.is_action_just_pressed("R"): #rotate the shadow when R is pressed
		global_rotation_degrees.y += 90
		
	if buildradius_detection.get_overlapping_areas().has(Main.main.player.buildradius): #if the shadow is in the radius
		if Input.is_action_just_pressed('leftclick') and (not has_overlapping_bodies()) and (not Main.main.spawn.get_overlapping_areas().has(self)): #if you click to place it and it's not touching other machines or the spawn area
			var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to make a machine
			inst.type = type #set the shadow to the type needed
			Main.main.get_node('machines').add_child(inst) ##add to the machines, maybe add to a seperate shadow node instead
			inst.wait.start(Main.main.type_to_waittime[type]) #start the timer, when it finished a machine will be created
			inst.bar.max_value = Main.main.type_to_waittime[type] #sets the max value for UI purposes
			
			#move the build shadow to the shadow's position/rotation
			inst.global_position = global_position
			inst.global_rotation = global_rotation
			
			Main.kredits -= Main.prices[type] #take away money!
			Main.prices[type] *= Main.machinepricemultiplier #increase the price
			
			##keep the prices from going over the max (based on level); maybe I was going to do something different!
			var maxprice: float = (Main.level + 1) ** (Main.machinepricemultiplier ** 1.5)
			##maybe the price multiplied by the maxprice should be the current machine price you leveled up at
			##a price for a random machine goes down when you sell a box??
			##add minimum clamp
			Main.prices['kreator'] = clamp(Main.prices['kreator'], 0, 20 * maxprice)
			Main.prices['seller'] = clamp(Main.prices['seller'], 0, 20 * maxprice)
			Main.prices['belt'] = clamp(Main.prices['belt'], 0, 25 * maxprice)
			Main.prices['multiplier'] = clamp(Main.prices['multiplier'], 0, 40 * maxprice)
		
		if Input.is_action_just_pressed('rightclick') and has_overlapping_bodies(): #removing machines while building
			var builderinarea: bool = false
			for node: Node3D in get_overlapping_bodies():
				if node is Builder: builderinarea = true
			
			if not builderinarea:
				for node: Node3D in get_overlapping_bodies():
					if node.is_in_group('machine'):
						if not node.is_in_group('original'):
							var inst: Builder = Main.main.buildshadow.instantiate() #create the builder to make a machine
							inst.mode = 'destroyer' #set all of the settings
							inst.node = node
							inst.type = 'kreator' if node.is_in_group('kreator') else ('seller' if node.is_in_group('seller') else ('belt' if node.is_in_group('belt') else 'multiplier'))
							
							Main.main.get_node('machines').add_child(inst) #add the node and set the timer stuff
							inst.wait.start(Main.main.type_to_waittime[inst.type])
							inst.bar.max_value = Main.main.type_to_waittime[inst.type]
							
							inst.global_position = global_position #move it to the correct position
							inst.global_rotation = global_rotation
							
							break
	
	if Input.is_action_just_pressed("enter") or Main.kredits - Main.prices[type] < 0: #if the user ends the creation or they dont have enough money,
		Main.building = false #tell main skript that the shadow is done with it's job
		queue_free() #do what needs to be done; remove it from the mortal plane of existence
		
		if Main.tutorial_progress == 7: #move onto the next tutorial text
			Main.tutorial_progress += 1
