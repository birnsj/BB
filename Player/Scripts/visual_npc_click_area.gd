extends Area2D


func _ready() -> void:
	input_event.connect(_on_input_event)


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	NpcDialog.open_dialog()
	viewport.set_input_as_handled()
