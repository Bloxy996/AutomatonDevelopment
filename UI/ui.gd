extends Control #this is the script for ALL of the UI
class_name UI

@onready var progress: ProgressBar = $ProgressBar
@onready var level: Label = $level
@onready var kredits: Label = $kredits
@onready var xpreq: Label = $xpreq
@onready var toomanyboxes: Label = $toomanyboxes
@onready var TMBblinker: Timer = $toomanyboxes/blinker
@onready var armtutorial: Control = $armtutorial
@onready var building: Control = $building
@onready var buildingtext: RichTextLabel = $building/detail
@onready var kreditindikator: Control = $kreditindikator

@onready var tutorial: Tutorial = $tutorial

var kreditlerp: float  = 0 #for lerping

func _process(delta: float) -> void: #runs every microsecond because this is a really fast computer
	#set the value to the amount of level pts (and lerp it) and the max to the max level pts you can get
	progress.value = lerpf(progress.value, Main.levelbar, delta * 4)
	progress.max_value=Main.maxLB
	kreditlerp = lerpf(kreditlerp, Main.kredits, delta * 4)
	kredits.text = str(int(kreditlerp), ' kredits') #set the credits to the amount of credits and lerp it
	level.text = str("level ", Main.level) #set the level UI to the level you are at
	xpreq.text = str(int(Main.levelbar), '/', int(Main.maxLB), ' boxes') #show the player how many boxes they have and how much they need (the max) to level up
	
	if Main.maxboxes - Main.main.boxamount <= 20: #if a warning needs to be shown
		if TMBblinker.is_stopped(): #the binking stuff code
			TMBblinker.start()
			toomanyboxes.visible = not toomanyboxes.visible
		
		if Main.maxboxes - Main.main.boxamount < 0: #over the limit warning
			toomanyboxes.modulate = Color.RED
			toomanyboxes.text = str(int(abs(Main.maxboxes - Main.main.boxamount)), ' BOXES OVER THE LIMIT, PLEASE REMOVE BOXES TO REACTIVATE THE CREATORS!')
		elif Main.maxboxes - Main.main.boxamount == 0: #at the limit warning
			toomanyboxes.modulate = Color.RED
			toomanyboxes.text = 'YOU HAVE REACHED THE MAX LIMIT, PLEASE REMOVE BOXES TO REACTIVATE THE CREATORS!'
		else: #near the limit warning
			toomanyboxes.modulate = Color.ORANGE_RED
			toomanyboxes.text = str(int(Main.maxboxes - Main.main.boxamount), ' BOXES TO THE LIMIT, BE CAREFUL!')
	else: #hide if there is no need for a warning
		toomanyboxes.hide()
	
	armtutorial.visible = Main.settingbehavior #shows a tutorial when setting behaviours
	building.visible = Main.building #shows the building UI when building
