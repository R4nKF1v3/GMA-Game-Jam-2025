extends Node

signal restart_called()

@onready var shop_menu: Control = %ShopMenu
@onready var main_menu: Control = %MainMenu
@onready var player_mech: PlayerMech = %PlayerMech
@onready var killed_window: Control = %KilledWindow

@export var level_manager: Node
@export var starting_point: Vector3 = Vector3(0.0, 0.0, -5.0)

@export var bgm_bus: String

var bgm_tween: Tween
var bgm_volume: float = 0.0 :
	set(value):
		bgm_volume = value
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bgm_bus),
			bgm_volume
		)


func _ready() -> void:
	main_menu.show()
	shop_menu.hide()
	level_manager.setup(starting_point)
	if bgm_tween:
		bgm_tween.kill()
	bgm_tween = create_tween()
	bgm_tween.tween_property(self, "bgm_volume", -10.0, 1.0)


func _on_player_mech_shop_open_requested() -> void:
	if !main_menu.visible:
		shop_menu.setup()
		level_manager.level_completed()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		if bgm_tween:
			bgm_tween.kill()
		bgm_tween = create_tween()
		bgm_tween.tween_property(self, "bgm_volume", -10.0, 1.0)


func _on_start_button_pressed() -> void:
	main_menu.hide()
	shop_menu.setup()


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_shop_menu_shop_closed() -> void:
	shop_menu.hide()
	player_mech.close_shop()
	level_manager.open_starting_tile()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if bgm_tween:
		bgm_tween.kill()
	bgm_tween = create_tween()
	bgm_tween.tween_property(self, "bgm_volume", 0.0, 1.0)


func _on_player_mech_killed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	killed_window.show()


func _on_restart_button_pressed() -> void:
	restart_called.emit()
