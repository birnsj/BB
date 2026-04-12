class_name StateMachine
extends Node

signal state_changed(state_key: StringName)

## Player movement tuning (used by movement states).
const MOVE_SPEED: float = 200.0
const ARRIVE_DISTANCE: float = 4.0

var player: CharacterBody2D

var _states: Dictionary = {}
var current: State


func configure(p: CharacterBody2D) -> void:
	player = p
	_states.clear()
	_register_state_child(p, &"idle", "Idle")
	_register_state_child(p, &"keyboard_move", "KeyboardMove")
	_register_state_child(p, &"mouse_drag", "MouseDrag")
	_register_state_child(p, &"move_to_point", "MoveToPoint")
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
		return
	if current:
		current.exit()
	current = next_state
	current.enter(payload)
	state_changed.emit(next)


func physics_update(delta: float) -> void:
	if current:
		current.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if current:
		current.handle_input(event)
