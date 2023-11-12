@tool
extends EditorDebuggerPlugin

const DConst = preload("res://addons/blockflow/debugger/debugger_constants.gd")
const DebuggerTab = preload("res://addons/blockflow/debugger/debugger_tab.gd")

var editor_plugin:EditorPlugin
var debugger_tab := DebuggerTab.new()

func _has_capture(capture: String) -> bool:
	return capture == DConst.DEBUGGER_PREFIX

func _capture(message: String, data: Array, session_id: int) -> bool:
	match message:
		DConst.DEBUGGER_REGISTER_PROCESSOR:
			debugger_tab.register_processor(data[0])
			return true
		DConst.DEBUGGER_UNREGISTER_PROCESSOR:
			debugger_tab.unregister_processor(data[0])
			return true
		DConst.DEBUGGER_PROCESSOR_PROCESSING_COLLECTION:
			debugger_tab.processor_processing_collection(data[0], data[1])
			return true
		DConst.DEBUGGER_PROCESSOR_PROCESSING_COMMAND:
			debugger_tab.processor_processing_command(data[0], data[1])
			return true
	
	return false

func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	# Listens to the session started and stopped signals.
	session.started.connect(debugger_tab.session_start)
	session.stopped.connect(debugger_tab.session_stop)
	session.breaked.connect(debugger_tab.session_break)
	session.continued.connect(debugger_tab.session_continue)
	
	debugger_tab.session = session
	session.add_session_tab(debugger_tab)
	
	return


