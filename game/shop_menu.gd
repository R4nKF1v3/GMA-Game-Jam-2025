extends Control

signal shop_closed()

@export var player: PlayerMech


func setup() -> void:
	show()


func _on_close_shop_button_pressed() -> void:
	shop_closed.emit()
