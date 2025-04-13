class_name MechWeaponData
extends RefCounted

var resource_data: MechWeaponResource
var level: int

var damage_mult: float = 1.0


var icon: Texture : 
	set(value):
		return
	get():
		return resource_data.icon


func _init(data: MechWeaponResource, p_level: int) -> void:
	resource_data = data
	level = p_level


func get_scene() -> MechWeapon:
	var scene: MechWeapon = resource_data.get_scene()
	scene.data = self
	return scene


func get_stats() -> PackedStringArray:
	return resource_data.get_stats(level)


func get_damage() -> float:
	return resource_data.get_damage(level) * damage_mult


func get_heat_buildup() -> float:
	return resource_data.get_heat_buildup(level)
