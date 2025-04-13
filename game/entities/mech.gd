class_name Mech
extends CharacterBody3D

signal hp_updated(amount, maximum)
signal hp_hit()
signal shields_updated(amount, maximum)
signal shields_hit()
signal killed()
signal heat_updated(amount, maximum)
signal jump_updated(amount, maximum)

@export var GRAVITY: float = 9.8
@export var ACCEL: float = 12.0
@export var MAX_SPEED: float = 6.0
@export var FLOAT_FORCE: float = 19.6
@export var MAX_FLOAT_FORCE: float = 20.0
@export var FLOAT_CAPACITY: float = 3.0
@export var FLOAT_CAP_RECHARGE_RATE: float = 1.0
@export var BASE_TURN_RATE: float = PI
@export var HEAT_CAPACITY: float = 100.0
@export var HEAT_REGEN_RATE: float = 20.0
@export var HEAT_COOLDOWN_DELAY: float = 1.0
@export var CAN_SHIELD_GATE: bool = false
@export var SHIELD_GATE_DURATION: float = 1.0

@export_flags_3d_physics var target_collision: int

@onready var anim: AnimationTree = $AnimationTree
@onready var head: Node3D = $Mech/Armature/Skeleton3D/Cabin_2/Cabin_2

@onready var pivot_down: Node3D = %PivotDown
@onready var pivot_up: Node3D = %PivotUp
@onready var pivot_checker: Node3D = %PivotChecker
@onready var step_audio: AudioStreamPlayer3D = %StepAudio
@onready var jump_audio: AudioStreamPlayer3D = %JumpAudio

@onready var weapon_slots: Array[Node3D] = [
	%ArmL, %ArmR, %ShoulderL, %ShoulderR
]

var weapons: Array[MechWeapon] = [null, null, null, null]
var active_weapons: Array[bool] = [true, true, true, true]
var core: MechComponentData
var shield: MechComponentData

var max_hp: float
var current_hp: float
var max_shields: float
var current_shields: float
var shield_recharge_rate: float
var shield_recharge_delay: float
var shield_cd_timer: float = 0.0

var shield_gating: float = 0.0

var heat_accumulated: float = 0.0
var heat_cooldown: float = 0.0
var overheated: bool = false :
	set(value):
		overheated = value
		for i in 4:
			var weapon: MechWeapon = weapons[i]
			if weapon != null:
				weapon.shooting = shooting && !overheated

var current_float_capacity: float = FLOAT_CAPACITY
var float_capacity_recharge: float = 0.0

var tilt_target: float = 0.0
var pivot_target: Basis = Basis.IDENTITY

var shooting: bool : set = _set_shooting

var pivot_falling: bool = false

var dead: bool = false


func add_weapon(weapon: MechWeapon, slot: int) -> void:
	if slot < 0 || slot >= weapon_slots.size():
		return
	
	remove_weapon(slot)
	weapons[slot] = weapon
	weapon_slots[slot].add_child(weapon)
	weapon.target_collision = target_collision
	weapon.heat_generated.connect(_on_weapon_heat_generated)
	weapon.initial_delay = (slot % 2) * (weapon.rate_of_fire / 2)
	weapon.add_ignored_object(self)


func remove_weapon(slot: int) -> void:
	if slot < 0 || slot >= weapon_slots.size():
		return
	
	if weapons[slot]:
		var existing_weapon: MechWeapon = weapons[slot]
		weapon_slots[slot].remove_child(existing_weapon)
		existing_weapon.queue_free()
	
	weapons[slot] = null


func add_core(p_core: MechComponentData) -> void:
	core = p_core
	core.set_active(self)


func add_shield(p_shield: MechComponentData) -> void:
	shield = p_shield
	shield.set_active(self)


func set_weapon_as_active(index: int, active: bool) -> void:
	active_weapons[index] = active
	if weapons[index]:
		weapons[index].shooting = active && shooting && !overheated


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
		jump_updated.emit(current_float_capacity, FLOAT_CAPACITY)
		if !jump_audio.playing:
			jump_audio.play()
	else:
		float_capacity_recharge = max(float_capacity_recharge - delta, 0.0)
		if is_equal_approx(float_capacity_recharge, 0.0):
			current_float_capacity = min(current_float_capacity + delta, FLOAT_CAPACITY)
			jump_updated.emit(current_float_capacity, FLOAT_CAPACITY)
		if jump_audio.playing:
			jump_audio.stop()
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
	#if is_on_floor():
		#var movement: Vector3 = global_basis * (anim.get_root_motion_position()) / delta
		#velocity.x = movement.x
		#velocity.z = movement.z
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
	
	if dead:
		return
	
	if heat_cooldown > 0.0:
		heat_cooldown -= delta
	else:
		heat_accumulated = max(heat_accumulated - HEAT_REGEN_RATE * delta, 0.0)
		heat_updated.emit(heat_accumulated, HEAT_CAPACITY)
		if overheated && is_equal_approx(heat_accumulated, 0.0):
			overheated = false
	
	shield_cd_timer = max(shield_cd_timer - delta, 0.0)
	if is_equal_approx(shield_cd_timer, 0.0):
		current_shields = min(current_shields + shield_recharge_rate * delta, max_shields)
		shields_updated.emit()
	
	shield_gating = max(shield_gating - delta, 0.0)
	
	if !pivot_falling && pivot_checker.global_position.y > pivot_up.global_position.y:
		pivot_falling = true
	elif pivot_falling && pivot_checker.global_position.y < pivot_down.global_position.y:
		pivot_falling = false
		step_audio.pitch_scale = randf() * 0.1 + 0.95
		step_audio.play()


func _set_shooting(p_shooting: bool) -> void:
	shooting = p_shooting
	for i in weapons.size():
		if weapons[i] && active_weapons[i]:
			weapons[i].shooting = shooting && !overheated


func _on_weapon_heat_generated(amount: float) -> void:
	heat_accumulated += amount
	heat_cooldown = HEAT_COOLDOWN_DELAY
	heat_updated.emit(heat_accumulated, HEAT_CAPACITY)
	if heat_accumulated >= HEAT_CAPACITY:
		overheated = true


func report_hit(damage: float) -> void:
	if dead || shield_gating > 0.0:
		return
	if current_shields > 0.0:
		current_shields = max(current_shields - damage, 0.0)
		shields_updated.emit(current_shields, max_shields)
		shields_hit.emit()
		shield_cd_timer = shield_recharge_delay
		if CAN_SHIELD_GATE:
			shield_gating = SHIELD_GATE_DURATION
	else:
		current_hp = max(current_hp - damage, 0.0)
		hp_updated.emit(current_hp, max_hp)
		hp_hit.emit()
		if is_equal_approx(current_hp, 0.0):
			dead = true
			killed.emit()
