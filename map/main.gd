extends Node3D #everything here can be called with any script anywhere it wants, this is the MASTER BRANCH!!

@onready var indikator: PackedScene = preload("res://UI/indikators/indikator.tscn")

var version: String = '1.5.3 debug' ##the current version, PLS UPDATE WHEN UPDATING THE GAME (find a way to automate the updating somehow?)

var prices: Dictionary = { #gets the prices of each of the machines
	'kreator' : 20,
	'seller' : 20,
	'belt' : 25,
	'multiplier' : 40,
	'splitbelt' : 30,
	'arm' : 10
}

var machinedata: Dictionary = {
	'kreator' : {
		'originalprice' : 20,
		'shadow' : preload("res://objekts/machines/kreator/kreatorshadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/kreator/kreator.tscn"),
		'type_to_waittime' : 10,
	},
	'seller' : {
		'originalprice' : 20,
		'shadow' : preload("res://objekts//machines/seller/sellershadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/seller/seller.tscn"),
		'type_to_waittime' : 10,
	},
	'belt' : {
		'originalprice' : 25,
		'shadow' : preload("res://objekts//machines/belt/beltshadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/belt/belt.tscn"),
		'type_to_waittime' : 5,
	},
	'multiplier' : {
		'originalprice' : 40,
		'shadow' : preload("res://objekts//machines/multiplier/multipliershadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/multiplier/multiplier.tscn"),
		'type_to_waittime' : 8,
	},
	'splitbelt' : {
		'originalprice' : 30,
		'shadow' : preload("res://objekts//machines/splitbelt/splitbeltshadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/splitbelt/splitbelt.tscn"),
		'type_to_waittime' : 5,
	},
	'arm' : {
		'originalprice' : 10,
		'shadow' : preload("res://objekts//machines/arm/armshadow.tscn"),
		'type_to_scene' : preload("res://objekts//machines/arm/arm.tscn"),
		'type_to_waittime' : 7,
	}
}

var settings: Dictionary = { #all of the settings for the game
	'indikator' : {
		'kredit' : true,
		'multiplier' : true
	},
	'daynight' : true,
	'sunvalue': 0.0
}

var main: MainScene #the main scene

var kredits: int = 0 #the amount of kredits the player has from selling boxes
var level: int = 0 #the level number the player is at
var levelbar: float = 0 #the amount of points the player has in each level
var maxLB: int = 10 #the max for the levelbar

var picked: bool = false #if the player is holding a box
var building: bool = false #if something is being built
var irradicating: bool = false #if something is being destoryed
var settingbehavior: bool = false #if arm behaviours are being set
var first_time: bool = true #is true when the player opens the game for the first time

var playername: String = ""
var displayname: String = ""

var boxes: int = 0
var maxboxes: int = 50 #the max amount of boxes that can be in the game, increases with every new expansion
var maxserveriterations: int = 20 #the max amount of times the silentwolf iterations can run until a error appears
var boxesperroom: int = 50 #the amount of boxes for every room, just so I can change the number wheverer I need it quickly
var Tprogress: int = 0 #how much progress is made through the tutorial

var progression_price: float = 15
var progression_demand: float = 8

const machinepricemultiplier: float = 1.125 #adjust this, raises the price whenever you buy a machine by this #
const deletetimerspeedup: float = 2 #the number to divide the time by when removing a machine
const beltspeed: float = 4 #speed for the belt/multipliers
const deleteboxcost: int = 5 #cost to delete boxes
const buildtimediff: float = 2 #the random amount of seconds added/removed from build timers
const armspeed: float = 8 #the number that is multiplied by delta when lerping the arm towards the target position
const grabspeed: float = 16 #the lerp of the box to the player's hand by delta
const grabdist: float = 2 #the distance where the player can grab boxes
const aligndivisor: float = 1 #the number that divides the align force for moving boxes to the center of belts/multipliers/etc.
const kreateboxmintime: float = 3.0 #the min and max times that are put into the kreator for making boxes
const kreateboxmaxtime: float = 6.0
const multiplierpricecap: float = 100 #the max # for multiplying boxes through a multiplier
const playerspeed: float = 7.5 #the speed for the player
const playerjumpvel: float = 100 #the jump velocity for the player
const minzoom: float = 2 #the min and max clamps for zoom
const maxzoom: float = 40
const selltimediff: float = 2 #the random amount of seconds added/removed from sell timers
const sellpricediff: int = 5 #the random amount of kredits added/removed from selling boxes
const boxestowarning: float = 20 #amount of boxes to the limit until the warning shows
const builderbardistancevisible: float = 4 #distance where you can see the bar thingy on builders

const playerresetpos: Vector3 = Vector3(4, 1, 4) #the reset position of the player
##const daynightcyclespeed: Vector3 = Vector3(2, 1, 0) * 0.001 #the vector that is added to the current rotation of the sun
const defaultsunrot: Vector3 = Vector3(-60, 135, 0) #the default rotation to turn the sun to

var factory_map: Dictionary = { #dict for the rooms that you have in the factory
	'[0, 0]' : null #the position, and then the expansion prices
}

func sell_box(price: int, pos: Vector3) -> void: #runs when a box is sold
	boxes += 1 #you know what this does...
	var gained: int = randi_range(price - sellpricediff, price + sellpricediff)
	kredits += gained #give the player credits for a box
	
	#indicate the change of kredits
	if Main.settings.indikator.kredit:
		var indkinst: Indikator = indikator.instantiate()
		main.ui.kreditindikator.add_child(indkinst)
		indkinst.start(gained, pos)
	
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

func progressions(mode: String, type: String = '', node: Node3D = null, room: Room = null, pos: Vector3 = Vector3.ZERO) -> void: #universal place for all progression stuff
	match mode:
		'buymachine': #buying a machine
			prices[type] *= machinepricemultiplier #increase the price
			#keep the prices from going over the max (based on level)
			prices[type] = clampi(prices[type], 0, machinedata[type]['originalprice'] * maxLB)
			
		'sellmachine': #selling a machine
			#give the credits back that were lost for each of the machines
			var machinetype: String = group_to_type(node)
			
			kredits += prices[machinetype] / machinepricemultiplier
			
			#indicate the change of kredits
			if Main.settings.indikator.kredit:
				var indkinst: Indikator = indikator.instantiate()
				main.ui.kreditindikator.add_child(indkinst)
				indkinst.start(prices[machinetype] / machinepricemultiplier, pos)
			
			prices[machinetype] /= ((machinepricemultiplier - 1) / 2) + 1 #bring down the price for the machine
			prices[machinetype] = round(prices[machinetype])
		
		'levelup': #when you level up
			maxLB = round(maxLB*machinepricemultiplier) #make the max level thingy bigger
		
		'addroom': #when a room is created
			#set prices
			room.expand_prices['left']['level'] = round(randf_range(4, 8) * (room.location.x + 1) ** machinepricemultiplier)
			room.expand_prices['left']['kredits'] = round(randf_range(40000, 80000) * (room.location.x + 1) ** machinepricemultiplier)
			room.expand_prices['right']['level'] = round(randf_range(4, 8) * (room.location.y + 1) ** machinepricemultiplier)
			room.expand_prices['right']['kredits'] = round(randf_range(40000, 80000) * (room.location.y + 1) ** machinepricemultiplier)

func resetgame() -> void: #resets all the variables to their original values
	DirAccess.remove_absolute("user://savegame.save") #clears the file
	
	#removes the player from the leaderboard
	var sw_result: Dictionary
	while not sw_result.has('scores'):
		sw_result = await SilentWolf.Scores.get_scores_by_player(playername).sw_get_player_scores_complete
		if not sw_result.has('scores'): continue
		
		while true:
			var sw_result2: Dictionary = await SilentWolf.Scores.get_scores_by_player(playername).sw_get_player_scores_complete
			if sw_result2.scores.is_empty(): break
			
			for score: Dictionary in sw_result2.scores:
				await SilentWolf.Scores.delete_score(score.score_id).sw_delete_score_complete
	
	kredits = 0
	level = 0
	levelbar = 0
	maxLB = 10
	first_time = true
	progression_price = 15
	progression_demand = 8
	playername = ""
	displayname = ""
	boxes = 0
	maxboxes = boxesperroom
	factory_map = {'[0, 0]' : null}
	
	settings = { ##update with actual settings always
		'indikator' : {
			'kredit' : true,
			'multiplier' : true
		},
		'daynight' : true,
		'sunvalue' : 0.0
	}
	
	for machine: String in prices.keys():
		prices[machine] = machinedata[machine]['originalprice']

func saveversion() -> void: #seperate func to save the game version
	var savedversion: FileAccess = FileAccess.open("user://version.save", FileAccess.WRITE) #file for the version
	savedversion.store_line(JSON.stringify({'version' : version})) #save the version onto the file

func savegame(menu: bool = false) -> void: #function to save game
	saveversion()
	
	#all of the variables that need to be gotten from a older save if on a menu
	var playertransform: Array = [playerresetpos.x, playerresetpos.y, playerresetpos.z, 0]
	var lightdir: Array = [defaultsunrot.x, defaultsunrot.y, defaultsunrot.z]
	var tutorialvisible: bool = true
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
				playertransform = data['playertransform']
				lightdir = data['lightdir']
				tutorialvisible = data['tutorialvisible']
			elif data.has('transform'):
				nodes.append(data)
	
	Global._updateleaderboard()
	var savefile: FileAccess = FileAccess.open("user://savegame.save", FileAccess.WRITE) #file for saving
	
	var mainsave: Dictionary = { #put all of the common varibles in a dictonary
		#normal varibles
		'kredits' : kredits,
		'boxes' : boxes, #level, levelbar, and maxLB are dependent on boxes
		#'level' : level,
		#'levelbar' : levelbar,
		#'maxLB' : maxLB,
		'first_time' : first_time,
		'progression_price' : progression_price,
		'progression_demand' : progression_demand,
		'playername' : playername,
		'displayname' : displayname,
		'factory_map' : factory_map, #maxboxes is dependent on the # of rooms in the factory
		#'maxboxes' : maxboxes,
		'prices' : prices,
		'tutorialvisible' : tutorialvisible if menu else main.ui.tutorial.text.visible,
		'settings' : settings,
		
		#player stuff, if it's the menu it gets what's already in there
		'playertransform' : playertransform if menu else [
			main.player.global_position.x,
			main.player.global_position.y,
			main.player.global_position.z,
			main.player.global_rotation.y
		],
		
		#day/night cycle stuff
		'lightdir' : lightdir if menu else [
			main.light.rotation_degrees.x,
			main.light.rotation_degrees.y,
			main.light.rotation_degrees.z
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
	if FileAccess.file_exists("user://version.save"): #if there is a version file
		var versionfile: FileAccess = FileAccess.open("user://version.save", FileAccess.READ) #open the file to read it
		var savedversion: String = JSON.parse_string(versionfile.get_line()).version
		if mainversion(savedversion) != mainversion(version):  #if the main versions are the same (excluding the # after the last dot),
			resetgame() #reset the game and reload the scene
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	else: #if there's none, please make one
		saveversion()
	
	if FileAccess.file_exists("user://savegame.save"): #if there's actually a save file!
		if not menu:
			for node: Node3D in get_tree().get_nodes_in_group('save'):
				if not node.is_in_group('original'):
					node.queue_free() #remove all of the nodes already in there bc they'll be replaced
			Main.main.machines.reset_map() #resets the map bc there's no machines that arent original
		
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
					if not menu:
						if key == 'playertransform': 
							main.player.global_position = Vector3(data[key][0], data[key][1], data[key][2])
							main.player.global_rotation.y = data[key][3]
						elif key == 'lightdir':
							main.light.rotation_degrees = Vector3(data[key][0], data[key][1], data[key][2])
						elif key == 'tutorialvisible':
							main.ui.tutorial.text.visible = data[key]
							main.ui.tutorial.set_process(data[key])
					
					else: set(key, data[key])
			elif not menu: #if it's a node
				var inst: Node3D = load(data["filename"]).instantiate() #create the node
				if inst.has_method('primaryload'): inst.primaryload(data)
				
				#add the node
				if inst.is_in_group('box'): main.boxes.add_child(inst)
				elif inst.is_in_group('machine') or inst.is_in_group('shadow'): main.machines.add_child(inst)
				if inst.has_method('secondaryload'): inst.secondaryload(data)
				
				if inst is CollisionShape3D: Main.main.machines.map[Vector2(inst.global_position.x, inst.global_position.z)] = inst #add to the map
		
		setboxesdependencies(boxes) #since level, levelbar, and maxLB are dependent on the boxes you sell, set them from boxes
		if not menu: 
			main.generate_rooms() #generate the rooms
			maxboxes = main.factory.get_child_count() * boxesperroom #set maxboxes since it's dependent
	else :
		first_time = true #it's the first time if there's no save file
	
	if version.contains('debug'): #this will save me so many troubles
		level = 100
		kredits = 1000000000
	
	Global._updateleaderboard()

func mainversion(longversion : String) -> String:
	var result: String = ''
	var foundfirstdot: bool = false
	for i: String in longversion:
		if i == '.':
			if foundfirstdot: break
			else: foundfirstdot = true
		result += i
	return result

func setboxesdependencies(calcboxes: int) -> void:
	var calclevel: int = 0 #recreates the beginning
	var calcmaxLB: int = 10
	
	while calcboxes >= calcmaxLB: #until you cannot fill the levelbar anymore
		calcboxes -= calcmaxLB #take away the max amount of boxes to increase the level
		calclevel += 1
		calcmaxLB = round(calcmaxLB * machinepricemultiplier) #increase the maxLB like how it usualy wound be
	
	#set all of the variables after because they should be determined now
	levelbar = calcboxes
	level = calclevel
	maxLB = calcmaxLB
