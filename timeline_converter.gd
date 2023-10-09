@tool
extends EditorResourceConversionPlugin

func _handles(resource: Resource) -> bool:
	return resource is Timeline

func _converts_to() -> String: return "CommandCollection"

func _convert(resource: Resource) -> Resource:
	return resource.get_collection_equivalent()
