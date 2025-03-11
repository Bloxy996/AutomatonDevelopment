extends Control #this is the script for ALL of the UI
class_name UI

@onready var progress: ProgressBar = $ProgressBar
@onready var level: Label = $level
@onready var kredits: Label = $kredits
@onready var xpreq: Label = $xpreq
@onready var tutorial: RichTextLabel = $tutorial
@onready var toomanyboxes: Label = $toomanyboxes
@onready var TMBblinker: Timer = $toomanyboxes/blinker

var kreditlerp: float  = 0 #for lerping

var tutorial_texts: Array = [ ##all of the tutorial texts, adjust text size tho
	'WASD to move, SPACE to jump, ESC to pause, and scroll to zoom the camera
to start, walk over to the CREATOR machine on the left and press CREATE A BOX to create a BOX',
	'after a few seconds, a BOX should appear
when it does, pick it up by clicking on it',
	'walk over to the SELLER machine on the right and drop your BOX by clicking on it again
this takes a bit of effort, dosent it? you can also right click on it to delete the box if you have enough kredits',
	'once an offer is avaliable (the light will turn red again), you can go over to the SELLER and press CLICK TO SELL to sell your BOX
you will get KREDITS and gain 1 EXPERIENCE POINT for each BOX you sell',
	'now you can continue to create and sell BOXES manually; this is a bit of work
after a while you will get enough KREDITS to buy a MACHINE, we will tell you when that time comes!',
	'you can now buy your first MACHINE!
click on ADD MACHINE in the bottom right or press TAB to open the SHOP',
	'you may now choose a MACHINE that you have enough KREDITS to buy
the descriptions are shown next to the image, click on the price to buy a MACHINE',
	'the shadow follows your MOUSE, and if you LEFT CLICK, you can place down the selected MACHINE; the arrow on the shadow is the direction of the MACHINE which can be rotated by pressing R
if you have more KREDITS, you can place more MACHINES and press ESCAPE to end the process; you can press RIGHT CLICK to remove machines too',
	'if you want to delete MACHINES, press the DELETE MACHINES BUTTON (or the delete key) and LEFT CLICK on MACHINES to delete them; press ESCAPE to stop
press T to close the tutorial, and have fun playing!'
]

func _process(delta: float) -> void: #runs every microsecond because this is a really fast computer
	#set the value to the amount of level pts (and lerp it) and the max to the max level pts you can get
	progress.value = lerpf(progress.value, Main.levelbar, delta * 4)
	progress.max_value=Main.maxLB
	kreditlerp = lerpf(kreditlerp, Main.kredits, delta * 4)
	kredits.text = str(round(kreditlerp), ' kredits') #set the credits to the amount of credits and lerp it
	level.text = str("level ", Main.level) #set the level UI to the level you are at
	xpreq.text = str(Main.levelbar, '/', Main.maxLB, ' boxes') #show the player how many boxes they have and how much they need (the max) to level up
	
	if Main.tutorial_progress == 4 and Main.kredits >= Main.prices['seller']: #move onto the next tutorial text if there's enough kredits to buy a machine
		Main.tutorial_progress += 1
	
	if Input.is_action_just_pressed('end_tutorial') and Main.tutorial_progress == 8: #close out the tutorial when the player is done with it
		tutorial.hide()
	
	tutorial.text = tutorial_texts[Main.tutorial_progress] #sets the tutorial texts based on the progress
	
	if Main.maxboxes - Main.main.boxamount <= 20: #if a warning needs to be shown
		if TMBblinker.is_stopped(): #the binking stuff code
			TMBblinker.start()
			toomanyboxes.visible = not toomanyboxes.visible
		
		if Main.maxboxes - Main.main.boxamount < 0: #over the limit warning
			toomanyboxes.modulate = Color.RED
			toomanyboxes.text = str(abs(Main.maxboxes - Main.main.boxamount), ' BOXES OVER THE LIMIT, PLEASE REMOVE BOXES TO REACTIVATE THE CREATORS!')
		elif Main.maxboxes - Main.main.boxamount == 0: #at the limit warning
			toomanyboxes.modulate = Color.RED
			toomanyboxes.text = 'YOU HAVE REACHED THE MAX LIMIT, PLEASE REMOVE BOXES TO REACTIVATE THE CREATORS!'
		else: #near the limit warning
			toomanyboxes.modulate = Color.ORANGE_RED
			toomanyboxes.text = str(Main.maxboxes - Main.main.boxamount, ' BOXES TO THE LIMIT, BE CAREFUL!')
	else: #hide if there is no need for a warning
		toomanyboxes.hide()
