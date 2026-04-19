extends CanvasLayer

const PANEL_MARGIN := Vector2(6, 6)

var _overlay_open: bool = false
@onready var _panel: PanelContainer = $GameOptionsMenu


func _ready() -> void:
	layer = 118
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_panel.close_requested.connect(_on_close_pressed)
	get_viewport().size_changed.connect(_apply_viewport_layout)
	call_deferred(&"_apply_viewport_layout")
	_set_overlay_open(false)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"game_options"):
		_set_overlay_open(not _overlay_open)
	_update_pause_for_panel_hover()


func _on_close_pressed() -> void:
	_set_overlay_open(false)


func _update_pause_for_panel_hover() -> void:
	if not _overlay_open:
		return
	var mp := get_viewport().get_mouse_position()
	get_tree().paused = _panel.get_global_rect().has_point(mp)


func _set_overlay_open(open: bool) -> void:
	_overlay_open = open
	_panel.visible = open
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	if not open:
		get_tree().paused = false


func _apply_viewport_layout() -> void:
	var sz: Vector2 = get_viewport().get_visible_rect().size
	if sz.x < 2.0 or sz.y < 2.0:
		sz = Vector2(get_viewport().size)
	_panel.position = PANEL_MARGIN
	var max_inner := (sz - PANEL_MARGIN * 2.0).max(Vector2(160, 120))
	if _panel.has_method(&"apply_viewport_max_size"):
		_panel.apply_viewport_max_size(max_inner)
