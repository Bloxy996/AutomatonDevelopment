extends Control

@onready var loader: Loader = $"../loader"

var opacity: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#sets opacity to 0 or invisible
	modulate = Color8(255,255,255,0)
	#stops process from running
	set_process(false)
	loader.showscreen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#increases opacity until it is fully visible
	if opacity < 255:
		opacity += 14
		modulate = Color8(255,255,255,opacity)

func called() -> void:
	#waits for a second and turns on process, which increases opacity
	await get_tree().create_timer(1).timeout
	set_process(true)

func _on_playbutton_pressed() -> void:
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://map/main.tscn")

func _on_reset_pressed() -> void:
	Main.resetgame() #resets all the variables
	loader.hidescreen(); await loader.anim.animation_finished
	await  get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene() #reloads the game

func _on_contacts_pressed() -> void:
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://UI/contacts/Contacts.tscn")

func _on_leaderboard_pressed() -> void:
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://leaderboard/leaderboardscreen.tscn")

func _on_changelog_pressed() -> void:
	$"../Changelog".show()
