# Overview

# Plugin flow

1. Blockflow 


# Folder structure

Plugin's folder structure. We aim to group related files by folder, but when we can't find a place for it at its creation moment, we put the file one level higher until

## `blockflow` folder 
This is the main project folder. It includes general documentation files (like [`README`](README.md)).

## `/commands`
Contains all command templates bundled with the plugin. 

Not all of these commands are registered (exposed) in CommandRecord.

## `/core`
Plugin core files. The plugin aims to work isolated as possible, but most (if not all) scripts tends to rely on these files.

You can find the plugin script here.

## `/debugger`
Plugin debugger.

Debugger UI and debugger scripts that are added under Godot's `debugger` tab to debug in-game processors.

## `/documentation`

Documentation files. This folder includes this file.

Even if each script has their own documentation to describe what is their purpose, some extra information can be found in their `README` files and in this folder.

## `/editor`
Editor folder.

All Blockflow UI related files lives here, from the main screen to each individual block script.

### `/command_block`
### `/inspector`
### `/playground`

### `/shortcuts`

## `/icons`
Plugin icons. All icons are here, in SVG Format, with a specific color and size selection.

## `/script_templates`
Script templates that are going to be copied to `res://` when plugin loads for the first time.

These templates should appear when you create a new script of `Command` type.