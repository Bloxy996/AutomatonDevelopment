extends Node3D #everything here can be called with any script anywhere it wants, this is the MASTER BRANCH!!

var prices: Dictionary = { ##gets the prices of each of the machines, maybe combine with machinedata?
	'kreator' : 20,
	'seller' : 20,
	'belt' : 25,
	'multiplier' : 40,
	'splitbelt' : 30
}

var machinedata: Dictionary = {
	'kreator' : {
		'originalprice' : 20,
		'shadow' : load("res://objekts/kreator/kreatorshadow.tscn"),
		'type_to_scene' : load("res://objekts/kreator/kreator.tscn"),
		'type_to_waittime' : 10
	},
	'seller' : {
		'originalprice' : 20,
		'shadow' : load("res://objekts/seller/sellershadow.tscn"),
		'type_to_scene' : load("res://objekts/seller/seller.tscn"),
		'type_to_waittime' : 10
	},
	'belt' : {
		'originalprice' : 25,
		'shadow' : load("res://objekts/konveyorbelt/beltshadow.tscn"),
		'type_to_scene' : load("res://objekts/konveyorbelt/konveyorbelt.tscn"),
		'type_to_waittime' : 5
	},
	'multiplier' : {
		'originalprice' : 40,
		'shadow' : load("res://objekts/multiplier/multipliershadow.tscn"),
		'type_to_scene' : load("res://objekts/multiplier/mutiplier.tscn"),
		'type_to_waittime' : 8
	},
	'splitbelt' : {
		'originalprice' : 30,
		'shadow' : load("res://objekts/splitbelt/splitbeltshadow.tscn"),
		'type_to_scene' : load("res://objekts/splitbelt/splitbelt.tscn"),
		'type_to_waittime' : 5
	}
}

var main: MainScene #the main scene

var kredits: float = 0 #the amount of kredits the player has from selling boxes
var level: int = 0 #the level number the player is at
var levelbar: float = 0 #the amount of points the player has in each level
var maxLB: int = 10 #the max for the levelbar

var picked: bool = false #if the player is holding a box
var building: bool = false #if something is being built
var irradicating: bool = false #if something is being destoryed
var first_time: bool = true #is true when the player opens the game for the first time

var tutorial_progress: int = 0 #progress durring the tutorial

var playername: String = ""
var displayname: String = ""

var boxes: int = 0
var maxboxes: int = 50 #the max amount of boxes that can be in the game, increases with every new expansion
var maxserveriterations: float = 20 #the max amount of times the silentwolf iterations can run until a error appears
var boxesperroom: int = 50 #the amount of boxes for every room, just so I can change the number wheverer I need it quickly

##the price and demand for ALL sellers, reset at each level up but it's a tad bit different
##also have UI for this
var progression_price: float = 15
var progression_demand: float = 8

const machinepricemultiplier: float = 1.125 ##adjust this, raises the price whenever you buy a machine by this #, you can change it w/ upgrades soon
const deletetimerspeedup: float = 2 ##the number to divide the time by when removing a machine (adjust and add a create speedup when doing upgrades)
const beltspeed: float = 4 #speed for the belt/multipliers
const deleteboxcost: float = 5 #cost to delete boxes

var factory_map: Array = [[1]] ##array for the rooms that you have in the factory, also make a machine map too for saving

func sell_box(price: int) -> void: #runs when a box is sold
	boxes += 1 #you know what this does...
	kredits += randi_range(price - 5, price + 5) #give the player credits for a box
	levelbar+=1 #increase level pts by 1
	if levelbar==maxLB: #if the level pts are up to the max,
		levelbar=0 #reset level pts
		progressions('levelup')
		level+=1 #increase the level by 1
		savegame() #seems like a good time to save your progress dosent it!

func group_to_type(node: Node3D) -> String: #amazing piece of code here
	for group: String in prices.keys():
		if node.is_in_group(group):
			return group
	return ''

##I WILL do progression price and demand!!
func progressions(mode: String, type: String = '', node: Node3D = null, room: Room = null) -> void: #universal place for all progression stuff
	match mode:
		'buymachine': #buying a machine
			prices[type] *= machinepricemultiplier #increase the price
			##keep the prices from going over the max (based on level); maybe I was going to do something different!
			##a price for a random machine goes down when you sell a box and add minimum clamp
			prices[type] = clamp(prices[type], 0, machinedata[type]['originalprice'] * maxLB)
			
		'sellmachine': #selling a machine
			#give the credits back that were lost for each of the machines
			var machinetype: String = group_to_type(node)
			
			kredits += prices[machinetype] / machinepricemultiplier
			prices[machinetype] /= ((machinepricemultiplier - 1) / 2) + 1 ##bring down the price for the machine, maybe have a floor clamp?
			prices[machinetype] = round(prices[machinetype])
		
		'levelup': #when you level up
			maxLB = round(maxLB*machinepricemultiplier) #make the max level thingy bigger
		
		'addroom': #when a room is created
			##set prices, pls update calculations
			room.expand_prices['left']['level'] = round(randf_range(4, 8) * (room.location.x + 1) ** machinepricemultiplier)
			room.expand_prices['left']['kredits'] = round(randf_range(40000, 80000) * (room.location.x + 1) ** machinepricemultiplier)
			room.expand_prices['right']['level'] = round(randf_range(4, 8) * (room.location.y + 1) ** machinepricemultiplier)
			room.expand_prices['right']['kredits'] = round(randf_range(40000, 80000) * (room.location.y + 1) ** machinepricemultiplier)

func resetgame() -> void: ##resets all the variables to their original values, update this when updating other variables
	#removes the player from the leaderboard
	var sw_result: Dictionary
	while not sw_result.has('scores'):
		sw_result = await SilentWolf.Scores.get_scores(0).sw_get_scores_complete
		if not sw_result.has('scores'): continue
		
		for score: Dictionary in sw_result.scores:
			if score["player_name"] == playername:
				SilentWolf.Scores.delete_score(score["score_id"])
	
	##probaly a better way of doing this...
	kredits = 0
	level = 0
	levelbar = 0
	maxLB = 10
	tutorial_progress = 0
	first_time = true
	progression_price = 15
	progression_demand = 8
	playername = ""
	displayname = ""
	boxes = 0
	maxboxes = boxesperroom
	factory_map = [[1]]
	
	for machine: String in prices.keys():
		prices[machine] = machinedata[machine]['originalprice']
	
	DirAccess.remove_absolute("user://savegame.save") #clears the file

func savegame(menu: bool = false) -> void: #function to save game
	#all of the variables that need to be gotten from a older save if on a menu
	var playertransform: Array = [4, 1, 4, 0]
	var nodes: Array
	
	if FileAccess.file_exists("user://savegame.save") and menu: #if this isnt the first save
		var loadfile: FileAccess = FileAccess.open("user://savegame.save", FileAccess.READ) #iterares through all the lines of the loadfile
		while loadfile.get_position() < loadfile.get_length():
			var JSONstring: String = loadfile.get_line()
			
			#get the data from the string
			var json: JSON = JSON.new()
			json.parse(JSONstring)
			var data: Dictionary = json.data
			
			#set those variables from earlier, machines are added into a list for later
			if data.has('kredits'):
				playertransform = [data['playertransform']]
			elif data.has('transform'):
				nodes.append(data)
	
	Global._updateleaderboard()
	var savefile: FileAccess = FileAccess.open("user://savegame.save", FileAccess.WRITE) #file for saving
	
	var mainsave: Dictionary = { #put all of the common varibles in a dictonary
		#normal varibles
		'kredits' : kredits,
		'boxes' : boxes, ##level, levelbar, and maxLB are dependent on boxes, so make it dependent and dont save it seperatley
		'level' : level,
		'levelbar' : levelbar,
		'maxLB' : maxLB,
		'tutorial_progress' : tutorial_progress,
		'first_time' : first_time,
		'progression_price' : progression_price,
		'progression_demand' : progression_demand,
		'playername' : playername,
		'displayname' : displayname,
		'maxboxes' : maxboxes, ##dependent on # of rooms, so update this too!
		'factory_map' : factory_map,
		'prices' : prices,
		
		#player stuff, if it's the menu it gets what's already in there
		'playertransform' : playertransform if menu else [
			main.player.global_position.x,
			main.player.global_position.y,
			main.player.global_position.z,
			main.player.global_rotation.y
		]
	}
	
	#turn it into a string and save it as a new line
	savefile.store_line(JSON.stringify(mainsave))
	
	if menu: #if on the menu, it just saves stuff from the old save
		for node: Dictionary in nodes:
			savefile.store_line(JSON.stringify(node))
	else: #call each of the node save functions from nodes that need to be saved
		for node: Node3D in get_tree().get_nodes_in_group('save'):
			if (not node.scene_file_path.is_empty()) and node.has_method('save'):
				if (not node.is_in_group('original')) and ((not box_inkreator(node)) if node is Box else true):
						savefile.store_line(JSON.stringify(node.call('save'))) #does the saving stuff like earlier
		
		main.get_node('UI/saved/AnimationPlayer').play('show') #play the animation thingy for saving games

func box_inkreator(body: Box) -> bool: #just makes sure that the box is not in a creator because you cant take those out apparently
	for boxarea: Area3D in body.detector.get_overlapping_areas():
		if boxarea.is_in_group('inkreator'): #the the area in the center of a kreator
			return true
	return false

func loadgame(menu: bool = false) -> void: #function to load the game
	if FileAccess.file_exists("user://savegame.save"): #if there's actually a save file!
		if not menu:
			for node: Node3D in get_tree().get_nodes_in_group('save'):
				if not node.is_in_group('original'):
					node.queue_free() #remove all of the nodes already in there bc they'll be replaced
		
		var savefile: FileAccess = FileAccess.open("user://savegame.save", FileAccess.READ) #iterares through all the lines of the savefile
		while savefile.get_position() < savefile.get_length():
			var JSONstring: String = savefile.get_line()
			
			#get the data from the string
			var json: JSON = JSON.new()
			json.parse(JSONstring)
			var data: Dictionary = json.data
			
			if data.has('kredits'): #if it's the first dict that has kredits (the main save)
				for key: String in data.keys():
					#set all of the variables and stuff
					if (not menu) and key == 'playertransform': 
						main.player.global_position = Vector3(data[key][0], data[key][1], data[key][2])
						main.player.global_rotation.y = data[key][3]
					
					elif key == 'factory_map': #set the factory map
						factory_map = data[key]
						if not menu: main.generate_rooms() #generate the rooms
					
					else: set(key, data[key])
			elif not menu: #if it's a node
				var inst: Node3D = load(data["filename"]).instantiate() #create the node
				
				##if data.has('original'): inst.original = data['original'] ##originals dont go through saving process anymore (maybe change it back?)
				if data.has('price'): inst.price = data['price']
				if data.has('type'): inst.type = data['type'] #build shadow loading stuff
				if data.has('mode'): inst.mode = data['mode']
				
				##add the node, I'll have to update this if I decide to save more types of things
				if inst.is_in_group('box'): main.boxes.add_child(inst)
				elif inst.is_in_group('machine') or inst.is_in_group('shadow'): main.machines.add_child(inst)
				
				##set the position and rotation and other variables that are saved, this may change
				inst.global_position = Vector3(data["transform"][0], data["transform"][1], data["transform"][2])
				inst.global_rotation.y = data["transform"][3]
				
				if data.has('paused'): inst.pause.text = data['paused'] #set's the pause state
				
				if inst is Builder:
					if inst.mode == 'builder': #start the timer stuff for the build shadow stuff
						inst.wait.start(data['timeleft'])
						inst.bar.max_value = data['waittime']
					elif inst.mode == 'destroyer': ##destroyer shadows cant be saved yet 
						##maybe find the machine based on the position? (I'll have to put machines/shadows/boxes in queues to load them in the right order though)
						inst.queue_free()
	
	Global._updateleaderboard()
