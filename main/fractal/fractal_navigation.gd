@tool
class_name FractalNavigation extends ColorRect

@export var camera: Camera3D 
@export var muse_status_label: Label
@export var muse_data_label: Label

var gd_muse: GDMuse

var bulb_power_target: float = 8.0
var bulb_power_intermediate: float = 8.0

func _ready() -> void:
	GlobalData.settings_configuration.updated.connect(_on_settings_updated)
	_on_settings_updated()
	
	muse_status_label.text = "No Muse connected. Press `Enter` to connect a headband."
	
	gd_muse = GDMuse.new()
	
	gd_muse.alpha_score_packet_received.connect(_on_alpha_score_received)
	gd_muse.muse_connecting.connect(_on_muse_connecting)
	gd_muse.muse_connected.connect(_on_muse_connected)
	gd_muse.muse_disconnected.connect(_on_muse_disconnected)
	
	gd_muse.listen_for_muses()

func _on_settings_updated() -> void:
	match GlobalData.settings_configuration.graphics_quality:
		0:
			material.set_shader_parameter("bulb_iter", 5)
			material.set_shader_parameter("collision_threshold", 1.0e-2)
			material.set_shader_parameter("light_iter", 32)
			material.set_shader_parameter("max_iter", 96)
		1:
			material.set_shader_parameter("bulb_iter", 6)
			material.set_shader_parameter("collision_threshold", 1.0e-3)
			material.set_shader_parameter("light_iter", 48)
			material.set_shader_parameter("max_iter", 128)
		2:
			material.set_shader_parameter("bulb_iter", 8)
			material.set_shader_parameter("collision_threshold", 1.0e-4)
			material.set_shader_parameter("light_iter", 64)
			material.set_shader_parameter("max_iter", 512)

func _on_muse_connecting() -> void:
	muse_status_label.set.call_deferred("text", "Connecting Muse...")

func _on_muse_connected() -> void:
	muse_status_label.set.call_deferred("text", "Muse connected.")

func _on_muse_disconnected() -> void:
	muse_status_label.set.call_deferred("text", "Muse disconnected. Press `Enter` to connect a headband.")

func _on_alpha_score_received(data: PackedFloat64Array, _timestamp: int) -> void:
	update_fractal.call_deferred(data[1])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept", false):
		gd_muse.connect_muse(GlobalData.settings_configuration.muse_device_name)

func _process(delta: float) -> void:
	material.set_shader_parameter("_cam_pos", camera.global_position)
	material.set_shader_parameter("_cam_mat", camera.global_transform.basis)
	material.set_shader_parameter("_screen_size", size)
	material.set_shader_parameter("bulb_power", bulb_power_intermediate)
	bulb_power_intermediate = lerp(bulb_power_intermediate, bulb_power_target, delta)

func update_fractal(alpha_score: float) -> void:
	muse_data_label.text = "Alpha score: %.3f" % alpha_score
	bulb_power_target = alpha_score * 8.0 + 8.0
