class_name PlayerMech
extends Mech

signal shop_open_requested()

@onready var camera: Camera3D = %Camera

@onready var hud: Control = %HUD
@onready var weapon_crosshairs: Array = %WeaponCrosshairs.get_children()
@onready var heat_progress_bar: ProgressBar = %HeatProgressBar
@onready var hp_progress_bar: TextureProgressBar = %HpProgressBar
@onready var shields_progress_bar: TextureProgressBar = %ShieldsProgressBar
@onready var shield_hit_feedback: TextureRect = %ShieldHitFeedback
@onready var hp_hit_feedback: TextureRect = %HpHitFeedback

@onready var shop_anim: AnimationPlayer = %ShopAnim
@onready var shop_camera: Camera3D = %ShopCamera

@export var MOUSE_SENSITIVITY: Vector2 = Vector2(0.002, 0.002)
@export var MAX_LOOK: Vector2 = Vector2(PI, PI / 4)
@export var MAX_TILT: float = PI / 4

@export var starting_weapons: Array[MechWeaponResource]
@export var starting_core: MechComponentResource
@export var starting_shield: MechComponentResource
@onready var inventory: PlayerInventory = PlayerInventory.new(self)

var shop_open: bool = false
var mouse_released: bool = false
var freelook: bool = false
var head_offset: Basis

var camera_offset: Vector2 = Vector2.ZERO


func _ready():
	for i in starting_weapons.size():
		var weapon_resource: MechWeaponResource = starting_weapons[i]
		var weapon_data: MechWeaponData = MechWeaponData.new(weapon_resource, 0)
		inventory.add_weapon_to_inventory(weapon_data)
		inventory.set_weapon_to_slot(weapon_data, i)
	
	var core_data: MechComponentData = MechComponentData.new(starting_core, 0)
	var shield_data: MechComponentData = MechComponentData.new(starting_shield, 0)
	inventory.add_core_to_inventory(core_data)
	inventory.add_shield_to_inventory(shield_data)
	inventory.set_core_as_active(core_data)
	inventory.set_shield_as_active(shield_data)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("toggle_camera") && !shop_open:
		if event.is_action_pressed("toggle_camera"):
			freelook = true
		elif event.is_action_released("toggle_camera"):
			freelook = false
			camera_offset = Vector2.ZERO
	elif event.is_action_pressed("release_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_released else Input.MOUSE_MODE_VISIBLE)
		mouse_released = !mouse_released
		shooting = shooting && !mouse_released
	elif event.is_action("fire") && !mouse_released && !shop_open:
		shooting = event.is_action_pressed("fire")
	elif event.is_action_pressed("toggle_weapon_1"):
		set_weapon_as_active(0, !active_weapons[0])
	elif event.is_action_pressed("toggle_weapon_2"):
		set_weapon_as_active(1, !active_weapons[1])
	elif event.is_action_pressed("toggle_weapon_3"):
		set_weapon_as_active(2, !active_weapons[2])
	elif event.is_action_pressed("toggle_weapon_4"):
		set_weapon_as_active(3, !active_weapons[3])
	elif event is InputEventMouseMotion && !shop_open:
		var motion: Vector2 = event.relative * MOUSE_SENSITIVITY
		if freelook:
			camera_offset = Vector2(
				clamp(camera_offset.x - motion.x, -PI * 0.4, PI * 0.4),
				clamp(camera_offset.y - motion.y, -PI * 0.4, PI * 0.4)
			)
		else:
			tilt_target = clamp(tilt_target - motion.y, -MAX_TILT, MAX_TILT)
			pivot_target = pivot_target.rotated(Vector3.UP, -motion.x)


func _physics_process(delta: float):
	# the player inputs a move direction relative to the direction they are facing
	# transform that to global space
	var move_dir: Vector3 = pivot_target * (Vector3(
		(Input.get_action_strength("move_left") - Input.get_action_strength("move_right")) * float(!shop_open),
		0,
		(Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")) * float(!shop_open)
	) * MAX_SPEED) * float(!dead)
	var jumping: bool = Input.is_action_pressed("jump") && !shop_open && !dead
	
	_process_movement(
		delta,
		move_dir,
		jumping
	)
	
	var target_basis: Basis = head.global_basis.orthonormalized()
	head_offset = head_offset.orthonormalized().slerp(target_basis, 16.0 * delta)
	head.global_basis = head_offset
	camera.global_basis = target_basis.rotated(Vector3.UP, PI)
	camera.global_rotation.x = tilt_target
	
	camera.rotation.x += camera_offset.y
	camera.rotation.y += camera_offset.x
	
	for i in weapons.size():
		var weapon: MechWeapon = weapons[i]
		var crosshair: Control = weapon_crosshairs[i]
		crosshair.visible = weapon != null
		if weapon:
			crosshair.position = camera.unproject_position(weapon.get_target_point())
	
	hp_progress_bar.max_value = max_hp
	hp_progress_bar.value = current_hp
	shields_progress_bar.max_value = max_shields
	shields_progress_bar.value = current_shields


func open_shop() -> void:
	shop_open = true
	hud.hide()
	shop_anim.play(&"loop")
	camera.current = false
	shop_camera.current = true
	shop_open_requested.emit()
	inventory.refresh()


func close_shop() -> void:
	shop_open = false
	hud.show()
	shop_anim.stop()
	shop_camera.current = false
	camera.current = true


func _on_heat_updated(amount: float, maximum: float) -> void:
	heat_progress_bar.max_value = maximum
	heat_progress_bar.value = amount
	heat_progress_bar.modulate.a = amount / maximum


var shield_hit_tween: Tween
var hp_hit_tween: Tween

func _on_shields_hit() -> void:
	shield_hit_feedback.show()
	shield_hit_feedback.modulate = Color.WHITE
	if shield_hit_tween:
		shield_hit_tween.kill()
	shield_hit_tween = create_tween()
	shield_hit_tween.tween_property(
		shield_hit_feedback,
		"modulate",
		Color.TRANSPARENT,
		0.1
	)


func _on_hp_hit() -> void:
	hp_hit_feedback.show()
	hp_hit_feedback.modulate = Color.WHITE
	if hp_hit_tween:
		hp_hit_tween.kill()
	hp_hit_tween = create_tween()
	hp_hit_tween.tween_property(
		hp_hit_feedback,
		"modulate",
		Color.TRANSPARENT,
		0.1
	)
