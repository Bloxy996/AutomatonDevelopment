extends Control
class_name Indikator

@onready var label: Label = $Label
@onready var anim: AnimationPlayer = $AnimationPlayer

var target: Vector3

func start(num: int, pos: Vector3, multiplier: bool = false) -> void: #the new ready function
	if multiplier:
		label.text = str('x ', num); modulate = Color('00bfff') #when a box is getting it's price multiplied
	else:
		num = round(num)
		if num > 0: label.text = str('+ ', num); modulate = Color.GREEN #increase of kredits
		elif num < 0: label.text = str('- ', abs(num)); modulate = Color.RED #decrease of kredits
		else: queue_free() #nothing, remove it!
	
	target = pos #sets the target so it can be used in process
	anim.play('fade') #starts the animation!!

func _process(_delta: float) -> void:
	global_position = get_viewport().get_camera_3d().unproject_position(target + (Vector3.ONE / 4)) - (label.size / 2) #puts it over the target

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free() #remove after animation is over
