class_name MoveToPointState
extends State

var _target: Vector2 = Vector2.ZERO


func enter(payload: Variant = null) -> void:
	if payload is Vector2:
		_target = payload
		return
	push_error(
		"MoveToPointState.enter: expected Vector2 destination, got %s. Falling back to idle." % payload
	)
	state_machine.transition_to(&"idle")


func physics_update(_delta: float) -> void:
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state_machine.transition_to(&"mouse_drag")
		return

	var to_point := _target - player.global_position
	if to_point.length() < StateMachine.ARRIVE_DISTANCE:
		player.velocity = Vector2.ZERO
		state_machine.transition_to(&"idle")
	else:
		player.velocity = to_point.normalized() * StateMachine.MOVE_SPEED
