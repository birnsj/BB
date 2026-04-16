class_name MoveToPointState
extends State

var _target: Vector2 = Vector2.ZERO
## [method Player.global_position] to [member _target] distance at click commit (drives speed boost for long moves).
var _click_commit_distance: float = 0.0


func enter(payload: Variant = null) -> void:
	if payload is Vector2:
		_target = payload
		_click_commit_distance = player.global_position.distance_to(_target)
		state_machine.arm_mouse_drag_ghost_suppression()
		(player as Player).request_camera_walk_start_recenter()
		return
	push_error(
		"MoveToPointState.enter: expected Vector2 destination, got %s. Falling back to idle." % payload
	)
	state_machine.transition_to(&"idle")


func physics_update(_delta: float) -> void:
	state_machine.update_mouse_drag_ghost_suppression()
	if State.is_attack_input_held():
		state_machine.transition_to(&"attack")
		return
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
		return
	if (
		not state_machine.ignore_mouse_drag_until_lmb_up
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	):
		state_machine.transition_to(&"mouse_drag")
		return

	var to_point := _target - player.global_position
	if to_point.length() < state_machine.arrive_distance:
		player.velocity = Vector2.ZERO
		state_machine.transition_to(&"idle")
	else:
		var d := to_point.length()
		var blend := maxf(state_machine.move_to_point_speed_blend_distance, 1.0)
		var t_far := clampf(_click_commit_distance / blend, 0.0, 1.0)
		var mul_far := lerpf(1.0, state_machine.move_to_point_far_speed_multiplier, t_far)
		var mul_arrive := state_machine.arrival_slow_multiplier(d)
		player.velocity = to_point.normalized() * state_machine.move_speed * mul_far * mul_arrive
