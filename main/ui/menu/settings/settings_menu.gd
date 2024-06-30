class_name SettingsMenu extends Menu

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("Option"):
		if node is OptionButton:
			node.item_selected.connect(_on_option_selected.unbind(1))
	
	%GraphicsQualityOptionButton.select(GlobalData.settings_configuration.graphics_quality)
	%DisplayScaleOptionButton.select(GlobalData.settings_configuration.display_scale - 1)
	
	close()

func _on_option_selected() -> void:
	GlobalData.settings_configuration.graphics_quality = %GraphicsQualityOptionButton.selected
	GlobalData.settings_configuration.display_scale = 1 + %DisplayScaleOptionButton.selected

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if is_open:
			close()
		else:
			open()

func open() -> void:
	super.open()
	visible = true

func close() -> void:
	super.close()
	visible = false
	GlobalData.save()
