extends Control

@onready var slot: PackedScene = preload("res://leaderboard/slot.tscn")

@onready var loader: Loader = $loader
@onready var title: RichTextLabel = $RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Main.loadgame(true)
	await get_tree().create_timer(0.1).timeout
	Global._updateleaderboard()
	await get_tree().create_timer(0.1).timeout
	
	var usedplayers: Array[String] = []
	
	#gets scores from leaderboard
	var sw_result: Dictionary
	
	while not sw_result.has('scores'):
		sw_result = await SilentWolf.Scores.get_scores(1000).sw_get_scores_complete
		if not sw_result.has('scores'): continue
		
		var i: int = 1
		for score: Dictionary in sw_result.scores:
			if not usedplayers.has(score["player_name"]):
				usedplayers.append(score["player_name"])
				
				var inst: Panel = slot.instantiate()
				$ScrollContainer/VBoxContainer.add_child(inst)
				
				inst.get_node('place').text = str(i)
				inst.get_node('name').text = score["metadata"]["display"]
				inst.get_node('level').text = str(score["metadata"]["level"])
				inst.get_node('boxes').text = str(score["score"])
				
				if score["player_name"] == Main.playername:
					$slot.get_node('place').text = str(i)
					$slot.get_node('name').text = score["metadata"]["display"]
					$slot.get_node('level').text = str(score["metadata"]["level"])
					$slot.get_node('boxes').text = str(score["score"])
					
					inst.self_modulate.a = 1.0
				i += 1
			else:
				SilentWolf.Scores.delete_score(score["score_id"])
	
	loader.showscreen()
	
	var month: String = [ #get the month using real time!
		0,
		'january',
		'february',
		'march',
		'april',
		'may',
		'june',
		'july',
		'august',
		'september',
		'october',
		'november',
		'december'
	][Time.get_date_dict_from_system().month]
	#show the month in the leaderboard's name, because it resets each month
	title.text = '[center]' + month + "'s leaderboard"

func _on_button_9_pressed() -> void: #go back to the main menu
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://UI/mainmenu/start menu.tscn")

func _on_changename_pressed() -> void:
	loader.hidescreen(); await loader.anim.animation_finished
	get_tree().change_scene_to_file("res://UI/displayname/changename.tscn")
