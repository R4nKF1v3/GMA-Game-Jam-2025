extends Screen

@export var game_scene: PackedScene

var game: Node


func enter(value = null) -> void:
	if is_instance_valid(game):
		if game.get_parent() == self:
			remove_child(game)
		game.queue_free()
	
	game = game_scene.instantiate()
	#game.game_cleared.connect(_on_game_cleared)
	add_child(game)
	#game.setup()
	active = true
	super.enter(value)


func exit() -> void:
	await get_tree().create_timer(1.0).timeout
	if game.get_parent() == self:
		remove_child(game)
	game.queue_free()
	get_tree().paused = false


func previous() -> void:
	return


func _on_game_cleared() -> void:
	_change_screen(GameState.SCREENS.LOADING, GameState.SCREENS.MENU)
