extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var trans: PHashTranslation = load("res://tmp/translation.de.translation")
	print((trans as Translation).locale)
	print(trans.get_message("TIP_FILTERED"))

