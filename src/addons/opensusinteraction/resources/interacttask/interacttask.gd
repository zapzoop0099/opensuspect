tool
extends Resource

class_name InteractTask

export(String) var task_text

export(int) var random_numbers = 0

var item_inputs_on: bool
var item_inputs: PoolStringArray

var item_outputs_on: bool
var item_outputs: PoolStringArray

var map_outputs_on: bool
var map_outputs: Array

var task_outputs_on: bool
var task_outputs: Array

var is_task_global: bool = false

#needed to instance new unique resources in editor
var base_ui_resource: Resource = ResourceLoader.load("res://addons/opensusinteraction/resources/interactui/interactui.tres")
var base_map_resource:Resource = ResourceLoader.load("res://addons/opensusinteraction/resources/interactmap/interactmap.tres")

#changed in the editor via overriding get(), set(), and get_property_list()
var ui_res: Resource = base_ui_resource.duplicate()

#node this task is attached to
var attached_to: Node

#assigned by a programmer when added to the scene
#needs to be unique
export var task_id: int = TaskManager.INVALID_TASK_ID
var task_data: Dictionary = {}
var task_data_player: Dictionary = {}
var task_registered: bool = false

# relationships between shown property names and the actual script property name
# properties in this dict are NOT automatically added to editor, they must also be in custom_properties_to_show
# if you want the editor property name to be the same as the script variable name, you do not need to add it to custom_properties
# shown property name: script property name
var custom_properties: Dictionary = {
	"ui_resource": "ui_res", 
	
	"inputs/toggle_items": "item_inputs_on", 
	"inputs/input_items": "item_inputs", 
	
	"outputs/toggle_items": "item_outputs_on", 
	"outputs/output_items": "item_outputs", 
	
	"outputs/toggle_map_interactions": "map_outputs_on", 
	"outputs/output_map_interactions": "map_outputs", 
	
	"outputs/toggle_tasks": "task_outputs_on", 
	"outputs/output_tasks": "task_outputs"
}

# properties to add to the editor with script
# if you want the editor property name to be the same as the script variable name, you do not need to add it to custom_properties
var custom_properties_to_show: PoolStringArray = ["ui_resource", "outputs/toggle_map_interactions", "outputs/output_map_interactions", "is_task_global"]

func complete_task(	player_id: int = TaskManager.GLOBAL_TASK_PLAYER_ID, 
					data: Dictionary = {}) -> bool:
	# I'm adding a virtual function in case we add some base checks here, so you could
	# 	add custom behavior while retaining the checks
	# this is similar behavior to assign_player(), registered(), gen_task_data(), etc.
	# if you want fully custom behavior, override this function instead
	var virt_return  = _complete_task(player_id, data)
	if virt_return is bool:
		return virt_return
	var temp_interact_data = task_data_player[player_id]
	for key in data.keys():
		temp_interact_data[key] = data[key]
	if map_outputs_on:
		for resource in map_outputs:
			resource.interact(attached_to, temp_interact_data)
	return true

# not defined to return a bool so this script can know if this function was overridden
# 	or not
# while overriding, return any bool to immediately stop the execution of complete_task()
# returning a bool will also give said bool to whatever called complete_task()
func _complete_task(player_id: int, data: Dictionary):
	pass

func assign_player(player_id: int = TaskManager.GLOBAL_TASK_PLAYER_ID):
	if task_data_player.has(player_id):
		return
	# if nothing is explicitly returned, _assign_player() will return null and will not trigger this
	# this check is so an extending script can override interact behavior (while retaining the
	#	above checks) by declaring _assign_player() and returning false. If you want fully custom 
	# 	behavior, override this function instead
	# used to add custom behavior when a player is assigned to this task
	if _assign_player(player_id) == false:
		return
	task_data_player[player_id] = task_data.duplicate(true)
	var task_text = task_data["task_text"]
	var data = []
	assert(random_numbers >= 0)
	randomize()
	for i in range(random_numbers):
		data.append(randi())
	#var data: Dictionary = TaskGenerators.call_generator(task_text)
	task_data_player[player_id]["task_data"] = data

func _assign_player(player_id: int = TaskManager.GLOBAL_TASK_PLAYER_ID):
	pass

func registered(new_task_id: int, new_task_data: Dictionary):
	_registered(new_task_id, new_task_data)
	for key in new_task_data.keys():
		task_data[key] = new_task_data[key]
	task_id = new_task_id
	task_registered = true

func _registered(new_task_id: int, new_task_data: Dictionary):
	pass

#func task_rset(property: String, value):
#	TaskManager.send_network_set(property, value, task_id)

#func receive_task_rset(property: String, value):
#	set(property, value)

#func task_rpc(function: String, args: Array):
#	TaskManager.send_network_call(function, args, task_id)

#func receive_task_rpc(function: String, args: Array):
#	call(function, args)

func get_task_data(player_id: int = Network.get_my_id()) -> Dictionary:
	if task_registered and is_task_global():
		player_id = TaskManager.GLOBAL_TASK_PLAYER_ID
	
	var temp_task_data = task_data
	if task_data_player.has(player_id):
		temp_task_data = task_data_player[player_id]
		
	temp_task_data["task_id"] = task_id
	if task_registered:
		return temp_task_data
	var generated_task_data = gen_task_data()
	for key in generated_task_data.keys():
		temp_task_data[key] = generated_task_data[key]
	return temp_task_data

# generate initial data to send to the task manager, should not be called after it is registered
func gen_task_data() -> Dictionary:
	if task_registered:
		return task_data
	var info: Dictionary = {}
	info["task_text"] = task_text
#	info["item_inputs"] = item_inputs
#	info["item_outputs"] = item_outputs
	info["task_outputs"] = task_outputs
	info["attached_node"] = attached_to
	info["resource"] = self
	info["is_task_global"] = is_task_global
	#info["ui_resource"] = ui_res
	var virt_info: Dictionary = _gen_task_data()
	for key in virt_info:
		info[key] = virt_info[key]
	for key in info.keys():
		task_data[key] = info[key]
	return info

# meant to be overridden in an extending script to allow adding custom data to task_info
func _gen_task_data() -> Dictionary:
	return {}

func get_task_id() -> int:
	return task_id
	
func get_task_state(player_id: int = TaskManager.GLOBAL_TASK_PLAYER_ID) -> int:
	if not task_data_player.has(player_id):
		#this player has not been assigned this task
		return TaskManager.task_state.HIDDEN
	return task_data_player[player_id]["state"]

func set_task_state(player_id: int, new_state: int) -> bool:
	task_data_player[player_id]["state"] = new_state
	return true

func is_task_global() -> bool:
	return task_data["is_task_global"]

func interact(_from: Node = null, _interact_data: Dictionary = {}):
	if attached_to == null and _from != null:
		attached_to = _from
	if attached_to == null:
		push_error("InteractTask resource trying to be used with no defined node")
	# if nothing is explicitly returned, _interact() will return null and will not trigger this
	# this check is so an extending script can override interact behavior (while retaining the
	#	above checks) by declaring _interact() and returning false. If you want fully custom 
	# 	behavior, override this function instead
	# this could be used to cancel the interaction or to implement custom behavior, 
	# 	like triggering a map interaction instead of opening a UI
	if _interact(_from, _interact_data) == false:
		return
	ui_res.interact(_from, get_task_data())

# meant to be overridden by an extending script to allow custom behavior when interacted with
func _interact(_from: Node = null, _interact_data: Dictionary = {}):
	pass

func init_resource(_from: Node):
	if attached_to == null and _from != null:
		attached_to = _from
	if attached_to == null:
		push_error("InteractTask resource trying to be initiated with no defined node")
	# if nothing is explicitly returned, _init_resource() will return null and will not trigger this
	# this check is so an inheriting script can override initiation behavior while retaining the
	#	above checks. If you want fully custom behavior, override this function instead
	# I can't think of any reason you wouldn't want to register with the task manager, 
	# 	but the ability to do so couldn't hurt
	# calling the virtual function here also allows the custom script to add custom behavior
	if _init_resource(_from) == false:
		return
	TaskManager.register_task(self)

# meant to be overridden by an extending script to allow custom behavior on resource init
func _init_resource(_from: Node):
	pass

# not adding a virtual function for this because the same thing is accomplished by
# overriding _gen_interact_data()
func get_interact_data(_from: Node = null) -> Dictionary:
	if attached_to == null and _from != null:
		attached_to = _from
	if attached_to == null:
		push_error("InteractTask resource trying to be used with no defined node")
	return gen_task_data()

func _init():
	#print("task init ", task_name)
	#ensures customizing this resource won't change other resources
	if Engine.editor_hint:
		resource_local_to_scene = true
	#else:
	#	TaskManager.connect("init_tasks", self, "init_task")

#EDITOR STUFF BELOW THIS POINT, DO NOT TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING
#---------------------------------------------------------------------------------------------------
#overrides set(), allows for export var groups and display properties that don't
#match actual var names
func _set(property, value):
	match property:
		"ui_resource":
			#if new resource is a ui interact resource
			if value is preload("res://addons/opensusinteraction/resources/interactui/interactui.gd"):
				ui_res = value
			else:
				#create new ui interact resource
				ui_res = base_ui_resource.duplicate()
			return true
		"outputs/output_map_interactions":
			map_outputs = value
			for i in map_outputs.size():
				if map_outputs[i] == null:
					map_outputs[i] = base_map_resource.duplicate()
			property_list_changed_notify()
			return true

	if property in custom_properties.keys():
		set(custom_properties[property], value)
	return true

#overrides get(), allows for export var groups and display properties that don't
#match actual var names
func _get(property):
	if property in custom_properties.keys():
		return get(custom_properties[property])

#overrides get_property_list(), tells editor to show more properties in inspector
func _get_property_list():
	var property_list: Array = []

	for property in custom_properties_to_show:
		if is_property_added(property, property_list):
			continue
		var entry: Dictionary = {}
		var type: int = typeof(get(property))
		if type == TYPE_OBJECT:
			var property_class: String = get(property).get_class()
			entry["hint"] = PROPERTY_HINT_RESOURCE_TYPE
			entry["hint_string"] = property_class
		entry["name"] = property
		entry["type"] = type
		property_list.append(entry)

	return property_list

func is_property_added(property: String, array: Array):
	for dict in array:
		if dict.name == property:
			return true
	return false
