# [UnnamedPlugin]

> CommandTimeline and GodotBlockFlow are potential names

<!-- Gosh, somebody help me here, I have no words for now -->
<!-- Update: Still have no words -->
[UnnamedPlugin] is a visual [DESCRIPTION]

Hi future devs!

While testing stuff in this very early stage, make sure to use `playground` scene.

That scene will be moved eventually (like any other file in this repository)
so make sure to know always where `playground` is to test stuff.

I'll make sure to point where it'll be in future release, after defining the
plugin structure.

## For now, this thing can...

### With code:

- Create timeline (`Timeline.new()`).
- Create a command (`Command.new()`).
- Add a command to the timeline `<Timeline>.add_command(<Command>)`.
- Create custom commands (`extends Command`).
- Define the name and the icon of the command (`_get_command_name()` and
`_get_command_icon()`).

### With editor:

- See a timeline (See [timeline_displayer.gd`](timeline_displayer.gd)).
- Display a bunch of buttons that are tied to a command to add them into the
current timeline when you press them (See [`command_list.gd`](command_list.gd)).
- Make appear a context menu when you right press an item in the timeline.
  - Modify the timeline structure with this context menu.
- Drag and drop items to modify the structure.

## This should be doing:

### With code:

- [ ] Executing the command behaviour.
- [ ] Managing the execution of the command behaviour.

### With editor:

- [x] Modifying the timeline structure with the context menu.
