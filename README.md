<!-- Gosh, somebody help me here, I have no words for now -->
<!-- Update: Still have no words -->

<!-- Hi future devs!

While testing stuff in this very early stage, make sure to use `playground` scene.

That scene will be moved eventually (like any other file in this repository)
so make sure to know always where `playground` is to test stuff.

I'll make sure to point where it'll be in future release, after defining the
plugin structure. -->

# <img src="icons/timeline.svg" width="48" height="48"> Godot Blockflow

A visual block style scripting for Godot 4.

---

Blockflow is a visual scripting plugin for Godot, made to create sequential instructions
that are executed one by one, easy to implement and highly customizable, allowing you to execute
code fragments in order according to the conditions you give it.

It helps in scenarios where you require a controlled execution of steps in
your games, such as a dialog system or the creation of cutscenes, without the need to recreate
an entire sequence by code.

Supports **any Godot 4** version.

## Getting started
Blockflow is a Godot plugin, it can be installed normally as [official Godot documentation](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html) guides:

- Download the plugin from the latest release.
- Extract the folder under your project `addons` folder (if the folder doesn't exist, create one).
- Go to Project -> Project Settings -> Plugins and mark `Blockflow` checkbox.

If everything works, you'll see `Block Editor` button at the top of Godot editor, next to 2D/3D/AssetLib buttons.
![]()

### Using git
You can install this repository as a submodule from your project root folder:
```shell
git submodule add https://github.com/AnidemDex/Blockflow  addons/blockflow
```

### Updating

To update the plugin manually:

- Close Godot editor.
- Remove `blockflow` folder.
- Add the new `blockflow` folder.

