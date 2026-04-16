extends CanvasLayer

var _open: bool = false

@onready var _root: Control = $RootLayout
@onready var _goodbye: Button = $RootLayout/Center/Panel/VBox/GoodbyeBtn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	_root.visible = false
	_goodbye.pressed.connect(_on_goodbye_pressed)
	set_process_unhandled_input(true)


func _unhandled_input(_event: InputEvent) -> void:
	if not _open:
		return
	# After Control/UI handling, swallow anything that would reach gameplay (camera, debug, etc.).
	get_viewport().set_input_as_handled()


func open_dialog() -> void:
	if _open:
		return
	# Must run before pausing: pausable nodes will not process [method StateMachine.transition_to] or physics.
	_stop_player_movement()
	_open = true
	_root.visible = true
	get_tree().paused = true
	_root.grab_focus()


func close_dialog() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	get_tree().paused = false
	_stop_player_movement()


func _stop_player_movement() -> void:
	var p := get_tree().get_first_node_in_group(&"game_follow_target") as CharacterBody2D
	if p == null:
		return
	p.velocity = Vector2.ZERO
	var sm := p.get_node_or_null(^"StateMachine") as StateMachine
	if sm:
		sm.transition_to(&"idle")


func _on_goodbye_pressed() -> void:
	close_dialog()
