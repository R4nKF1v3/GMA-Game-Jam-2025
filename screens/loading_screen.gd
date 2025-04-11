extends Screen

@onready var container: Control = $CanvasLayer/Container
@onready var anim_player: AnimationPlayer = $EnterWaitExit
@onready var main_container: Control = $CanvasLayer/Container/FadeBG/StaticCont/MainContainer

var change_override


func _ready() -> void:
	container.hide()


func enter(value = null) -> void:
	change_override = value
	super.enter(value)


func _play_enter_animation() -> void:
	main_container.anchor_left = 0
	main_container.anchor_right = 0
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	main_container.position = viewport_size / 2 - main_container.size / 2
	if change_override:
		anim_player.play("RESET")
		await anim_player.animation_finished
		anim_player.play("enter")
	else:
		anim_player.play("wait")
	active = true


func _play_exit_animation() -> void:
	main_container.anchor_left = 1
	main_container.anchor_right = 1
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	main_container.position = viewport_size / 2 - main_container.size / 2
	anim_player.play("exit")


func _call_transition() -> void:
	await get_tree().create_timer(randf_range(0.0, 1.0)).timeout
	_change_screen(change_override if change_override else GameState.SCREENS.MENU)
