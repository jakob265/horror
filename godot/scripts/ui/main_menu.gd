extends Control

signal start_new_game
signal quit_pressed


func _ready() -> void:
	$VBox/NewGame.pressed.connect(func(): start_new_game.emit())
	$VBox/Quit.pressed.connect(func(): quit_pressed.emit())
