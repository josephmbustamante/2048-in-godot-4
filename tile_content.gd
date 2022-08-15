extends Node3D
class_name TileContent


var tile = null
var amount := 2

@onready var label = $MeshInstance3D/Label3D


func _ready():
	label.text = str(amount)
	set_color(Color.DIM_GRAY)


func change_amount(new_amount: int, color: Color = Color.DIM_GRAY):
	amount = new_amount
	label.text = str(amount)
	set_color(color)


func set_color(color: Color):
	$MeshInstance3D.set("shader_uniforms/color", color)
