extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#required silent wolf configuration, dont change anything about this
	SilentWolf.configure({
		"api_key": "IU6NBBMzZJ38Vdl20XFi73RvnUk3vgM2COTfi2I1",
		"game_id": "automaton",
		"log_level": 0
	})

	SilentWolf.configure_scores({
		"open_scene_on_close": "res://scenes/MainPage.tscn"
	})

func _updateleaderboard() -> void:
	if not Main.version.contains('debug'):
		#saves score with username, boxes sold, leaderboard name, and metadata (display name and level)
		SilentWolf.Scores.save_score(Main.playername, Main.boxes, "main", {"display": Main.displayname, "level": Main.level})

#ran when creating new username, checks if someone in leaderboard already has username
func _checkiftaken(writtenname: String) -> bool:
	var sw_result: Dictionary
	while not sw_result.has('scores'):
		sw_result = await SilentWolf.Scores.get_scores_by_player(writtenname).sw_get_player_scores_complete
		if not sw_result.has('scores'): continue
	
	if sw_result.scores.is_empty():
		return true
	return false
