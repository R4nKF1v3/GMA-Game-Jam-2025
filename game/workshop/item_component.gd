extends Control

signal equip_requested()
signal unequip_requested()
signal discard_requested()

@onready var item_preview: TextureRect = %ItemPreview
@onready var stats_container: Node = %StatsContainer
@onready var equip_button: Button = %EquipButton
@onready var unequip_button: Button = %UnequipButton
@onready var discard_button: Button = %DiscardButton

var is_equipped: bool : 
	set(value):
		is_equipped = value
		equip_button.visible = !is_equipped && can_change
		unequip_button.visible = is_equipped && can_change
		discard_button.visible = !is_equipped && discardable

var can_change: bool :
	set(value):
		can_change = value
		equip_button.visible = !is_equipped && can_change
		unequip_button.visible = is_equipped && can_change

var discardable: bool :
	set(value):
		discardable = value
		discard_button.visible = !is_equipped && discardable


func setup(component_data) -> void:
	item_preview.texture = component_data.icon if component_data else null
	for child in stats_container.get_children():
		stats_container.remove_child(child)
		child.queue_free()
	if component_data:
		for stat in component_data.get_stats():
			var label: Label = Label.new()
			stats_container.add_child(label)
			label.text = stat


func _on_equip_button_pressed() -> void:
	equip_requested.emit()


func _on_unequip_button_pressed() -> void:
	unequip_requested.emit()


func _on_discard_button_pressed() -> void:
	discard_requested.emit()
