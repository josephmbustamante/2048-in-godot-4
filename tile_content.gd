extends Node3D
class_name TileContent


var amount := 2

@onready var label = $Label3D


func _ready():
	label.text = str(amount)


func change_amount(new_amount: int):
	amount = new_amount
	label.text = str(amount)
