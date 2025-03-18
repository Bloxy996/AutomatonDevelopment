extends Control

@onready var registerfields: Control = $registerfields
@onready var errors: RichTextLabel = $errors

func _ready() -> void:
	errors.hide()
	SilentWolf.Auth.sw_registration_complete.connect(_on_registration_complete)
  
func _on_registration_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		print("Registration succeeded!")
	else:
		error(sw_result.error)

func _on_register_pressed() -> void:
	var rg: Dictionary
	for field: LineEdit in registerfields.get_children():
		if field.text == '':
			error(field.placeholder_text + ' not filled out'); return
		rg[field.name] = field.text
	
	SilentWolf.Auth.register_player(rg.username, rg.email, rg.password, rg.confirm)

func error(message: String) -> void:
	errors.show()
	errors.text = '[center]' + message
