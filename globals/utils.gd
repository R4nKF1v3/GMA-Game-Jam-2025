extends Node


static func get_closest(
	global_position: Vector3,
	elements_list: Array,
	ignored: Array = []
) -> Node3D:
	var selected: Node3D
	var closest: float = -1
	for element in elements_list:
		if is_instance_valid(element) && element is Node3D:
			var distance: float = global_position.distance_squared_to(element.global_position)
			if (distance < closest || closest == -1) && !ignored.has(element):
				selected = element
				closest = distance
	
	return selected


static func remap(
	v: float,
	old_min: float,
	old_max: float,
	new_min: float,
	new_max: float
) -> float:
	return ((v - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min
