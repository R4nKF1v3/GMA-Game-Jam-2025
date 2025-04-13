class_name EnemyMech
extends Mech

@onready var damage_particles: GPUParticles3D = %DamageParticles
@onready var killed_particles: GPUParticles3D = %KilledParticles

var enemy_weapons: Array[MechWeaponData]
var enemy_core: MechComponentData
var enemy_shield: MechComponentData

var target_in_range: PlayerMech
var target_locked: PlayerMech

var detect_player_query: PhysicsRayQueryParameters3D


func _ready() -> void:
	pivot_target = pivot_target.rotated(Vector3.UP, randf_range(0.0, TAU))
	detect_player_query = PhysicsRayQueryParameters3D.new()
	detect_player_query.collision_mask = 1 + 2
	detect_player_query.collide_with_areas = false


func setup(
	spawn_point: Vector3,
	p_weapons: Array[MechWeaponData],
	p_core: MechComponentData,
	p_shield: MechComponentData
) -> void:
	global_position = spawn_point
	
	enemy_weapons = p_weapons
	enemy_core = p_core
	enemy_shield = p_shield
	
	for i in enemy_weapons.size():
		add_weapon(
			enemy_weapons[i].get_scene(),
			i
		)
	
	add_core(enemy_core)
	add_shield(enemy_shield)


var query_delay: float = 0.0
var last_query_result: bool = false
var last_seen: Vector3


func _physics_process(delta: float) -> void:
	#tilt_target = clamp(tilt_target - motion.y, -MAX_TILT, MAX_TILT)
	var move_direction: Vector3 = Vector3.ZERO
	var jumping: bool = false
	query_delay -= delta
	if dead:
		tilt_target = lerp(tilt_target, -PI * 0.25, delta)
	elif !target_locked:
		pivot_target = pivot_target.rotated(Vector3.UP, PI * 0.15 * delta)
		query_delay -= delta
		if _check_target_visible():
			target_locked = target_in_range
	else:
		var target_visible: bool = _check_target_visible()
		shooting = target_visible
		if !target_visible:
			var dir_to_target: Vector3 = global_position.direction_to(last_seen)
			jumping = abs(global_position.y - target_locked.global_position.y) > 3.0
			move_direction =  Vector3(
				dir_to_target.x,
				0,
				dir_to_target.z
			) * MAX_SPEED
		var dir: Vector3 = head.global_position.direction_to(target_locked.head.global_position)
		tilt_target = dir.y
		pivot_target = Transform3D(pivot_target, global_position).looking_at(
			Vector3(
				target_locked.global_position.x,
				global_position.y,
				target_locked.global_position.z
			)
		).basis.rotated(Vector3.UP, PI).orthonormalized()
	
	_process_movement(delta, move_direction, jumping)


func _on_detection_area_body_entered(body: Node3D) -> void:
	if !target_locked && body is PlayerMech:
		target_in_range = body


func _check_target_visible() -> bool:
	if target_in_range && query_delay <= 0.0:
		query_delay = 1.0
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		detect_player_query.from = head.global_position
		detect_player_query.to = target_in_range.head.global_position
		var result: Dictionary = space_state.intersect_ray(detect_player_query)
		last_query_result = result.get("collider") == target_in_range
		if last_query_result:
			last_seen = result.get("position", last_seen)
	return last_query_result


func report_hit(damage: float) -> void:
	super.report_hit(damage)
	damage_particles.restart()
	damage_particles.emitting = true


func _on_killed() -> void:
	killed_particles.emitting = true
