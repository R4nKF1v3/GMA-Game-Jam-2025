class_name MechWeapon
extends Node3D

signal fired()
signal heat_generated(amount)

@onready var target_point_raycast: RayCast3D = $TargetPointRaycast
@onready var shoot_raycast: RayCast3D = $ShootRaycast
@onready var fire_particles: GPUParticles3D = %FireParticles
@onready var fire_sound: AudioStreamPlayer3D = %FireSound

@export var rate_of_fire: float
@export var spread: float
@export var range: float = 1000.0

var initial_delay: float = 0.0

var data: MechWeaponData

var target_collision: int : 
	set(value):
		target_collision = value
		if shoot_raycast:
			shoot_raycast.collision_mask = target_collision
var shooting: bool = false :
	set(value):
		shooting = value
		if shooting:
			if shoot_timer && shoot_timer.time_left > 0.0:
				if !shoot_timer.timeout.is_connected(shoot):
					shoot_timer.timeout.connect(shoot)
			elif initial_delay > 0.0:
				shoot_timer = get_tree().create_timer(initial_delay)
				shoot_timer.timeout.connect(shoot)
			else:
				shoot()
		elif shoot_timer && shoot_timer.timeout.is_connected(shoot):
			shoot_timer.timeout.disconnect(shoot)

var shoot_timer: SceneTreeTimer


func add_ignored_object(object: CollisionObject3D) -> void:
	target_point_raycast.add_exception(object)
	shoot_raycast.add_exception(object)


func shoot() -> void:
	if !shooting:
		return
	fire_particles.restart()
	fire_particles.emitting = true
	fire_sound.play()
	shoot_raycast.target_position = Vector3.FORWARD.rotated(
		Vector3(
			1.0, 0.0, 0.0
		).normalized(),
		randf_range(0.0, spread)
	).rotated(
		Vector3(
			0.0, 1.0, 0.0
		).normalized(),
		randf_range(0.0, spread)
	).rotated(
		Vector3(
			0.0, 0.0, 1.0
		).normalized(),
		randf_range(0.0, spread)
	) * -range
	shoot_raycast.force_raycast_update()
	if shoot_raycast.is_colliding():
		var collider: Object = shoot_raycast.get_collider()
		if collider && collider is Mech:
			collider.report_hit(
				data.get_damage()
			)
	heat_generated.emit(data.get_heat_buildup())
	fired.emit()
	shoot_timer = get_tree().create_timer(rate_of_fire)
	shoot_timer.timeout.connect(shoot)


func set_data(p_data: MechWeaponData) -> void:
	data = p_data


func get_target_point() -> Vector3:
	return target_point_raycast.get_collision_point() if target_point_raycast.is_colliding() else target_point_raycast.to_global(target_point_raycast.target_position)
