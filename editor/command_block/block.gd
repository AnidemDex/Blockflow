@tool
extends TreeItem

## Command visual representation for TimelineDisplayer

const FALLBACK_ICON = preload("res://icon.svg")
const FALLBACK_NAME = "UNKNOW_COMMAND"
const BOOKMARK_ICON = preload("res://addons/blockflow/icons/bookmark.svg")
const STOP_ICON = preload("res://addons/blockflow/icons/stop.svg")
const CONTINUE_ICON = preload("res://addons/blockflow/icons/play.svg")
const CommandClass = preload("res://addons/blockflow/commands/command.gd")

enum ColumnPosition {
	NAME_COLUMN,
	HINT_COLUMN,
	LAST_COLUMN
	}

enum ButtonHint {CONTINUE_AT_END}

var command:CommandClass = null: set = set_command
var command_name:String = FALLBACK_NAME
var command_icon:Texture = FALLBACK_ICON
var command_hint:String = ""
var command_hint_icon:Texture = null

func update() -> void:
	var hint_tooltip:String = "Bookmark:\n"+command.bookmark
	var bookmark_icon:Texture = BOOKMARK_ICON
	
	if command.bookmark.is_empty():
		hint_tooltip = ""
		bookmark_icon = null
	
	for i in get_tree().columns:
		set_icon_max_width(i, 32)
	
	set_text(ColumnPosition.NAME_COLUMN, command_name)
	set_icon(ColumnPosition.NAME_COLUMN, command_icon)
	
	set_text(ColumnPosition.HINT_COLUMN, command_hint)
	set_icon(ColumnPosition.HINT_COLUMN, command_hint_icon)
	
	var disabled_color = get_tree().get_theme_color("disabled_font_color", "Editor")
	set_text(ColumnPosition.LAST_COLUMN, str(command.index))
	set_custom_color(ColumnPosition.LAST_COLUMN, disabled_color)
	set_text_alignment(ColumnPosition.LAST_COLUMN, HORIZONTAL_ALIGNMENT_RIGHT)
	
	set_icon(ColumnPosition.LAST_COLUMN, bookmark_icon)
	set_icon_modulate(ColumnPosition.LAST_COLUMN, disabled_color)
	set_tooltip_text(ColumnPosition.LAST_COLUMN, hint_tooltip)
	
	if get_button_count(ColumnPosition.LAST_COLUMN) > 0:
		erase_button(ColumnPosition.LAST_COLUMN, ButtonHint.CONTINUE_AT_END)
	
	hint_tooltip = "CommandManager will stop when this command ends."
	var continue_icon = STOP_ICON
	if command.continue_at_end:
		hint_tooltip = "CommandManager will continue automatically to next command when this command ends."
		continue_icon = CONTINUE_ICON
	add_button(ColumnPosition.LAST_COLUMN, continue_icon, ButtonHint.CONTINUE_AT_END, false, hint_tooltip)


func set_command(value:CommandClass) -> void:
	if value == command:
		return
	
	if command and command.changed.is_connected(update):
		command.changed.disconnect(update)
	
	command = value
	set_metadata(0, command)
	
	if not command:
		_set_default_values()
		return
	
	command_name = command.get_command_name()
	command_icon = command.get_icon()
	if not command_icon:
		command_icon = FALLBACK_ICON
	command_hint = command.get_hint()
	command_hint_icon = command.get_hint_icon()
	
	command.changed.connect(update)


func _set_default_values() -> void:
	command_name = FALLBACK_NAME
	command_icon = FALLBACK_ICON
	command_hint = ""
	command_hint_icon = null

func _init():
	pass
