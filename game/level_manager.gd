extends Node

@export var player: PlayerMech
@export var level_instances_container: Node
@export var enemies_container: Node
@export var starting_tile_scene: PackedScene
@export var tiles_scenes: Array[PackedScene]

@export var base_tiles: int = 3
@export var new_tiles_per_level: float = 0.5

@export var base_enemy_spawn: int = 2
@export var extra_enemies_per_level: float = 0.5

@export var enemy_scene: PackedScene
@export var weapons_available: Array[MechWeaponResource]
@export var cores_available: Array[CoreComponentResource]
@export var shields_available: Array[ShieldComponentResource]

@export var music_tracks: Array[AudioStream]

var level: int = 0

var tiles_generated: Array[Node3D] = []
var enemies_spawned: Array[EnemyMech] = []


func setup(starting_point: Vector3) -> void:
	var starting_tile: Node3D = _setup_starting_tile(starting_point)
	setup_level(starting_tile.get_connection_point())
	tiles_generated.push_front(starting_tile)


func setup_level(starting_point: Vector3) -> void:
	for tile in tiles_generated:
		level_instances_container.remove_child.call_deferred(tile)
		tile.queue_free.call_deferred()
	tiles_generated.clear()
	
	for enemy in enemies_spawned:
		enemies_container.remove_child.call_deferred(enemy)
		enemy.queue_free.call_deferred()
	enemies_spawned.clear()
	
	var previous_connection: Vector3 = starting_point
	
	for i in int(base_tiles + level * new_tiles_per_level):
		var new_tile: Node3D = _setup_new_tile(tiles_scenes.pick_random(), previous_connection)
		tiles_generated.push_back(new_tile)
		previous_connection = new_tile.get_connection_point()
		for _i in int(base_enemy_spawn + level * extra_enemies_per_level):
			_setup_new_enemy(
				new_tile.get_new_spawn_point()
			)
	
	var end_tile: Node3D = _setup_starting_tile(previous_connection)
	end_tile.open_entrance()
	tiles_generated.push_back(end_tile)
	
	AudioManager.change_main_bgm(music_tracks.pick_random(), -25)


func level_completed() -> void:
	level += 1
	var end_tile: Node3D = tiles_generated.pop_back()
	setup_level(
		end_tile.get_connection_point()
	)
	tiles_generated.push_front(end_tile)
	end_tile.close_entrance()


func open_starting_tile() -> void:
	var starting_tile: Node3D = tiles_generated.front()
	starting_tile.open_exit()


func close_end_tile() -> void:
	var end_tile: Node3D = tiles_generated.back()
	end_tile.close_entrance()


func _setup_starting_tile(connection_point: Vector3) -> Node3D:
	var starting_tile: Node3D = _setup_new_tile(starting_tile_scene, connection_point)
	starting_tile.setup(true)
	return starting_tile


func _setup_new_tile(tile_scene: PackedScene, connection_point: Vector3) -> Node3D:
	var tile: Node3D = tile_scene.instantiate()
	level_instances_container.add_child(tile)
	tile.connect_to_point(connection_point)
	return tile


var check_occupied_query: PhysicsPointQueryParameters3D = PhysicsPointQueryParameters3D.new()

func _setup_new_enemy(spawn_position: Vector3) -> void:
	var new_enemy: EnemyMech = enemy_scene.instantiate()
	enemies_container.add_child(new_enemy)
	enemies_spawned.push_back(new_enemy)
	
	weapons_available.shuffle()
	var weapons: Array[MechWeaponData]
	for i in randi() % 3 + 2:
		weapons.push_back(
			MechWeaponData.new(weapons_available.pick_random(), level)
		)
	
	check_occupied_query.collision_mask = 4
	check_occupied_query.position = spawn_position
	var result: Array[Dictionary] = player.get_world_3d().direct_space_state.intersect_point(check_occupied_query)
	if !result.is_empty():
		spawn_position += Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * 0.5
	
	new_enemy.setup(
		spawn_position,
		weapons,
		MechComponentData.new(cores_available.pick_random(), level),
		MechComponentData.new(shields_available.pick_random(), level)
	)
	
	new_enemy.killed.connect(_on_enemy_killed.bind(new_enemy))


func _on_enemy_killed(enemy: EnemyMech) -> void:
	var level_up: int = randi() % 2 + 1
	match randi() % 4:
		0, 1:
			var random_weapon: MechWeaponData = enemy.enemy_weapons.pick_random()
			random_weapon.level += level_up
			random_weapon.damage_mult = 1.0
			player.inventory.add_weapon_to_inventory(random_weapon)
		2:
			enemy.enemy_core.level += level_up
			player.inventory.add_core_to_inventory(enemy.enemy_core)
		3:
			enemy.enemy_shield.level += level_up
			player.inventory.add_shield_to_inventory(enemy.enemy_shield)
