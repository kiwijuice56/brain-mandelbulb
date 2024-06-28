class_name ToggleHelpButton
extends Button

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	get_node("%HelpPanelContainer").visible = not get_node("%HelpPanelContainer").visible
	if not get_node("%HelpPanelContainer").visible:
		text = "help"
	else:
		text = "close"
