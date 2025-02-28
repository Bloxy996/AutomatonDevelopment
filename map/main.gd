extends Node3D #everything here can be called with any script anywhere it wants, this is the MASTER BRANCH!!

var kredits: float = 0 #the amount of kredits the player has from selling boxes
var level: int = 0 #the level number the player is at
var levelbar: float = 0 #the amount of points the player has in each level
var maxLB: int = 10 #the max for the levelbar

var picked: bool = false #if the player is holding a box
var building: bool = false #if something is being built
var irradicating: bool = false #if something is being destoryed

var tutorial_progress: int = 0 #progress durring the tutorial

var playername: String = ""
var displayname: String = ""

var boxes: int = 0
var maxboxes: int = 50 #the max amount of boxes that can be in the game, increases with every new expansion
var maxserveriterations: float = 20 #the max amount of times the silentwolf iterations can run until a error appears
var boxesperroom: int = 50 #the amount of boxes for every room, just so I can change the number wheverer I need it quickly

var main: MainScene #the main scene

var prices: Dictionary = { #gets the prices of each of the machines
	'kreator' : 20,
	'seller' : 20,
	'belt' : 25,
	'multiplier' : 40
}

var first_time: bool = true #is true when the player opens the game for the first time

##the price and demand for ALL sellers, reset at each level up but it's a tad bit different
##also have UI for this
var progression_price: float = 15
var progression_demand: float = 8

var machinepricemultiplier: float = 1.125 ##adjust this, raises the price whenever you buy a machine by this #, you can change it w/ upgrades soon

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

##I WILL do progression price and demand!!
func progressions(mode: String, type: String = '', node: Node3D = null, room: Room = null) -> void: #universal place for all progression stuff
	match mode:
		'buymachine': #buying a machine
			Main.prices[type] *= Main.machinepricemultiplier #increase the price
			##keep the prices from going over the max (based on level); maybe I was going to do something different!
			##a price for a random machine goes down when you sell a box and add minimum clamp
			Main.prices[type] = clamp(Main.prices[type], 0, {'kreator' : 20, 'seller' : 20, 'belt' : 25, 'multiplier' : 40}[type] * ((Main.level + 1) ** (Main.machinepricemultiplier ** 1.5)))
		'sellmachine': #selling a machine
			#give the credits back that were lost for each of the machines
			if node.is_in_group('kreator'): Main.kredits += Main.prices['kreator'] / (Main.machinepricemultiplier * 2)
			elif node.is_in_group('seller'): Main.kredits += Main.prices['seller'] / (Main.machinepricemultiplier * 2)
			elif node.is_in_group('belt'): Main.kredits += Main.prices['belt'] / (Main.machinepricemultiplier * 2)
			elif node.is_in_group('multiplier'): Main.kredits += Main.prices['multiplier'] / (Main.machinepricemultiplier * 2)
		'levelup': #when you level up
			maxLB = round(maxLB*machinepricemultiplier) #make the max level thingy bigger
		'addroom': #when a room is created
			##set prices, pls update calculations
			room.expand_prices['left']['level'] = int(randf_range((room.location.x + 1) * 3, (room.location.x + 1) * 6))
			room.expand_prices['left']['kredits'] = int(randf_range((room.location.x + 1) * 30000, (room.location.x + 1) * 60000))
			room.expand_prices['right']['level'] = int(randf_range((room.location.y + 1) * 3, (room.location.y + 1) * 6))
			room.expand_prices['right']['kredits'] = int(randf_range((room.location.y + 1) * 30000, (room.location.y + 1) * 60000))


func resetgame() -> void: ##resets all the variables to their original values, update this when updating other variables
	#removes the player from the leaderboard
	var sw_result: Dictionary
	while not sw_result.has('scores'):
		sw_result = await SilentWolf.Scores.get_scores(0).sw_get_scores_complete
		if not sw_result.has('scores'): continue
		
		for score: Dictionary in sw_result.scores:
			if score["player_name"] == Main.playername:
				SilentWolf.Scores.delete_score(score["score_id"])
	
	kredits = 0
	level = 0
	levelbar = 0
	maxLB = 10
	tutorial_progress = 0
	first_time = true
	progression_price = 15
	progression_demand = 8
	machinepricemultiplier = 1.5
	playername = ""
	displayname = ""
	boxes = 0
	maxboxes = boxesperroom
	factory_map = [[1]]
	
	prices = {
		'kreator' : 20,
		'seller' : 20,
		'belt' : 25,
		'multiplier' : 40
	}
	
	DirAccess.remove_absolute("user://savegame.save") #clears the file

func savegame(menu: bool = false) -> void: #function to save game
	#all of the variables that need to be gotten from a older save if on a menu
	var player_posX: float = 4
	var player_posY: float = 1
	var player_posZ: float = 4
	var player_rotY: float
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
				player_posX = data['player_posX']
				player_posY = data['player_posY']
				player_posZ = data['player_posZ']
				player_rotY = data['player_rotY']
			elif data.has('rotY'):
				nodes.append(data)
	
	Global._updateleaderboard()
	var savefile: FileAccess = FileAccess.open("user://savegame.save", FileAccess.WRITE) #file for saving
	
	var mainsave: Dictionary = { #put all of the common varibles in a dictonary
		#normal varibles
		'kredits' : kredits,
		'level' : level,
		'levelbar' : levelbar,
		'maxLB' : maxLB,
		'tutorial_progress' : tutorial_progress,
		'first_time' : first_time,
		'progression_price' : progression_price,
		'progression_demand' : progression_demand,
		'machinepricemultiplier' : machinepricemultiplier,
		'playername' : playername,
		'displayname' : displayname,
		'boxes' : boxes,
		'maxboxes' : maxboxes,
		'factory_map' : factory_map,
		
		#player stuff, if it's the menu it gets what's already in there
		'player_posX' : player_posX if menu else main.get_node('player').global_position.x,
		'player_posY' : player_posY if menu else main.get_node('player').global_position.y,
		'player_posZ' : player_posZ if menu else main.get_node('player').global_position.z,
		'player_rotY' : player_rotY if menu else main.get_node('player').global_rotation.y,
		
		#prices
		'kreator' : prices['kreator'],
		'seller' : prices['seller'],
		'belt' : prices['belt'],
		'multiplier' : prices['multiplier']
	}
	
	#turn it into a string and save it as a new line
	savefile.store_line(JSON.stringify(mainsave))
	
	if menu: #if on the menu, it just saves stuff from the old save
		for node: Dictionary in nodes:
			savefile.store_line(JSON.stringify(node))
	else: #call each of the node save functions from nodes that need to be saved
		for node: Node3D in get_tree().get_nodes_in_group('machine') + get_tree().get_nodes_in_group('box') + get_tree().get_nodes_in_group('shadow'):
			if (not node.scene_file_path.is_empty()) and node.has_method('save'):
				if not node.is_in_group('original'):
					savefile.store_line(JSON.stringify(node.call('save'))) #does the saving stuff like earlier
		
		main.get_node('UI/saved/AnimationPlayer').play('show') #play the animation thingy for saving games

func loadgame(menu: bool = false) -> void: #function to load the game
	if FileAccess.file_exists("user://savegame.save"): #if there's actually a save file!
		if not menu:
			for node: Node3D in get_tree().get_nodes_in_group('machine') + get_tree().get_nodes_in_group('box') + get_tree().get_nodes_in_group('shadow'):
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
					if (not menu) and key == 'player_posX': main.get_node('player').global_position.x = data[key]
					elif (not menu) and key == 'player_posY': main.get_node('player').global_position.y = data[key]
					elif (not menu) and key == 'player_posZ': main.get_node('player').global_position.z = data[key]
					elif (not menu) and key == 'player_rotY': main.get_node('player').global_rotation.y = data[key]
					
					elif key == 'kreator': prices['kreator'] = data[key]
					elif key == 'seller': prices['seller'] = data[key]
					elif key == 'belt': prices['belt'] = data[key]
					elif key == 'multiplier': prices['multiplier'] = data[key]
					
					elif key == 'factory_map': #set the factory map
						factory_map = data[key]
						if not menu: main.generate_rooms() #generate the rooms
					
					else: set(key, data[key])
			elif (not menu) and is_instance_valid(main.get_node(data["parent"])): ##if it's a node and the parent exists, probaly find a better way to save the parent then
				var inst: Node3D = load(data["filename"]).instantiate() #create the node
				
				##dont add a box if it's not part of the main box node (maybe I should fix this instead of js not adding them!)
				if inst is Box and main.get_node(data["parent"]).name != 'boxes':
					continue
				
				if data.has('original'): inst.original = data['original'] ##originals dont go through saving process anymore (maybe change it back?)
				if data.has('price'): inst.price = data['price']
				if data.has('type'): inst.type = data['type'] #build shadow loading stuff
				if data.has('mode'): inst.mode = data['mode']
				
				main.get_node(data["parent"]).add_child(inst) #add the node
				
				##set the position and rotation and other variables that are saved, this may change
				inst.global_position = Vector3(data["posX"], data["posY"], data["posZ"])
				inst.global_rotation.y = data["rotY"]
				
				if data.has('paused'): inst.pause.text = data['paused'] #set's the pause state
				
				if inst is Builder:
					if inst.mode == 'builder': #start the timer stuff for the build shadow stuff
						inst.wait.start(data['timeleft'])
						inst.bar.max_value = data['waittime']
					elif inst.mode == 'destroyer': ##destroyer shadows cant be saved yet 
						##maybe find the machine based on the position? (I'll have to put machines/shadows/boxes in queues to load them in the right order though)
						inst.queue_free()
	
	Global._updateleaderboard()
