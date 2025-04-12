extends Node

@export var level_instances_container: Node
@export var starting_tile: Node3D


func setup() -> void:
	starting_tile.setup(true)
