class_name MechComponentResource
extends Resource


func handle_active(mech: Mech, level: int) -> void:
	pass


func _get_scaled_stat(base_stat: float, level_mod: float, level: int) -> float:
	return base_stat + level_mod * level
