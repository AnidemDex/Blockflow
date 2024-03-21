const Constants = preload("res://addons/blockflow/debugger/constants.gd")

static func can_send_message() -> bool:
	return not Engine.is_editor_hint() and OS.has_feature("editor")

static func register_processor(processor_data:Dictionary) -> void:
	if not can_send_message(): return
	
	EngineDebugger.send_message(Constants.DEBUGGER_REGISTER_PROCESSOR, [processor_data])


static func unregister_processor(processor_id:int) -> void:
	if not can_send_message(): return
	
	EngineDebugger.send_message(Constants.DEBUGGER_UNREGISTER_PROCESSOR, [processor_id])


static func processing_collection(processor_id:int, collection_data:Dictionary) -> void:
	if not can_send_message(): return
	
	EngineDebugger.send_message(Constants.DEBUGGER_PROCESSOR_PROCESSING_COLLECTION, [processor_id, collection_data])

static func processing_command(processor_id:int, command_data:Dictionary) -> void:
	if not can_send_message(): return
	
	EngineDebugger.send_message(Constants.DEBUGGER_PROCESSOR_PROCESSING_COMMAND, [processor_id, command_data])
