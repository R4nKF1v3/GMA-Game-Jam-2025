class_name Mech
extends CharacterBody3D

@export var GRAVITY: float = 9.8
@export var ACCEL: float = 12.0
@export var MAX_SPEED: float = 6.0
@export var FLOAT_FORCE: float = 19.6
@export var MAX_FLOAT_FORCE: float = 20.0
@export var FLOAT_CAPACITY: float = 3.0
@export var FLOAT_CAP_RECHARGE_RATE: float = 1.0
@export var BASE_TURN_RATE: float = PI

@onready var anim: AnimationTree = $AnimationTree
@onready var head: Node3D = $Mech/Armature/Skeleton3D/Cabin_2/Cabin_2

@onready var weapon_slots: Array[Node3D] = [
	%ArmL, %ArmR, %ShoulderL, %ShoulderR
]

var weapons: Array[MechWeapon] = [null, null, null, null]
var core: MechComponentData
var shield: MechComponentData

var max_hp: float
var current_hp: float
var max_shields: float
var current_shields: float
var shield_recharge_rate: float
var shield_recharge_delay: float
var shield_cd_timer: SceneTreeTimer

var current_float_capacity: float = FLOAT_CAPACITY
var float_capacity_recharge: float = 0.0

var tilt_target: float = 0.0
var pivot_target: Basis = Basis.IDENTITY.rotated(Vector3.UP, PI)

var shooting: bool : set = _set_shooting


func add_weapon(weapon: MechWeapon, slot: int) -> void:
	if slot < 0 || slot >= weapon_slots.size():
		return
	
	if weapons[slot]:
		var existing_weapon: MechWeapon = weapons[slot]
		weapon_slots[slot].remove_child(existing_weapon)
		existing_weapon.queue_free()
	
	weapons[slot] = weapon
	weapon_slots[slot].add_child(weapon)


func add_core(p_core: MechComponentData) -> void:
	core = p_core
	core.set_active(self)


func add_shield(p_shield: MechComponentData) -> void:
	shield = p_shield
	shield.set_active(self)


func _process_movement(
	delta: float,
	move_dir: Vector3,
	jumping: bool
) -> void:
	# accelerate towards desired velocity
	velocity.x = move_toward(velocity.x, move_dir.x, ACCEL * delta)
	if jumping && current_float_capacity > 0.0:
		if velocity.y >= MAX_FLOAT_FORCE:
			velocity.y += GRAVITY * delta
		else:
			velocity.y += FLOAT_FORCE * delta
		current_float_capacity -= delta
		float_capacity_recharge = FLOAT_CAP_RECHARGE_RATE
	else:
		float_capacity_recharge = max(float_capacity_recharge - delta, 0.0)
		if is_equal_approx(float_capacity_recharge, 0.0):
			current_float_capacity = min(current_float_capacity + delta, FLOAT_CAPACITY)
	velocity.y -= GRAVITY * delta
	velocity.z = move_toward(velocity.z, move_dir.z, ACCEL * delta)
	
	# transform the new velocity relative to the direction our feet our facing
	# use that to drive the animation
	var local_velocity: Vector3 = velocity * global_basis
	anim.set(
		"parameters/blend_position",
		Vector2(-local_velocity.x, local_velocity.z) * max(float(is_on_floor()), 0.1)
	)
	
	# input velocity to the AnimationTree and get our "true" velocity,
	# which must be transformed back to global space
	if is_on_floor():
		var movement: Vector3 = global_basis * (anim.get_root_motion_position()) / delta
		velocity.x = movement.x
		velocity.z = movement.z
	set_up_direction(Vector3.UP)
	move_and_slide()
	velocity = velocity
	
	# rotate the base towards where the head is facing
	# the faster we're moving, the faster the base rotates
	# if we're standing still, only the head rotates
	global_basis = global_basis.orthonormalized().slerp(
		pivot_target.orthonormalized(),
		delta * velocity.length() * BASE_TURN_RATE / MAX_SPEED
	)
	
	# now adjust the head rotation to face the desired direction
	# given the new rotation of the base
	head.global_basis = pivot_target
	head.rotation.x = -tilt_target


func _set_shooting(p_shooting: bool) -> void:
	shooting = p_shooting
	for i in weapons.size():
		if weapons[i]:
			weapons[i].shooting = shooting
