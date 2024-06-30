# Blockflow overview
This files summarizes the plugin behavior and plugin structure. For detailed information about the content of each folder, take a look at their respective `README` files.
<!-- 
Note:
README files are created on demand. 
This means that they are created when someone requested further information about a specific part. This question is solved and the information gathered from the question is added to the file.

This is made this way to ensure that time invested in documentation applies to a real user "use case" and not the creator of the plugin thoughts. (Yeah, I'm looking at you, future Dex).
-->

- [Plugin flow](#plugin-flow)
	- [Editor runtime](#editor-runtime)
	- [In-game runtime](#in-game-runtime)
	- [Processor runtime](#processor-runtime)
- [Folder structure](#folder-structure)
	- [`blockflow` folder](#blockflow-folder)
	- [`/commands`](#commands)
	- [`/core`](#core)
	- [`/debugger`](#debugger)
	- [`/documentation`](#documentation)
	- [`/editor`](#editor)
		- [`/command_block`](#command_block)
		- [`/inspector`](#inspector)
		- [`/playground`](#playground)
		- [`/shortcuts`](#shortcuts)
	- [`/icons`](#icons)
	- [`/script_templates`](#script_templates)

## Plugin flow

### Editor runtime

1. `Blockflow` plugin is activated by the user:
	- Godot engine creates `core/plugin_script.gd` (`Blockflow` plugin) instance.
	- On creation, plugin creates and holds `BlockEditor` and `CommandRecord` instances, with some inspector tools.
2. `BlockEditor` is added as main screen node, displayed along with `2D` and `3D` scene views.
	- `BlockEditor` adds a `TitleLabel`, `CollectionDisplayer`, `Toolbar` and a `CommandList`.
		- Toolbar menu items are added during creation time.
		- The editor adds itself to a fake "singleton" name in `Engine` as `Blockflow_main_editor`.
		- Even if `CollectionDisplayer` display `CommandBlock`s, it doesn't manipulate the collection, is the editor itself which does this task.
3. First time that editor loads or when it doesn't edit any collection, a "welcome" message is displayed and `CommandList` buttons are disabled.
4. When a command is selected (clicked) from `CommandList` it emits a signal that is listened by `BlockEditor`. That signal contains information about the command selected, which is duplicated and added in the current edited collection.
5. When a command is drag from any place (from a `CommandBlock`, `CommandList` or `FileSystem`) drag information is passed to engine:
	- If is drop in `CollectionDisplayer`, the data is handled by`BlockEditor` and the command is added/moved to the dropped position.
6. Right-click on any `CommandBlock` will display a menu with some manipulation options that can be applied to the block.

### In-game runtime
Editor is not meant to be used _in-game_, but many parts of it can be used/replicated in game.

### Processor runtime
> Processor core functions are not designed to work in editor. Data manipulation in this node, however, is. Many aspects of the processor in editor time are modified by many `EditorInspector` plugins, added by `Blockflow` plugin.

`CommandProcessor` takes a single `CommandCollection` at time.

When you play a scene with `CommandProcessor` nodes (and `start_on_ready` is enabled or you call `start`), processor will call the execution steps from the command position passed (being 0, the first command, used) and will repeat this process until there are no more commands left.

Command flow is determined by the processor, the next/previous steps can be determined by the current executed command.

## Folder structure

Plugin's folder structure. We aim to group related files by folder, but when we can't find a place for it at its creation moment, we put the file one level higher until

### `blockflow` folder 
This is the main project folder. It includes general documentation files (like [`README`](README.md)).

### `/commands`
Contains all command templates bundled with the plugin. 

Not all of these commands are registered (exposed) in CommandRecord.

### `/core`
Plugin core files. The plugin aims to work isolated as possible, but most (if not all) scripts tends to rely on these files.

You can find the plugin script here.

### `/debugger`
Plugin debugger.

Debugger UI and debugger scripts that are added under Godot's `debugger` tab to debug in-game processors.

### `/documentation`

Documentation files. This folder includes this file.

Even if each script has their own documentation to describe what is their purpose, some extra information can be found in their `README` files and in this folder.

### `/editor`
Editor folder.

All Blockflow UI related files lives here, from the main screen to each individual block script.

#### `/command_block`
Scripts that defines the structure of the basic command block that is seen in editor through `CommandDisplayer`.

#### `/inspector`
Inspector scripts that defines custom modifications to different classes that are used in this plugin at `EditorInspector`.

#### `/playground`
Test (playground) scenes to try Blockflow features and debug them in game. 

Some features can't be used in game runtime since they're locked to the editor runtime, so we test those in these playground scenes.

#### `/shortcuts`
Shortcuts used in the editor, created as `Shortcut` resources to be able to modify and reuse.

### `/icons`
Plugin icons. All icons are here, in SVG Format, with a specific color and size selection.

### `/script_templates`
Script templates that are going to be copied to `res://` when plugin loads for the first time.

These templates should appear when you create a new script of `Command` type.