class_name NpcState
extends Node

var state_machine: NpcStateMachine
var player: CharacterBody2D


static func is_attack_input_held() -> bool:
	return Input.is_physical_key_pressed(KEY_TAB) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func configure(sm: NpcStateMachine, p: CharacterBody2D) -> void:
	state_machine = sm
	player = p


## Virtual: called when this state becomes active. [param payload] is state-specific (e.g. move target).
func enter(_payload: Variant = null) -> void:
	pass


## Virtual: called when leaving this state for another.
func exit() -> void:
	pass


## Virtual: run after movement intent is applied; [member CharacterBody2D.move_and_slide] runs on the player afterward.
func physics_update(_delta: float) -> void:
	pass


## Virtual: input events are forwarded here before [method Node._input] returns.
func handle_input(_event: InputEvent) -> void:
	pass
