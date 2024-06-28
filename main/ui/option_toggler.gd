# Handles parameter input for the shader
class_name OptionToggler
extends Node

# Each string in this array corresponds to a boolean in the shader and an input 
# action to reduce code repetition for simple toggles
const settings: Array = ["ambient_occlusion", "glow", "mirror", "tetrehedron"]

@onready var material: ShaderMaterial = get_tree().get_root().get_node("Main/FractalNavigation").material

func _input(event: InputEvent) -> void:
	for toggle in settings:
		if Input.is_action_just_pressed(toggle):
			material.set_shader_parameter(toggle, not material.get_shader_parameter(toggle))
	for i in range(9):
		if Input.is_key_pressed(KEY_0 + i):
			material.set_shader_parameter("palette", i)
	if event.is_action_pressed("mouse_lock", false):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("threshold_down", false):
		material.set_shader_parameter("collision_threshold", material.get_shader_parameter("collision_threshold") + 6e-4)
	if event.is_action_pressed("threshold_up", false):
		material.set_shader_parameter("collision_threshold", max(1e-4, material.get_shader_parameter("collision_threshold") - 6e-4))
