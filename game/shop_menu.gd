extends Control

signal shop_closed()

@onready var weapon_components: Array[Node] = %WeaponComponentsContainer.get_children()
@onready var core_component: Control = %CoreComponent
@onready var shield_component: Control = %ShieldComponent

@onready var weapons_stock_container: Node = %WeaponsStockContainer
@onready var cores_stock_container: Node = %CoresStockContainer
@onready var shields_stock_container: Node = %ShieldsStockContainer

@onready var discard_popup: Control = %DiscardPopup
@onready var discard_yes_button: Button = %DiscardYesButton

@export var player: PlayerMech
@export var component_scene: PackedScene


func _ready() -> void:
	for i in weapon_components.size():
		var component: Control = weapon_components[i]
		component.unequip_requested.connect(_on_weapon_unequip_requested.bind(i))
	discard_popup.hide()


func setup() -> void:
	show()
	var inventory: PlayerInventory = player.inventory
	
	var all_weapons_occupied: bool = true
	
	for i in inventory.active_weapons.size():
		var component: Control = weapon_components[i]
		component.setup(inventory.active_weapons[i])
		component.is_equipped = true
		component.can_change = inventory.active_weapons[i] != null
		all_weapons_occupied = all_weapons_occupied && inventory.active_weapons[i] != null
	
	core_component.setup(inventory.active_core)
	core_component.can_change = false
	core_component.discardable = false
	
	shield_component.setup(inventory.active_shield)
	shield_component.can_change = false
	shield_component.discardable = false
	
	_clean_container(weapons_stock_container)
	for weapon in inventory.weapons_inventory:
		if weapon in inventory.active_weapons:
			continue
		var component: Control = component_scene.instantiate()
		weapons_stock_container.add_child(component)
		weapons_stock_container.move_child(component, 0)
		component.setup(weapon)
		component.is_equipped = false
		component.can_change = !all_weapons_occupied
		component.discardable = inventory.weapons_inventory.size() > 1
		component.equip_requested.connect(_on_weapon_equip_requested.bind(weapon))
		component.discard_requested.connect(_on_element_discard_requested.bind(
			weapon, inventory.weapons_inventory
		))
	
	_clean_container(cores_stock_container)
	for core in inventory.cores_inventory:
		if core == inventory.active_core:
			continue
		var component: Control = component_scene.instantiate()
		cores_stock_container.add_child(component)
		cores_stock_container.move_child(component, 0)
		component.setup(core)
		component.is_equipped = false
		component.can_change = true
		component.discardable = true
		component.equip_requested.connect(_on_core_equip_requested.bind(core))
		component.discard_requested.connect(_on_element_discard_requested.bind(
			core, inventory.cores_inventory
		))
	
	_clean_container(shields_stock_container)
	for shield in inventory.shields_inventory:
		if shield == inventory.active_shield:
			continue
		var component: Control = component_scene.instantiate()
		shields_stock_container.add_child(component)
		shields_stock_container.move_child(component, 0)
		component.setup(shield)
		component.is_equipped = false
		component.can_change = true
		component.discardable = true
		component.equip_requested.connect(_on_shield_equip_requested.bind(shield))
		component.discard_requested.connect(_on_element_discard_requested.bind(
			shield, inventory.shields_inventory
		))


func _on_weapon_unequip_requested(weapon_index: int) -> void:
	player.inventory.set_weapon_to_slot(null, weapon_index)
	setup()


func _on_weapon_equip_requested(weapon_data: MechWeaponData) -> void:
	var free_slot: int = -1
	for i in player.inventory.active_weapons.size():
		var weapon_active: MechWeaponData = player.inventory.active_weapons[i]
		if !weapon_active:
			free_slot = i
			break
	
	if free_slot != -1:
		player.inventory.set_weapon_to_slot(weapon_data, free_slot)
	
	setup()


func _on_core_equip_requested(core_data: MechComponentData) -> void:
	player.inventory.set_core_as_active(core_data)
	setup()


func _on_shield_equip_requested(shield_data: MechComponentData) -> void:
	player.inventory.set_shield_as_active(shield_data)
	setup()


func _on_element_discard_requested(element, container: Array) -> void:
	discard_popup.show()
	if discard_yes_button.pressed.is_connected(_discard_element):
		discard_yes_button.pressed.disconnect(_discard_element)
	discard_yes_button.pressed.connect(_discard_element.bind(element, container))


func _discard_element(element, container: Array) -> void:
	container.erase(element)
	if discard_yes_button.pressed.is_connected(_discard_element):
		discard_yes_button.pressed.disconnect(_discard_element)
	setup()
	discard_popup.hide()


func _clean_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_close_shop_button_pressed() -> void:
	shop_closed.emit()
