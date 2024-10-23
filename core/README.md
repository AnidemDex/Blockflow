# Core 
Very important files that didn't fit in any other folder. 

These files are usually tied to the plugin than the editor itself, like the main plugin script or util functions used in many editor places.

# Plugin
## plugin_script.gd
Plugin script core. Without this, editor can't add the plugin.

## constants.gd
Constant values used in plugin scripts to get non-variable plugin data.

# `CommandRecord`
Object in charge of managing the different types of commands that can be registered in the plugin, displayed in `CommandList` and built through templates.

**Unimplemented**: Record is also used in the Timeline/Collection serializer.

It should be able to:
- [] Register commands from `Script`s that are saved as files.
- [] Register commands from `Resource`s that are saved as files.
- [] Unregister commands using their path, script or command resource.
- [] Send a signal when its internal register changes.
- [] Register plugin _built-in_ commands defined in `constants.gd`.

## command_record.gd
`CommandRecord` script.

## command_record.tres
`CommandRecord` fake singleton. Used by default as reference for all `CommandRecord` instances.
