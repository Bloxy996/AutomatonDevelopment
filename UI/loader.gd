extends Control
class_name Loader
##yeah this is a pretty useless script idk why it exists

@onready var anim: AnimationPlayer = $anim

func _ready() -> void:
	show()

func showscreen() -> void:
	await get_tree().create_timer(0.01).timeout
	anim.play('show')
	await anim.animation_finished
	hide()

func hidescreen() -> void:
	show()
	anim.play('hide')
