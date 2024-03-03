@tool
extends PanelContainer

const FALLBACK_ICON = preload("res://addons/blockflow/icons/false.svg")
const Settings = preload("res://addons/blockflow/blockflow.gd")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const EditorConst = preload("res://addons/blockflow/editor/constants.gd")

class Category extends VBoxContainer:
	var EditorTheme:Theme = load(EditorConst.DEFAULT_THEME_PATH) as Theme
	
	var title:Button
	var container:VBoxContainer
	var command_button_pressed_callback:Callable
	
	var commands := []
	
	func add_command(command:CommandClass) -> void:
		if command in commands:
			return
		
		commands.append(command)
		
		var command_button := Button.new()
		command_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		command_button.set_drag_forwarding(
			command_button_get_drag_data.bind(command),
			Callable(),
			Callable()
		)
		
		if command_button_pressed_callback.is_valid():
			command_button.pressed.connect(
				command_button_pressed_callback.bind(command)
				)
		
		command_button.text = command.command_name
		
		var command_icon:Texture = command.command_icon
		if not command_icon:
			command_icon = FALLBACK_ICON
		command_button.expand_icon = true
		command_button.icon = command_icon
		
		container.add_child(command_button)
		
	func command_button_get_drag_data(at_position:Vector2, command:CommandClass):
		if not command: return
		
		var drag_data = {&"type":&"resource", &"resource":null, &"from":self}
		drag_data.resource = command.get_duplicated()
		
		var drag_preview = Button.new()
		drag_preview.text = (drag_data.resource as Command).command_name
		set_drag_preview(drag_preview)
		
		return drag_data
	
	func _toggle(button_pressed:bool) -> void:
		container.visible = !container.visible
	
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
				var font := get_theme_font("bold","EditorFonts")
				var font_size := get_theme_font_size("bold_size", "EditorFonts")
				var sb := get_theme_stylebox("bg", "EditorInspectorCategory")
				title.add_theme_font_override("font", font)
				title.add_theme_constant_override("font_size", font_size)
				title.add_theme_stylebox_override("normal", sb)
				title.add_theme_stylebox_override("hover", sb)
				title.add_theme_icon_override("checked", get_theme_icon("GuiTreeArrowRight", "EditorIcons"))
				title.add_theme_icon_override("unchecked", get_theme_icon("GuiTreeArrowDown", "EditorIcons"))
				title.add_theme_icon_override("checked_disabled", get_theme_icon("GuiTreeArrowRight", "EditorIcons"))
				title.add_theme_icon_override("unchecked_disabled", get_theme_icon("GuiTreeArrowDown", "EditorIcons"))
				
				var category_icon:Texture
				var theme_name:String = title.text
				# Verifying this per theme change may impact performance?
				var is_category_theme_defined:bool = EditorTheme.get_icon_list("Category").has(theme_name)
				
				category_icon = get_theme_icon(theme_name, "Category")
				
				if not is_category_theme_defined:
					category_icon = get_theme_icon("Object", "EditorIcons")
				
				title.icon = category_icon
			
			9003:
				propagate_call("set", ["disabled", true])
			9004:
				propagate_call("set", ["disabled", false])
	
	func _init() -> void:
		title = CheckButton.new()
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "Category"
		title.alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.expand_icon = true
		title.toggled.connect(_toggle)
		add_child(title)
		
		container = VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(container)

var command_button_pressed_callback:Callable
var scroll_container:ScrollContainer
var category_container:VBoxContainer
var misc_category:Category

var categories:Dictionary = {}


func build_command_list() -> void:
	if is_instance_valid(category_container):
		category_container.queue_free()
		category_container = null
	categories.clear()
	create_category_container()
	
	for command in Settings.get_default_command_scripts():
		add_command(command)
	
	for command in Settings.get_custom_commands():
		add_command(command)
	
	sort_categories()
		


func create_category_container() -> void:
	if is_instance_valid(category_container): return
	category_container = VBoxContainer.new()
	category_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(category_container)


func add_category(category_name:StringName) -> void:
	if category_name in categories: return
	
	var category = Category.new()
	category.name = category_name
	category.command_button_pressed_callback = command_button_pressed_callback
	category.title.text = category_name
	category.title.icon = get_theme_icon("Object", "EditorIcons")
	categories[category_name] = category
	category_container.add_child(category)


func add_command(command_obj:Object) -> void:
	if command_obj is Script:
		command_obj = command_obj.new()
	
	if command_obj is CommandClass:
		var category:StringName = command_obj.command_category
		add_category(category)
		var category_node:Node = categories.get(category, null)
		
		category_node.add_command(command_obj)
		return


func sort_categories() -> void:
	var c:Array = categories.keys()
	c.erase(&"Commands")
	c.sort()
	for i in c.size():
		var category:Node = categories[c[i]]
		category_container.move_child(category, i)
	
	if &"Commands" in categories:
		category_container.move_child(categories[&"Commands"], 0)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			# TODO: Add a background stylebox
			return

func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(128, 64)
	
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)
