extends Control

func _new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _coming_soon() -> void:
	$Title.text = "СКОРО"

func _exit_game() -> void:
	get_tree().quit()
