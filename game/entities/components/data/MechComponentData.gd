class_name MechComponentData
extends RefCounted

var level: int = 0
var resource_data: MechComponentResource

var icon: Texture :
	set(value):
		return
	get():
		return resource_data.icon


func _init(data: MechComponentResource, p_level: int) -> void:
	resource_data = data
	level = p_level


func set_active(mech: Mech) -> void:
	resource_data.handle_active(mech, level)


func get_stats() -> PackedStringArray:
	return resource_data.get_stats(level)
