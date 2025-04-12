class_name MechWeapon
extends Node3D

@onready var target_point_raycast: RayCast3D = $TargetPointRaycast

var data: MechWeaponData

var shooting: bool = false


func set_data(p_data: MechWeaponData) -> void:
	data = p_data


func get_target_point() -> Vector3:
	return target_point_raycast.get_collision_point() if target_point_raycast.is_colliding() else target_point_raycast.to_global(target_point_raycast.target_position)
