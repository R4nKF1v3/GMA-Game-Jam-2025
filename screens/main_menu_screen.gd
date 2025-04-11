extends Screen

@onready var container: Control = $Container

@export var bgm: AudioStream


func _ready() -> void:
	container.visible = active


func _play_enter_animation() -> void:
	active = true
	container.show()
	AudioManager.change_main_bgm(bgm, -20)


func _play_exit_animation() -> void:
	await get_tree().create_timer(1.0).timeout
	container.hide()


func _on_StartButton_button_up() -> void:
	_change_screen(GameState.SCREENS.LOADING, GameState.SCREENS.GAME)


func _on_ReturnButton_button_up() -> void:
	get_tree().quit()
