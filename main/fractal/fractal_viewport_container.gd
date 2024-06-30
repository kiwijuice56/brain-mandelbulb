class_name FractalViewportContainer extends SubViewportContainer

func _ready() -> void:
	GlobalData.settings_configuration.updated.connect(_on_settings_updated)
	_on_settings_updated()

func _on_settings_updated() -> void:
	stretch_shrink = GlobalData.settings_configuration.display_scale
	DisplayServer.window_set_mode(GlobalData.settings_configuration.window_mode)
