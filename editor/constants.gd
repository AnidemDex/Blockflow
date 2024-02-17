
# Editor specific starts in 9000, 9001 and 9002 are reserved
# https://github.com/godotengine/godot/blob/4.0.1-stable/scene/main/node.h#L298

enum {
	NOTIFICATION_EDITOR_DISABLED = 9003,
	NOTIFICATION_EDITOR_ENABLED = 9004,
}

const DEFAULT_LAYOUT_FILE = "res://.godot/editor/block_editor_cache.cfg"

const SHORTCUT_DUPLICATE = preload("res://addons/blockflow/editor/shortcuts/duplicate.tres")
const SHORTCUT_DELETE = preload("res://addons/blockflow/editor/shortcuts/delete.tres")
