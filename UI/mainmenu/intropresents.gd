extends RichTextLabel

var opacity: int = 1
var timer: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Main.loadgame(true)
	
	#sets opacity as 0 or not visible if it's the first time
	if Main.first_time:
		modulate = Color8(255,255,255,opacity)
	else:
		modulate = Color8(255,255,255,0)
		$"../maincontainer".called()
		set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Main.first_time:
		#show everything if the start thingy already played
		$"../maincontainer".called()
		modulate = Color8(255,255,255,0)
		#ends script
		set_process(false)
	
	#pauses for 1 sec
	await get_tree().create_timer(1).timeout
	#increases opacity until opacity is at or above 255, or fully visible
	if opacity < 255 and opacity > 0:
		opacity += 14
		modulate = Color8(255,255,255,opacity)
	else:
		#if opacity is greater than 255
		if opacity >= 0:
			#wait for 1 sec (shows present)
			await get_tree().create_timer(2).timeout
			#reduces opacity until it gets below 0 (not visible)
			while not opacity < 0:
				await get_tree().create_timer(delta / 2).timeout
				opacity -= 14
				modulate = Color8(255,255,255,opacity)
		#waits 0.5 seconds and shows buttons
		if opacity < 0:
			await get_tree().create_timer(0.5).timeout
			if Main.playername == "": $"../Entername"._namecalled()
			$"../maincontainer".called()
			Main.first_time = false
			#ends script
			set_process(false)
