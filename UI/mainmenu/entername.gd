extends Control

var opacity: int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#increases opacity until it is fully visible
	if opacity < 255:
		opacity += 14
		modulate = Color8(255,255,255,opacity)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#sets opacity to 0 or invisible
	modulate = Color8(255,255,255,0)
	#stops process from running
	set_process(false)
	hide()
	$RichTextLabel4.visible = false

func _namecalled() -> void:
	#waits for a second and turns on process, which increases opacity
	await get_tree().create_timer(1).timeout
	show()
	set_process(true)

func _on_button_pressed() -> void:
	var playernametemp: String = $LineEdit.text
	if await Global._checkiftaken(playernametemp) and playernametemp != "":
		Main.playername = $LineEdit.text
		Main.displayname = $LineEdit2.text
		hide()
		Main.savegame(true)
		Global._updateleaderboard()
	else:
		$RichTextLabel4.visible = true
