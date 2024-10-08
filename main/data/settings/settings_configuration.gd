class_name SettingsConfiguration extends Resource

signal updated

@export_enum("low", "medium", "high") var graphics_quality: int = 1:
	set(val):
		graphics_quality = val
		updated.emit()
@export var display_scale: int = 1: # applied scale is 1/display_scale
	set(val):
		display_scale = val
		updated.emit()
@export var window_mode: DisplayServer.WindowMode = DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED:
	set(val):
		window_mode = val
		updated.emit()
@export var muse_device_name: String = "MuseS-8DAB":
	set(val):
		muse_device_name = val
		updated.emit()
