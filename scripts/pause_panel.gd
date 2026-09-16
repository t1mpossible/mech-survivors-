extends Panel


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_parent().get_parent()._resume_game()
		get_viewport().set_input_as_handled()
