class_name NpcIdleState
extends NpcState


func enter(_payload: Variant = null) -> void:
	player.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	state_machine.update_mouse_drag_ghost_suppression()
	if NpcState.is_attack_input_held():
		state_machine.transition_to(&"attack")
		return
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
	elif (
		not state_machine.ignore_mouse_drag_until_lmb_up
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	):
		state_machine.transition_to(&"mouse_drag")


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		state_machine.transition_to(&"attack")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		state_machine.transition_to(&"attack")
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	state_machine.update_mouse_drag_ghost_suppression()
	if state_machine.ignore_mouse_drag_until_lmb_up:
		return
	state_machine.transition_to(&"mouse_drag")
