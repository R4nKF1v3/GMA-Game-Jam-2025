class_name MechWeaponResource
extends Resource

@export var scene: PackedScene


func get_scene() -> MechWeapon:
	return scene.instantiate()
