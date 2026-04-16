class_name KeyboardMoveState
extends State


func physics_update(_delta: float) -> void:
	state_machine.update_mouse_drag_ghost_suppression()
	if State.is_attack_input_held():
		state_machine.transition_to(&"attack")
		return
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.length_squared() > 0.0:
		player.velocity = direction * state_machine.move_speed
	else:
		if (
			not state_machine.ignore_mouse_drag_until_lmb_up
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		):
			state_machine.transition_to(&"mouse_drag")
		else:
			state_machine.transition_to(&"idle")
