@tool
extends TreeItem

## Command visual representation for CollectionDisplayer

const FALLBACK_ICON = preload("res://addons/blockflow/icons/false.svg")
const FALLBACK_NAME = "UNKNOW_COMMAND"
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")
const CollectionClass = preload("res://addons/blockflow/collection.gd")
const Blockflow = preload("res://addons/blockflow/blockflow.gd")

enum ColumnPosition {
	NAME_COLUMN,
	HINT_COLUMN,
	BUTTON_COLUMN,
	INDEX_COLUMN,
	}

enum ButtonHint {CONTINUE_AT_END}

var command:CommandClass = null: set = set_command
var command_name:String = FALLBACK_NAME
var command_icon:Texture = FALLBACK_ICON
var command_hint:String = ""
var command_hint_icon:Texture = null

var command_background_color:Color = Color()
var background_colors:PackedColorArray = [
	Color(), # Blank
	Color("#ff4545"), # Red
	Color("#ffe345"), # Yellow
	Color("#80ff45"), # Green
	Color("#45ffa2"), # Aqua
	Color("#45d7ff"), # Blue
	Color("#8045ff"), # Purple
	Color("#ff4596"), # Pink
]

var command_text_color:Color = Color()


func update() -> void:
	command_name = command.command_name
	command_icon = command.command_icon
	if not command_icon:
		command_icon = FALLBACK_ICON
	command_hint = command.command_hint
	command_hint_icon = command.command_hint_icon

	command_background_color = background_colors[command.background_color]
	if command_background_color:
		command_background_color.a = 0.25


	command_text_color = command.command_text_color
	

	var hint_tooltip:String = "Bookmark:\n"+command.bookmark
	var bookmark_icon:Texture = BOOKMARK_ICON
	
	if command.bookmark.is_empty():
		hint_tooltip = ""
		bookmark_icon = null
	
	for i in get_tree().columns:
		set_icon_max_width(i, Blockflow.BLOCK_ICON_MIN_SIZE)

		if command_background_color == Color():
			clear_custom_bg_color(i)
		else:
			set_custom_bg_color(i, command_background_color, i != ColumnPosition.NAME_COLUMN)

		if command_text_color:
			set_custom_color(i, command_text_color)
		else:
			clear_custom_color(i)

	
	set_text(ColumnPosition.NAME_COLUMN, command_name)
	set_icon(ColumnPosition.NAME_COLUMN, command_icon)
	
	set_text(ColumnPosition.HINT_COLUMN, command_hint)
	set_icon(ColumnPosition.HINT_COLUMN, command_hint_icon)
	
	var disabled_color = get_tree().get_theme_color("disabled_font_color", "Editor")
	var position_hint:String = "%d" % [command.position]
	
	set_icon(ColumnPosition.BUTTON_COLUMN, bookmark_icon)
	set_icon_modulate(ColumnPosition.BUTTON_COLUMN, disabled_color)
	set_tooltip_text(ColumnPosition.BUTTON_COLUMN, hint_tooltip)
	
	if get_button_count(ColumnPosition.BUTTON_COLUMN) > 0:
		erase_button(ColumnPosition.BUTTON_COLUMN, ButtonHint.CONTINUE_AT_END)
	
	hint_tooltip = "CommandManager will stop when this command ends."
	var continue_icon = STOP_ICON
	if command.continue_at_end:
		hint_tooltip = "CommandManager will continue automatically to next command when this command ends."
		continue_icon = CONTINUE_ICON
	add_button(ColumnPosition.BUTTON_COLUMN, continue_icon, ButtonHint.CONTINUE_AT_END, false, hint_tooltip)

	set_text(ColumnPosition.INDEX_COLUMN, position_hint)
	set_custom_color(ColumnPosition.INDEX_COLUMN, disabled_color)
	set_text_alignment(ColumnPosition.INDEX_COLUMN, HORIZONTAL_ALIGNMENT_RIGHT)


func set_command(value:CommandClass) -> void:
	if value == command:
		return
	
	command = value
	set_metadata(0, command)
	
	if not command:
		_set_default_values()
		return
	
	command.changed.connect(update)
	update()



func _set_default_values() -> void:
	command_name = FALLBACK_NAME
	command_icon = FALLBACK_ICON
	command_hint = ""
	command_hint_icon = null
