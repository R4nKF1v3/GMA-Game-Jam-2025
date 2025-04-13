extends Node3D

@export var enter_point: Node3D
@export var exit_point: Node3D
@export var spawn_points_container: Node3D


func connect_to_point(point: Vector3) -> void:
	var offset: Vector3 = -enter_point.position
	global_position = point + offset


func get_connection_point() -> Vector3:
	return exit_point.global_position


func get_new_spawn_point() -> Vector3:
	return spawn_points_container.get_child(randi() % spawn_points_container.get_child_count()).global_position
