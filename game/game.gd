extends Node

@onready var shop_menu: Control = %ShopMenu
@onready var main_menu: Control = %MainMenu
@onready var player_mech: PlayerMech = %PlayerMech

@export var level_manager: Node


func _ready() -> void:
	main_menu.show()
	shop_menu.hide()
	level_manager.setup()


func _on_player_mech_shop_open_requested() -> void:
	if !main_menu.visible:
		shop_menu.setup()


func _on_start_button_pressed() -> void:
	main_menu.hide()
	shop_menu.setup()


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_shop_menu_shop_closed() -> void:
	shop_menu.hide()
	player_mech.close_shop()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
