class_name Menu extends Control

var is_open: bool = false

func open() -> void:
	is_open = true

func close() -> void:
	is_open = false
