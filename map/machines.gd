extends StaticBody3D
class_name MachineContainer

@onready var map : Dictionary = { #the map for all the machines
	Vector2(14, 3) : $originalcreator, #original machines are already in here
	Vector2(3, 14) : $originalseller
}

func reset_map() -> void: #resets the map, used in main.gd when loading
	map = {
		Vector2(14, 3) : $originalcreator,
		Vector2(3, 14) : $originalseller
	}

signal map_updated

func _process(delta: float) -> void:
	for machine : Node3D in get_children(): ##pls dont get children every frame
		if machine.has_method('update'): machine.update(delta) #runs the update for the machine if it has one (just _process())

func get_machine(pos : Vector3) -> CollisionShape3D:
	var pos2d: Vector2 = Vector2(pos.x, pos.z)
	
	if map.has(pos2d): return map[pos2d]
	else: return null
