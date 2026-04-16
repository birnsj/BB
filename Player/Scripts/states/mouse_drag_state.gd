class_name MouseDragState
extends State

## Press→release within this time (ms) can still count as a click for point-to-move (not a drag).
@export var click_max_duration_ms: int = 520
## Max **viewport / screen** movement between press and release to count as a click (stable when the camera is panned or tweening; world-space distance is not).
@export var click_max_move_px: float = 56.0

var _press_time_ms: int = 0
## Viewport pixel position at drag start ([method Viewport.get_mouse_position]); used with [member click_max_move_px] in screen space.
var _press_screen: Vector2 = Vector2.ZERO
var _prev_lmb_down: bool = true
var _release_screen: Vector2 = Vector2.ZERO
var _commit_release_pending: bool = false


func enter(_payload: Variant = null) -> void:
	var vp := player.get_viewport()
	_press_time_ms = Time.get_ticks_msec()
	_press_screen = vp.get_mouse_position()
	_prev_lmb_down = true
	_commit_release_pending = false


func _world_mouse() -> Vector2:
	return (player as Player).get_world_mouse()


func _commit_lmb_release() -> void:
	_commit_release_pending = false
	if state_machine.current != self:
		return
	var release_world := (player as Player).viewport_px_to_world(_release_screen)
	var moved_screen := _press_screen.distance_to(_release_screen)
	var elapsed := Time.get_ticks_msec() - _press_time_ms
	if elapsed < click_max_duration_ms and moved_screen < click_max_move_px:
		state_machine.transition_to(&"move_to_point", release_world)
	else:
		state_machine.transition_to(&"idle")


func physics_update(_delta: float) -> void:
	if State.is_attack_input_held():
		state_machine.transition_to(&"attack")
		return
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
		return

	var lmb_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if _commit_release_pending:
		player.velocity = Vector2.ZERO
		return

	if _prev_lmb_down and not lmb_down:
		_release_screen = player.get_viewport().get_mouse_position()
		_commit_release_pending = true
		player.velocity = Vector2.ZERO
		call_deferred(&"_commit_lmb_release")
		_prev_lmb_down = false
		return

	_prev_lmb_down = lmb_down

	if lmb_down:
		var target := _world_mouse()
		var to_target := target - player.global_position
		var dist := to_target.length()
		var arrive := state_machine.arrive_distance
		if dist < arrive:
			player.velocity = Vector2.ZERO
		else:
			var blend_end := maxf(state_machine.mouse_drag_speed_blend_distance, arrive + 1.0)
			var t := clampf((dist - arrive) / (blend_end - arrive), 0.0, 1.0)
			var mul_drag := lerpf(state_machine.mouse_drag_close_speed_multiplier, 1.0, t)
			var mul_arrive := state_machine.arrival_slow_multiplier(dist)
			player.velocity = to_target.normalized() * state_machine.move_speed * mul_drag * mul_arrive
	else:
		player.velocity = Vector2.ZERO
		state_machine.transition_to(&"idle")
