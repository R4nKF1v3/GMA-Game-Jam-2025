extends Node

var screens_map = {}
var current_screen = null


func _ready() -> void:
	randomize()
	#get_tree().set_auto_accept_quit(false)
	
	screens_map = {
		GameState.SCREENS.LOADING: $LoadingScreen,
		GameState.SCREENS.MENU: $MainMenuScreen,
		GameState.SCREENS.GAME: $GameScreen
	}
	
	for s in screens_map.values():
		s.change_screen.connect(_on_change_screen)
	_change_screen.call_deferred(GameState.SCREENS.LOADING, null)


func _on_change_screen(screen_id: int, value = null) -> void:
	_change_screen.call_deferred(screen_id, value)


func _change_screen(screen_id: int, value) -> void:
	if current_screen:
		current_screen.exit()
	current_screen = screens_map[screen_id]
	current_screen.enter(value)
