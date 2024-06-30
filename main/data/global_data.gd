extends Node

const SETTINGS_PATH: String = "user://settings.tres"

var settings_configuration: SettingsConfiguration

func _ready() -> void:
	if ResourceLoader.exists(SETTINGS_PATH):
		settings_configuration = ResourceLoader.load(SETTINGS_PATH)
	else:
		settings_configuration = SettingsConfiguration.new()

func save() -> void:
	ResourceSaver.save(settings_configuration, SETTINGS_PATH)
