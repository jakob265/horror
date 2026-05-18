extends Control

signal resume_pressed
signal quit_pressed


func _ready() -> void:
	$Panel/VBox/Resume.pressed.connect(func(): resume_pressed.emit())
	$Panel/VBox/Quit.pressed.connect(func(): quit_pressed.emit())
