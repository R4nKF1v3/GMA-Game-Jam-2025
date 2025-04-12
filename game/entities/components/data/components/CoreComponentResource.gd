class_name CoreComponentResource
extends MechComponentResource

@export var base_hp: float
@export var hp_per_level: float
@export var base_shield_capacity: float
@export var shield_capacity_per_level: float


func handle_active(mech: Mech, level: int) -> void:
	mech.max_hp = _get_scaled_stat(base_hp, hp_per_level, level)
	mech.max_shields = _get_scaled_stat(base_shield_capacity, shield_capacity_per_level, level)
	mech.current_hp = mech.max_hp
	mech.current_shields = mech.max_shields
