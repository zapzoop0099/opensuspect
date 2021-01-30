extends MarginContainerBase

var mouse_entered:bool
var index:int

#TODO: Set a randomizer 

signal input_received(ui_data, index)

func _ready():
	pass


func _on_itemslot_mouse_entered():
	if get_child_count() == 1:
		return
	else:
		get_child(1).animator.play("hover")
		get_child(1).can_pickup_with_mouse = true
		mouse_entered = true


func _on_itemslot_mouse_exited():
	if get_child_count() == 1:
		return
	else:
		get_child(1).animator.play("idle")
		get_child(1).can_pickup_with_mouse = false
		mouse_entered = false


func _on_itemslot_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and mouse_entered == true:
		if get_child(1) != null:
			emit_signal("input_received", ui_data, index)
