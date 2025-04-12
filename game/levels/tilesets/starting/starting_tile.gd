extends Node3D

@export var enter_point: Node3D
@export var exit_point: Node3D
@export var animation_player: AnimationPlayer

@onready var entered_area: Area3D = $EnteredArea
@onready var player_pivot: Node3D = %PlayerPivot

var open_shop: bool = false


func setup(p_open_shop: bool) -> void:
	open_shop = p_open_shop


func connect_to_point(point: Vector3) -> void:
	pass


func _on_entered_area_body_entered(body: Node3D) -> void:
	if open_shop && body is PlayerMech:
		body.global_position = player_pivot.global_position
		body.open_shop()
		open_shop = false
