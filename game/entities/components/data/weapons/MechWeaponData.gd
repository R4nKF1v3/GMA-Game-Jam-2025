class_name MechWeaponData
extends RefCounted

var resource_data: MechWeaponResource
var level: int


func _init(data: MechWeaponResource, p_level: int) -> void:
	resource_data = data
	level = p_level


func get_scene() -> MechWeapon:
	var scene: MechWeapon = resource_data.get_scene()
	scene.data = self
	return scene
