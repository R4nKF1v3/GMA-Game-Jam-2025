class_name MechWeaponResource
extends Resource

@export var icon: Texture
@export var scene: PackedScene

@export var base_damage: float
@export var damage_per_level: float
@export var heat_buildup: float


func get_damage(level: int) -> float:
	return _get_scaled_stat(base_damage, damage_per_level, level)


func get_heat_buildup(_level) -> float:
	return heat_buildup


func get_scene() -> MechWeapon:
	return scene.instantiate()


func get_stats(level: int) -> PackedStringArray:
	return PackedStringArray([
		tr("damage: ") + str(_get_scaled_stat(base_damage, damage_per_level, level)),
		tr("heat: ") + str(heat_buildup)
	])


func _get_scaled_stat(base_stat: float, level_mod: float, level: int) -> float:
	return base_stat + level_mod * level
