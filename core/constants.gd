## Plugin constants

const NAME = &"Blockflow"
const PLUGIN_NAME = &"BlockflowPlugin"

const COMMAND_FOLDER = &"res://addons/blockflow/commands"
const TEMPLATE_FOLDER = &"res://command_templates"

const DEFAULT_COMMAND_PATHS = [
	"res://addons/blockflow/commands/command_call.gd",
	"res://addons/blockflow/commands/command_animate.gd",
	"res://addons/blockflow/commands/command_comment.gd",
	"res://addons/blockflow/commands/command_print.gd",
	"res://addons/blockflow/commands/branch.gd",
	"res://addons/blockflow/commands/command_goto.gd",
	"res://addons/blockflow/commands/command_return.gd",
	"res://addons/blockflow/commands/command_set.gd",
	"res://addons/blockflow/commands/command_wait.gd",
	"res://addons/blockflow/commands/command_end.gd",
	]

const PROJECT_SETTING_PATH =\
&"blockflow/settings/"

const PROJECT_SETTING_DEFAULT_COMMANDS = PROJECT_SETTING_PATH+\
&"commands/default_commands"

const PROJECT_SETTING_CUSTOM_COMMANDS = PROJECT_SETTING_PATH+\
&"commands/custom_commands"

const PROJECT_SETTING_THEME = PROJECT_SETTING_PATH +\
&"editor/theme"
