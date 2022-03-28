extends TextureButton

signal pick_building(index)
var colors = [0,0,0,0]
export (PackedScene) var house
export (int) var angle
export (NodePath) var building

var _selected = false
var selected setget _set_selected, _get_selected
func _set_selected(value): 
	_selected = value
	disabled = value
	if value:
		focus_mode = Control.FOCUS_ALL
		grab_focus()
		focus_mode = Control.FOCUS_NONE
func _get_selected():
	return _selected

func _pressed():
	if selected:
		return
		
	emit_signal("pick_building", get_index())
	print("pressed")

func init():
	if building:
		get_node(building).get_parent().rotate_y(deg2rad(angle))

		Helper.set_mats(get_node(building), colors)

