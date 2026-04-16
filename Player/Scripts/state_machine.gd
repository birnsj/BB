class_name StateMachine
extends Node

signal state_changed(state_key: StringName)

## Player movement tuning (used by movement states).
const MOVE_SPEED: float = 200.0
const ARRIVE_DISTANCE: float = 4.0

var player: CharacterBody2D

var _states: Dictionary = {}
var current: State
## Key of the active state (e.g. [code]&"idle"[/code]); updated in [method transition_to].
var current_key: StringName = &""

var _last_physics_delta: float = 1.0 / 60.0

## After click-to-move, polled LMB can flicker; require several consecutive physics ticks with LMB up before drag is allowed again.
const MOUSE_DRAG_LMB_UP_STREAK_REQUIRED: int = 6

## After click-to-move, [method Input.is_mouse_button_pressed] can stay true for many ticks; don't treat as LMB drag until the streak clears.
var ignore_mouse_drag_until_lmb_up: bool = false
var _mouse_drag_lmb_up_streak: int = 0


func update_mouse_drag_ghost_suppression() -> void:
	if not ignore_mouse_drag_until_lmb_up:
		_mouse_drag_lmb_up_streak = 0
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse_drag_lmb_up_streak = 0
		return
	_mouse_drag_lmb_up_streak += 1
	if _mouse_drag_lmb_up_streak >= MOUSE_DRAG_LMB_UP_STREAK_REQUIRED:
		ignore_mouse_drag_until_lmb_up = false
		_mouse_drag_lmb_up_streak = 0


func arm_mouse_drag_ghost_suppression() -> void:
	ignore_mouse_drag_until_lmb_up = true
	_mouse_drag_lmb_up_streak = 0


func configure(p: CharacterBody2D) -> void:
	player = p
	_states.clear()
	_register_state_child(p, &"idle", "Idle")
	_register_state_child(p, &"keyboard_move", "KeyboardMove")
	_register_state_child(p, &"mouse_drag", "MouseDrag")
	_register_state_child(p, &"move_to_point", "MoveToPoint")
	_register_state_child(p, &"attack", "Attack")
	if not _states.has(&"idle"):
		push_error("StateMachine: failed to register idle state.")
		return
	transition_to(&"idle")


func _register_state_child(p: CharacterBody2D, key: StringName, child_name: String) -> void:
	var child: Node = get_node_or_null(NodePath(child_name))
	if child == null:
		push_error("StateMachine: missing child node '%s' for state '%s'." % [child_name, key])
		return
	if not child is State:
		push_error(
			"StateMachine: node '%s' must use a script that extends State (state key '%s')."
			% [child_name, key]
		)
		return
	_states[key] = child as State
	(child as State).configure(self, p)


func transition_to(next: StringName, payload: Variant = null) -> void:
	var next_state: State = _states.get(next) as State
	if next_state == null:
		push_error("Unknown state: %s" % String(next))
		return
	if current == next_state:
		# Allow a new click destination while already walking (otherwise transition_to no-ops).
		if next == &"move_to_point" and payload is Vector2:
			current.enter(payload)
		return
	if current:
		current.exit()
	current_key = next
	current = next_state
	current.enter(payload)
	state_changed.emit(next)


func physics_update(delta: float) -> void:
	if current == null:
		return
	_last_physics_delta = delta
	## If [method transition_to] runs inside [method State.physics_update], the new state would not run until next frame; run it once so velocity/movement apply immediately.
	var key_before := current_key
	current.physics_update(delta)
	if current_key != key_before:
		current.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if current == null:
		return
	## Mouse / UI transitions often happen in [method Node._input] before [method Node._physics_process]; run the new state's physics once so velocity updates same frame as LMB (mirrors logic in [method physics_update]).
	var key_before := current_key
	current.handle_input(event)
	if current_key != key_before:
		var d: float = _last_physics_delta
		if d <= 0.0:
			d = 1.0 / float(Engine.physics_ticks_per_second)
		current.physics_update(d)
