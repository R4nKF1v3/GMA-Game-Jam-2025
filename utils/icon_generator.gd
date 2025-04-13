@tool
extends SubViewport

signal texture_baked(image : Image)

@export var object_to_render: Node3D
@export var save_path: String
@export var apply: bool :
	set(value):
		if object_to_render && !save_path.is_empty():
			create_scene_img(save_path)


func create_scene_img(png_path):
	texture_baked.connect(_texture_baked.bind(png_path))
	refresh()


func _texture_baked(img : Image, png_path):
	img.save_png(png_path)
	texture_baked.disconnect(_texture_baked)


# If true, the object will rotate. If false the script will emit a
# "texture_baked" signal and the delete itself
@export var in_game : bool = false 

var object : Node3D


func _ready() -> void:
	set_process(false)


# Instantiate the scene and center the object to camera
func refresh():
	object = object_to_render
	frame = 0
	rot_angle = 0.0
	set_process(true)


var frame = 0
var rot_angle = 0.0
func _process(delta):
	if in_game:
		object.basis = object.basis.rotated(Vector3.UP, rot_angle)
		rot_angle += delta
	else:
		# 0 is the render frame. 1: frame has been rendered, emit the signal
		if frame > 0:
			texture_baked.emit(self.get_texture().get_image())
			set_process(false)
	frame += 1
