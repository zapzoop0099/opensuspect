tool
extends InteractTask

enum actions {OPEN, INSTANCE, UPDATE, CLOSE}

signal set_scene
signal erase_children

var slots_info:Dictionary = {}
var items_to_hold:Array = ["battery","wrench"]

func _init():
	add_networked_func("_server_set_scene", MultiplayerAPI.RPC_MODE_MASTER)
	add_networked_func("_client_set_scene", MultiplayerAPI.RPC_MODE_PUPPET)
	add_networked_func("_server_erase_children", MultiplayerAPI.RPC_MODE_MASTER)
	add_networked_func("_client_erase_children", MultiplayerAPI.RPC_MODE_PUPPET)
	
	GameManager.connect("state_changed",self,"_on_state_changed")
	
func set_action(value):
	match value:
		actions.OPEN:
			ui_res.action = actions.OPEN
		actions.INSTANCE:
			ui_res.action = actions.INSTANCE
		actions.UPDATE:
			ui_res.action = actions.UPDATE
		actions.CLOSE:
			ui_res.action = actions.CLOSE

func interact(_from: Node = null, _interact_data: Dictionary = {}, value = actions.OPEN):
	if attached_to == null and _from != null:
		attached_to = _from
	if attached_to == null:
		push_error("InteractTask resource trying to be used with no defined node")
	if not is_player_assigned(Network.get_my_id()):
		return
	if is_task_completed(Network.get_my_id()):
		return
	
	var dic = Helpers.merge_dicts(_interact_data, get_task_data())
	set_action(value)
	ui_res.interact(_from, dic)
	
func update(_from, data, value):
	print("get interaction")
	set_action(value)
	ui_res.interact(_from,task_data)
	print("next is sync")
	sync_task()


func _sync_task():
	print("set_server")
	task_rpc("_server_set_scene",["_no_var"])

func _server_set_scene(_arr):
	emit_signal("set_scene")
	print("client one next")
	task_rpc("_client_set_scene", ["_no_var"])
	
func _server_erase_children(_dic):
	emit_signal("erase_children")
	task_rpc("_client_erase_children", ["_no_var"])

func _client_set_scene(_dic):
	print("emitted")
	emit_signal("set_scene")

func _client_erase_children(_dic):
	emit_signal("erase_children")


func _on_state_changed(_old_state, new_state) -> void:#resets the task when state changes
	match new_state:
		GameManager.State.Lobby:
			task_rpc("_server_erase_children", ["no_var"])

func give_item(index):
	print("slot index")
	print(slots_info)
	print("index1")
	print(index)
	
	for slot_index in slots_info.keys():
		if not index == slot_index:
			return
		else:
			for slot in slot_index:
				var item_holding = slot_index[slot]
				print(item_holding)
	
