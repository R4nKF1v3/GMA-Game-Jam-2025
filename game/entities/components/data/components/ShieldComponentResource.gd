class_name ShieldComponentResource
extends MechComponentResource

@export var base_shield_recharge_rate: float
@export var recharge_rate_per_level: float
@export var base_shield_recharge_cooldown: float
@export var shield_cooldown_per_level: float


func handle_active(mech: Mech, level: int) -> void:
	mech.shield_recharge_rate = _get_scaled_stat(
		base_shield_recharge_rate,
		recharge_rate_per_level,
		level
	)
	mech.shield_recharge_delay = _get_scaled_stat(
		base_shield_recharge_cooldown,
		shield_cooldown_per_level,
		level
	)
