@tool
extends PanelContainer

var session:EditorDebuggerSession

# { Object.get_instance_id(): [ProcessorDebugger, processor_data] }
var processors:Dictionary = {}

var collections:Dictionary = {}
var commands:Dictionary = {}
var command_collections:Dictionary = {}

var status_label:Label
var inactive_indicator:CenterContainer
var debugger_tabs:TabContainer
var processors_list:Tree
var main_collection_displayer:Tree
var current_collection_displayer:Tree
var current_command_displayer:Tree

func session_start() -> void:
	if not is_instance_valid(processors_list.get_root()):
		processors_list.create_item()
		processors_list.get_root().set_text(0, "Current Scene")
	
	show_active()


func session_break(can_debug:bool) -> void:
	return

func session_continue() -> void:
	return

func session_stop() -> void:
	processors_list.clear()
	commands.clear()
	collections.clear()
	
	show_inactive()


func register_processor(processor_data:Dictionary) -> void:
	processors[processor_data.id] = {}
	processors[processor_data.id][&"data"] = processor_data
	
	var root := processors_list.get_root()
	var processor_item := processors_list.create_item(root)
	processor_item.set_text(0, processor_data.name)
	processor_item.set_tooltip_text(0, str(processor_data.path))
	processor_item.set_icon(0, get_theme_icon("Node", "EditorIcons"))
	processor_item.set_metadata(0, processor_data.id)
	processors[processor_data.id][&"item"] = processor_item


func unregister_processor(processor_id:int) -> void:
	processors[processor_id][&"item"].free()
	processors.erase(processor_id)


func processor_processing_collection(processor_id:int, collection_data:Dictionary) -> void:
	collections[collection_data.id] = {}
	collections[collection_data.id][&"data"] = collection_data
	
	var processor_data:Dictionary = processors[processor_id][&"data"]
	
	if collection_data[&"class"] == &"CommandCollection":
		processor_data[&"main_collection"] = collection_data
		for command_data in collection_data[&"command_list"]:
			commands[command_data.id] = {}
			commands[command_data.id][&"data"] = command_data
	
	processor_data[&"current_collection"] = collection_data


func processor_processing_command(processor_id:int, command_data:Dictionary) -> void:
	commands[command_data.id] = {}
	commands[command_data.id][&"data"] = command_data
	
	var processor_data:Dictionary = processors[processor_id][&"data"]
	
	processor_data[&"current_command"] = command_data


func show_active() -> void:
	status_label.text = "Debug session started."
	status_label.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	
	inactive_indicator.visible = false
	debugger_tabs.visible = true

func show_inactive() -> void:
	status_label.text = "Debug session closed"
	status_label.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	
	inactive_indicator.visible = true
	debugger_tabs.visible = false


func _processor_list_item_selected() -> void:
	var selected_item := processors_list.get_selected()
	main_collection_displayer.clear()
	current_collection_displayer.clear()
	current_command_displayer.clear()
	
	var main_collection_root := main_collection_displayer.create_item()
	main_collection_root.set_text(0, "No processor is selected")
	main_collection_root.disable_folding = true
	
	var curr_collection_root := current_collection_displayer.create_item()
	curr_collection_root.set_text(0, "No processor is selected")
	curr_collection_root.disable_folding = true
	
	var curr_command_root := current_command_displayer.create_item()
	curr_command_root.set_text(0, "No processor is selected")
	curr_command_root.disable_folding = true
	
	if not selected_item:
		return
	
	var processor_id:int = selected_item.get_metadata(0)
	var processor_data:Dictionary = processors[processor_id]["data"]
	
	var main_collection_data:Dictionary = processor_data[&"main_collection"]
	var current_collection_data:Dictionary = processor_data[&"current_collection"]
	var current_command_data:Dictionary = processor_data[&"current_command"]
	
	if main_collection_data.is_empty():
		main_collection_root.set_text(0, "Processor does no have a main collection")
	else:
		main_collection_root.set_text(0, main_collection_data.name)
		var bookmarks_item := main_collection_displayer.create_item(main_collection_root)
		bookmarks_item.set_text(0, "Bookmarks")
		for bookmark in main_collection_data[&"bookmarks"]:
			var bookmark_item := main_collection_displayer.create_item(bookmarks_item)
			bookmark_item.set_text(0, bookmark)
		
		var command_list_item := main_collection_displayer.create_item(main_collection_root)
		command_list_item.set_text(0, "Command List")
		for command_data in main_collection_data[&"command_list"]:
			var command_item := main_collection_displayer.create_item(command_list_item)
			var command_name:String = "Unknow Command [ID: %s]"%command_data.id
			if command_data.id in commands:
				command_name = commands[command_data.id][&"data"][&"name"]
			
			command_item.set_text(0, command_name)
	
	if current_collection_data.is_empty():
		curr_collection_root.set_text(0, "Processor does no have a main collection")
	else:
		curr_collection_root.set_text(0, current_collection_data.name)
	
	if current_command_data.is_empty():
		curr_command_root.set_text(0, "Processor does no have a main collection")
	else:
		curr_command_root.set_text(0, current_command_data.name)
	
	
	

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			show_inactive()

func _init() -> void:
	name = "📜 Blockflow"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vb := VBoxContainer.new()
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vb)
	
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	
	status_label = Label.new()
	hb.add_child(status_label)
	
	var hs := HSplitContainer.new()
	hs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(hs)
	
	processors_list = Tree.new()
	processors_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	processors_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	processors_list.column_titles_visible = true
	processors_list.size_flags_stretch_ratio = 0.25
	processors_list.set_column_title(0, "Processors")
	processors_list.item_selected.connect(_processor_list_item_selected)
	hs.add_child(processors_list)
	
	inactive_indicator = CenterContainer.new()
	inactive_indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inactive_indicator.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inactive_indicator.visible = false
	hs.add_child(inactive_indicator)
	
	var label := Label.new()
	label.text = "There is no processor selected."
	inactive_indicator.add_child(label)
	
	debugger_tabs = TabContainer.new()
	debugger_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debugger_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hs.add_child(debugger_tabs)
	
	var hs_center := HSplitContainer.new()
	hs_center.name = "Collections"
	hs_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hs_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debugger_tabs.add_child(hs_center)
	
	main_collection_displayer = Tree.new()
	main_collection_displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_collection_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_collection_displayer.column_titles_visible = true
	main_collection_displayer.set_column_title(0, "Main Collection")
	hs_center.add_child(main_collection_displayer)
	
	# Oh frogs, why aren't there MultiSplitContainer?
	var hs_left := HSplitContainer.new()
	hs_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hs_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs_center.add_child(hs_left)
	
	current_collection_displayer = Tree.new()
	current_collection_displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_collection_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_collection_displayer.column_titles_visible = true
	current_collection_displayer.set_column_title(0, "Current Collection")
	hs_left.add_child(current_collection_displayer)
	
	current_command_displayer = Tree.new()
	current_command_displayer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_command_displayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_command_displayer.column_titles_visible = true
	current_command_displayer.set_column_title(0, "Current Command")
	hs_left.add_child(current_command_displayer)
	
	
	
	
	
