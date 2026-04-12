class_name IdleState
extends State


func enter(_payload: Variant = null) -> void:
	player.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state_machine.transition_to(&"mouse_drag")


func handle_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	state_machine.transition_to(&"mouse_drag")
