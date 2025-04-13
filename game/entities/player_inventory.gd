class_name PlayerInventory
extends RefCounted

var player: PlayerMech
var weapons_inventory: Array[MechWeaponData] = []
var cores_inventory: Array[MechComponentData] = []
var shields_inventory: Array[MechComponentData] = []

var active_weapons: Array[MechWeaponData] = [null, null, null, null]
var active_core: MechComponentData
var active_shield: MechComponentData


func _init(p_player: PlayerMech) -> void:
	player = p_player


func add_weapon_to_inventory(weapon_data: MechWeaponData) -> void:
	if !weapons_inventory.has(weapon_data):
		weapons_inventory.push_back(weapon_data)


func add_core_to_inventory(core_data: MechComponentData) -> void:
	if !cores_inventory.has(core_data):
		cores_inventory.push_back(core_data)


func add_shield_to_inventory(shield_data: MechComponentData) -> void:
	if !shields_inventory.has(shield_data):
		shields_inventory.push_back(shield_data)


func set_weapon_to_slot(weapon_data: MechWeaponData, slot: int) -> void:
	if slot < 0 || slot >= active_weapons.size():
		return
	
	active_weapons[slot] = weapon_data
	if weapon_data:
		player.add_weapon(weapon_data.get_scene(), slot)
	else:
		player.remove_weapon(slot)


func set_core_as_active(core_data: MechComponentData) -> void:
	active_core = core_data
	player.add_core(active_core)


func set_shield_as_active(shield_data: MechComponentData) -> void:
	active_shield = shield_data
	player.add_shield(active_shield)


func refresh() -> void:
	active_core.set_active(player)
	active_shield.set_active(player)
	player.hp_updated.emit(player.current_hp, player.max_hp)
	player.shields_updated.emit(player.current_shields, player.max_shields)
