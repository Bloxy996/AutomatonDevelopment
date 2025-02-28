extends StaticBody3D
class_name Room

##show progress to get to expansion with 2 progressbars behind the button

@onready var wallFL: CollisionShape3D = $wallFL
@onready var wallFR: CollisionShape3D = $wallFR
@onready var wallBL: CollisionShape3D = $hidden/wallBL
@onready var wallBR: CollisionShape3D = $hidden/wallBR

@onready var expandLM: Marker3D = $wallFL/expandL
@onready var expandRM: Marker3D = $wallFR/expandR
@onready var detectL: Area3D = $wallFL/Area3D
@onready var detectR: Area3D = $wallFR/Area3D
@onready var buttonL: Button = $wallFL/expandL/Button
@onready var buttonR: Button = $wallFR/expandR/Button

var location: Vector2 = Vector2(0, 0) #location on the factory map array

var expand_prices: Dictionary = { #prices needed to expand
	'left' : {
		'level' : 0,
		'kredits' : 0
	},
	'right' : {
		'level' : 0,
		'kredits' : 0
	}
}

func _ready() -> void:
	Main.progressions('addroom', '', null, self)
	
	#set the buttons
	expandLM.get_node('Button').text = str(
		'expansion at
		level ', expand_prices['left']['level'], '
		', expand_prices['left']['kredits'], ' kredits'
	)
	expandRM.get_node('Button').text = str(
		'expansion at
		level ', expand_prices['right']['level'], '
		', expand_prices['right']['kredits'], ' kredits'
	)
	
	#buttons will show/hide when their walls are hovered over
	detectL.mouse_entered.connect(func() -> void: buttonL.show())
	detectL.mouse_exited.connect(func() -> void: buttonL.hide())
	detectR.mouse_entered.connect(func() -> void: buttonR.show())
	detectR.mouse_exited.connect(func() -> void: buttonR.hide())

func _process(_delta: float) -> void:
	if is_instance_valid(expandLM): set_button(expandLM, expand_prices['left'])
	if is_instance_valid(expandRM): set_button(expandRM, expand_prices['right'])
	
	var usable_walls: Array[StaticBody3D] = [] #make an array of the walls that the room can use and show the meshes too
	if is_instance_valid(wallBL): usable_walls.append(wallBL.get_node('mesh/StaticBody3D'))
	if is_instance_valid(wallBR): usable_walls.append(wallBR.get_node('mesh/StaticBody3D'))
	if is_instance_valid(wallFL): usable_walls.append(wallFL.get_node('mesh/StaticBody3D'))
	if is_instance_valid(wallFR): usable_walls.append(wallFR.get_node('mesh/StaticBody3D'))
	
	for wall: StaticBody3D in usable_walls: #show/hide the walls based on whether they're in the way of the player or not
		#whether the wall should be visible or not
		var visiblility: bool = wall.get_node('Marker3D').global_position.x > Main.main.player.global_position.x or wall.get_node('Marker3D').global_position.z > Main.main.player.global_position.z
		if wall.get_parent().visible and (not visiblility): wall.get_node("../AnimationPlayer").play('hide') #if the wall needs to hide
		if (not wall.get_parent().visible) and visiblility: wall.get_node("../AnimationPlayer").play('show') #if the wall needs to show
		
		#wall.get_parent().visible = visiblility

func set_button(marker : Marker3D, prices : Dictionary) -> void:
	marker.get_node('Button').global_position = get_viewport().get_camera_3d().unproject_position(marker.global_position) - (marker.get_node('Button').size / 2) #move to the wall
	marker.get_node('Button/ProgressBar').value = 1 if Main.level >= prices['level'] and Main.kredits >= prices['kredits'] else 0 ##turn the button green when you can buy the room, maybe change to an actual progress bar?

func _on_buttonL_pressed() -> void: #expand to the right
	if Main.level >= expand_prices['left']['level'] and Main.kredits >= expand_prices['left']['kredits']:
		Main.kredits -= expand_prices['left']['kredits']
		Main.main.add_room(location + Vector2(1, 0))

func _on_buttonR_pressed() -> void: #expand to the left
	if Main.level >= expand_prices['right']['level'] and Main.kredits >= expand_prices['right']['kredits']:
		Main.kredits -= expand_prices['right']['kredits']
		Main.main.add_room(location + Vector2(0, 1))
