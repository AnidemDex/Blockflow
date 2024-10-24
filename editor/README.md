# Editor
Blockflow editor.

The editor main purpose is to provide a tool to create and modify collections and commands to be used later in game through processors.

It should be able to:
- Load stuff:
    - [ ] Load a `Timeline`(unimplemented).
    - [ ] Load a `Collection`, including, but not limited to `Command` and `CommandCollection`. 
    - [ ] It can use the `File` menu, using the `Open...` option, to load a `Collection` or `Timeline` (unimplemented).
    - [ ] The attempted file to inspect in editor will be automatically handled by the plugin, then passed to the editor.
- Edit stuff:
    - [ ] Create, move and remove `Event`s in `Timeline`s (unimplemented).
    - [ ] Create, move and remove `Commands` in any `Collection` type. (unimplemented) For now you can only do that for `Command`s in `CommandCollection`s.
    - [ ] Edit, copy and paste a `Command` using the context-menu and its related shortcuts, which is open by default with a right-click in any `CommandBlock`.
    - [ ] Create `Timeline`s (unimplemented).
    - [ ] Create `Command`s (unimplemented).
    - [ ] Create `CommandCollection`s. 
    - [ ] It can use the `File` menu, using the `New...` option
- [ ] Display a list of `Event`s for its usage (unimplemented).
- [ ] Display a list of `Command` for its usage. It uses `CommandList` with `CommandRecord` data in order to achieve it.

## views
### editor_view.gd
Editor view base class. 

This class implements the necessary tools to show and manipulate a single `Collection` object.

### in_editor_view.gd
Editor view made for **in editor** usage only.

## in_runtime_editor_view.gd
Editor view made for runtime usage. Its usage in editor is not recommended.

## shortcuts
Shortcut related resources.

## playground
Is supposed to contain test scenarios to debug the editor.

## inspector
`EditorInspector` related classes.

Most of these modify and expand the inspector view of each object handled by Blockflow.

### inspector_tools.gd
A collection of tools and nodes.

## displayer
Nodes which goal is to show the internal structure of blockflow objects, like the internal tree structure of a `Collection`.

### fancy_displayer.gd
`DisplayerFancy` type. It creates a fake and custom tree structure, using custom scenes.

### simple_displayer.gd
`DisplayerSimple` type. It creates the tree structure using custom `TreeItems` and `Tree` node. 

**Untested since the implementation of fancy displayer!!!**

## command_block
Objects that are the visual representation of a `Command`, used by `Displayer` types.

**Classes defined on its root are not tested since the implementation of fancy displayer!!!**

### fancy_block
Fancy visual representation of a command, used by `DisplayerFancy`.

#### block.gd
Node representation of a `Command`, composed by multiple `BlockCell` to define its sections.

#### block_cell.gd
Custom container used in `block.gd` to define a section. It can contain any arbitrary ammount of nodes to display any arbitrary ammount of data. 

We recommend to use `Control` node types to display data, and `Container` types to maintain a consistent layout.