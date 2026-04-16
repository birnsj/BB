class_name MouseDragState
extends State

## Press→release within this time (ms) can still count as a click for point-to-move (not a drag).
@export var click_max_duration_ms: int = 520
## Max world movement between press and release to count as a click (camera pan / jitter tolerant).
@export var click_max_move_px: float = 64.0

var _press_time_ms: int = 0
var _press_pos: Vector2 = Vector2.ZERO
var _prev_lmb_down: bool = true
## Set in [method handle_input] on LMB release so world position matches the event (camera tween / frame order safe).
var _release_world: Vector2 = Vector2.ZERO
var _has_release_world: bool = false


func enter(_payload: Variant = null) -> void:
	_press_time_ms = Time.get_ticks_msec()
	_press_pos = _world_mouse()
	_prev_lmb_down = true
	_has_release_world = false


func handle_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or event.pressed:
		return
	var mb := event as InputEventMouseButton
	# Project through the game Camera2D (same as [method Player.get_world_mouse]); viewport alone is wrong when the camera is a separate rig.
	_release_world = (player as Player).viewport_px_to_world(mb.position)
	_has_release_world = true


func _world_mouse() -> Vector2:
	return (player as Player).get_world_mouse()


func physics_update(_delta: float) -> void:
	if State.is_attack_input_held():
		state_machine.transition_to(&"attack")
		return
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
		return

	var lmb_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if _prev_lmb_down and not lmb_down:
		var release_pos: Vector2
		if _has_release_world:
			release_pos = _release_world
			_has_release_world = false
		else:
			release_pos = _world_mouse()
		var elapsed := Time.get_ticks_msec() - _press_time_ms
		var moved := _press_pos.distance_to(release_pos)
		if elapsed < click_max_duration_ms and moved < click_max_move_px:
			state_machine.transition_to(&"move_to_point", release_pos)
		else:
			state_machine.transition_to(&"idle")
		_prev_lmb_down = lmb_down
		return

	_prev_lmb_down = lmb_down

	if lmb_down:
		var target := _world_mouse()
		var to_target := target - player.global_position
		if to_target.length() < StateMachine.ARRIVE_DISTANCE:
			player.velocity = Vector2.ZERO
		else:
			player.velocity = to_target.normalized() * StateMachine.MOVE_SPEED
	else:
		player.velocity = Vector2.ZERO
		state_machine.transition_to(&"idle")
