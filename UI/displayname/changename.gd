extends Control

@onready var currentname: RichTextLabel = $RichTextLabel3
@onready var loader: Loader = $loader

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RichTextLabel5.visible = false # Replace with function body.
	loader.showscreen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	currentname.text = "[center]" + Main.displayname #sets text to player display name

func _on_cancel_pressed() -> void:
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://leaderboard/leaderboardscreen.tscn") #go to the start menu

func _on_confirm_pressed() -> void:
	if $LineEdit.text != "":
		Main.displayname = $LineEdit.text
		Main.savegame(true)
		$RichTextLabel5.visible = true
