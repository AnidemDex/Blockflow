@tool
extends EditorResourceConversionPlugin

const TimelineClass = preload("res://addons/blockflow/timeline.gd")

func _handles(resource: Resource) -> bool:
	return resource is TimelineClass

func _converts_to() -> String: return "CommandCollection"

func _convert(resource: Resource) -> Resource:
	return resource.get_collection_equivalent()
