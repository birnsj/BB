class_name MouseDragState
extends State

## Release quicker than this (ms) counts as a "click" for point-to-move.
const CLICK_MAX_DURATION_MS: int = 250
## If the cursor moves farther than this between press and release, it was a drag, not a tap.
const CLICK_MAX_MOVE_PX: float = 28.0

var _press_time_ms: int = 0
var _press_pos: Vector2 = Vector2.ZERO
var _prev_lmb_down: bool = true


func enter(_payload: Variant = null) -> void:
	_press_time_ms = Time.get_ticks_msec()
	_press_pos = player.get_global_mouse_position()
	_prev_lmb_down = true


func physics_update(_delta: float) -> void:
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
		return

	var lmb_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if _prev_lmb_down and not lmb_down:
		var release_pos := player.get_global_mouse_position()
		var elapsed := Time.get_ticks_msec() - _press_time_ms
		var moved := _press_pos.distance_to(release_pos)
		if elapsed < CLICK_MAX_DURATION_MS and moved < CLICK_MAX_MOVE_PX:
			state_machine.transition_to(&"move_to_point", release_pos)
		else:
			state_machine.transition_to(&"idle")
		_prev_lmb_down = lmb_down
		return

	_prev_lmb_down = lmb_down

	if lmb_down:
		var target := player.get_global_mouse_position()
		var to_target := target - player.global_position
		if to_target.length() < StateMachine.ARRIVE_DISTANCE:
			player.velocity = Vector2.ZERO
		else:
			player.velocity = to_target.normalized() * StateMachine.MOVE_SPEED
	else:
		player.velocity = Vector2.ZERO
		state_machine.transition_to(&"idle")
