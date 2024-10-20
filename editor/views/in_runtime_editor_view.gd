extends "res://addons/blockflow/editor/views/editor_view.gd"

var undo_redo:UndoRedo

func add_command(command:CommandClass, at_position:int = -1, to_collection:CollectionClass = null) -> void:
	if not _current_collection: return
	if not command: return
	if not to_collection:
		to_collection = _current_collection
	
	var action_name:String = "Add command '%s'" % [command.command_name]
	last_selected_command = command
	
	disable()
	undo_redo.create_action(action_name)
		
	if at_position < 0:
		undo_redo.add_do_method(to_collection.add.bind(command))
	else:
		undo_redo.add_do_method(to_collection.insert.bind(command, at_position))
	
	undo_redo.add_undo_method(to_collection.erase.bind(command))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()


func move_command(command:CommandClass, to_position:int, from_collection:CollectionClass=null, to_collection:CollectionClass=null) -> void:
	if not _current_collection: return
	if not command: return
	
	if not from_collection:
		from_collection = command.get_command_owner()
	if not to_collection:
		to_collection = command.get_command_owner()
	
	if not from_collection:
		# It comes from nowhere, maybe we're adding instead of moving?
		add_command(command, to_position, to_collection)
		return

	if to_collection == command:
		push_error("Can't move into self!")
		return

	var weak_owner = to_collection.weak_owner
	if weak_owner:
		weak_owner = weak_owner.get_ref()
	while weak_owner:
		if weak_owner is WeakRef:
			weak_owner = weak_owner.get_ref()
		if weak_owner == command:
			push_error("Found self in parents, can't move into self!")
			return
		weak_owner = weak_owner.weak_owner

	var from_position:int = from_collection.get_command_position(command)
	var action_name:String = "Move command '%s'" % [command.command_name]
	
	disable()
	undo_redo.create_action(action_name)
	if from_collection == to_collection:
		undo_redo.add_do_method(from_collection.move.bind(command, to_position))
		undo_redo.add_undo_method(from_collection.move.bind(command, from_position))
	else:
		undo_redo.add_do_method(from_collection.erase.bind(command))
		undo_redo.add_undo_method(from_collection.insert.bind(command, from_position))
		undo_redo.add_do_method(to_collection.insert.bind(command, to_position))
		undo_redo.add_undo_method(to_collection.erase.bind(command))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()

func duplicate_command(command:CommandClass, to_index:int) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:CollectionClass
	if not command.weak_owner:
		push_error("!command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("!command_collection")
		return
	
	var action_name:String = "Duplicate command '%s'" % [command.command_name]
	var duplicated_command = command.get_duplicated()
	last_selected_command = duplicated_command
	var idx = to_index if to_index > -1 else command_collection.size()
	
	disable()
	undo_redo.create_action(action_name)
		
	undo_redo.add_do_method(command_collection.insert.bind(duplicated_command, to_index))
	undo_redo.add_undo_method(command_collection.erase.bind(duplicated_command))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()


func remove_command(command:CommandClass) -> void:
	if not _current_collection: return
	if not command: return
	var command_collection:CollectionClass
	if not command.weak_owner:
		push_error("not command.weak_owner")
		return
	command_collection = command.get_command_owner()
	if not command_collection:
		push_error("not command_collection")
		return
	
	var action_name:String = "Remove command '%s'" % [command.command_name]
	
	disable()
	undo_redo.create_action(action_name)
		
	undo_redo.add_do_method(command_collection.remove.bind(command.index))
	undo_redo.add_undo_method(command_collection.insert.bind(command, command.index))
	
	undo_redo.add_do_method(_current_collection.update)
	undo_redo.add_undo_method(_current_collection.update)
	
	undo_redo.commit_action()
	enable()
