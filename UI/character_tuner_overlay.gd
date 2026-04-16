extends CanvasLayer

const CONFIG_PATH := "user://character_tuning.cfg"
## Compact panel (logical px); leaves most of the viewport for gameplay.
const PANEL_MAX_SIZE := Vector2(272, 188)
const PANEL_MARGIN := Vector2(6, 6)

## (section, property, label, min, max, step, use_int)
const _ROWS: Array[Dictionary] = [
	{
		"section": "player",
		"title": "Movement",
		"rows": [
			{"p": "move_speed", "l": "Move speed", "mn": 50.0, "mx": 450.0, "st": 1.0, "i": false},
			{"p": "arrive_distance", "l": "Arrive distance", "mn": 1.0, "mx": 48.0, "st": 0.5, "i": false},
			{
				"p": "mouse_drag_lmb_up_streak_required",
				"l": "LMB-up streak",
				"mn": 1.0,
				"mx": 30.0,
				"st": 1.0,
				"i": true
			},
			{
				"p": "mouse_drag_close_speed_multiplier",
				"l": "Drag near-cursor ×",
				"mn": 1.0,
				"mx": 2.5,
				"st": 0.02,
				"i": false
			},
			{
				"p": "mouse_drag_speed_blend_distance",
				"l": "Drag blend dist",
				"mn": 24.0,
				"mx": 600.0,
				"st": 4.0,
				"i": false
			},
			{
				"p": "move_to_point_far_speed_multiplier",
				"l": "Click-move far ×",
				"mn": 1.0,
				"mx": 2.5,
				"st": 0.02,
				"i": false
			},
			{
				"p": "move_to_point_speed_blend_distance",
				"l": "Click-move blend dist",
				"mn": 40.0,
				"mx": 800.0,
				"st": 5.0,
				"i": false
			},
			{
				"p": "move_to_point_arrival_slow_radius",
				"l": "Arrival slow radius",
				"mn": 16.0,
				"mx": 400.0,
				"st": 2.0,
				"i": false
			},
			{
				"p": "move_to_point_arrival_min_speed_mul",
				"l": "Arrival min speed ×",
				"mn": 0.05,
				"mx": 1.0,
				"st": 0.01,
				"i": false
			},
		]
	},
	{
		"section": "player",
		"title": "Facing",
		"rows": [
			{"p": "move_anim_eps2", "l": "Walk/idle eps²", "mn": 0.1, "mx": 100.0, "st": 0.5, "i": false},
			{"p": "facing_vertical_bias", "l": "Vertical bias", "mn": 0.25, "mx": 4.0, "st": 0.05, "i": false},
		]
	},
	{
		"section": "input_mouse",
		"title": "Input (mouse)",
		"rows": [
			{"p": "click_max_duration_ms", "l": "Click max ms", "mn": 50.0, "mx": 2000.0, "st": 10.0, "i": true},
			{"p": "click_max_move_px", "l": "Click max move px", "mn": 8.0, "mx": 200.0, "st": 1.0, "i": false},
		]
	},
	{
		"section": "combat",
		"title": "Combat",
		"rows": [
			{"p": "attack_offset_base", "l": "Attack offset base", "mn": 0.0, "mx": 40.0, "st": 0.5, "i": false},
			{"p": "attack_offset_north_extra", "l": "North extra", "mn": 0.0, "mx": 40.0, "st": 0.5, "i": false},
		]
	},
	{
		"section": "camera",
		"title": "Camera",
		"rows": [
			{"p": "pan_speed", "l": "Pan speed", "mn": 50.0, "mx": 600.0, "st": 5.0, "i": false},
			{"p": "recenter_duration", "l": "Recenter duration", "mn": 0.1, "mx": 2.0, "st": 0.05, "i": false},
			{"p": "pan_limit_half_screens", "l": "Pan limit (½ screens)", "mn": 0.5, "mx": 6.0, "st": 0.1, "i": false},
			{"p": "camera_player_move_eps2", "l": "Move eps² (camera)", "mn": 0.1, "mx": 100.0, "st": 0.5, "i": false},
			{
				"p": "mouse_drag_recenter_sustain_ticks",
				"l": "Drag recenter ticks",
				"mn": 1.0,
				"mx": 30.0,
				"st": 1.0,
				"i": true
			},
			{"p": "follow_smoothness", "l": "Follow smoothness", "mn": 0.5, "mx": 12.0, "st": 0.1, "i": false},
		]
	},
]

var _profile: CharacterTuningProfile
var _panel: PanelContainer
var _recenter_on_movement_cb: CheckBox
var _sliders: Dictionary = {} ## StringName -> HSlider
var _value_labels: Dictionary = {} ## StringName -> Label
var _suppress_slider_signal: bool = false
var _overlay_open: bool = false
var _prev_physical_toggle_down: bool = false


func _ready() -> void:
	## Above [code]Player/StateDebugLayer[/code] ([member CanvasLayer.layer] 100); autoload so any main scene gets the UI.
	layer = 128
	## Still run while [member SceneTree.paused] so we can un-pause when the cursor leaves the panel or the overlay closes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_profile = CharacterTuningProfile.new()
	_build_ui()
	get_viewport().size_changed.connect(_apply_viewport_layout)
	call_deferred(&"_apply_viewport_layout")
	_set_overlay_open(false)
	call_deferred(&"_load_config_and_apply")
	print("Character tuner: F3 / F10 — toggle (Input Map: character_tuner_toggle).")


func _process(_delta: float) -> void:
	var action := Input.is_action_just_pressed(&"character_tuner_toggle")
	var phy := Input.is_physical_key_pressed(KEY_F3) or Input.is_physical_key_pressed(KEY_F10)
	var phy_edge := phy and not _prev_physical_toggle_down
	_prev_physical_toggle_down = phy
	if action or phy_edge:
		_set_overlay_open(not _overlay_open)

	_update_pause_for_panel_hover()


func _update_pause_for_panel_hover() -> void:
	if not _overlay_open:
		get_tree().paused = false
		return
	var mp := get_viewport().get_mouse_position()
	get_tree().paused = _panel.get_global_rect().has_point(mp)


func _set_overlay_open(open: bool) -> void:
	_overlay_open = open
	_panel.visible = open
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	if not open:
		get_tree().paused = false


## [CanvasLayer] is not a [Control], so children get no layout rect from anchors — set explicit [member Control.position] / [member Control.size].
func _apply_viewport_layout() -> void:
	var sz: Vector2 = get_viewport().get_visible_rect().size
	if sz.x < 2.0 or sz.y < 2.0:
		sz = Vector2(get_viewport().size)
	_panel.position = PANEL_MARGIN
	var max_inner := (sz - PANEL_MARGIN * 2.0).max(Vector2(160, 120))
	_panel.size = Vector2(
		minf(PANEL_MAX_SIZE.x, max_inner.x),
		minf(PANEL_MAX_SIZE.y, max_inner.y)
	)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 4)
	_panel.add_child(outer)

	var title := Label.new()
	title.text = "Tuner (F3/F10)"
	outer.add_child(title)

	_recenter_on_movement_cb = CheckBox.new()
	_recenter_on_movement_cb.text = "Recenter cam on movement"
	_recenter_on_movement_cb.tooltip_text = (
		"When on, walking (keyboard), LMB-drag, and click-to-move start pull the view back toward the player. "
		+ "Space still recenters when off."
	)
	_recenter_on_movement_cb.toggled.connect(_on_recenter_on_movement_toggled)
	outer.add_child(_recenter_on_movement_cb)

	var btn_row := HBoxContainer.new()
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	btn_row.add_child(save_btn)
	var reset_btn := Button.new()
	reset_btn.text = "Reset defaults"
	reset_btn.pressed.connect(_on_reset_pressed)
	btn_row.add_child(reset_btn)
	outer.add_child(btn_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 72)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for block: Dictionary in _ROWS:
		var sec := Label.new()
		sec.text = str(block.get("title", ""))
		sec.add_theme_font_size_override("font_size", 13)
		list.add_child(sec)
		for row: Dictionary in block.get("rows", []):
			list.add_child(_make_slider_row(row))

	_refresh_all_sliders()


func _on_recenter_on_movement_toggled(pressed: bool) -> void:
	_profile.camera_recenter_on_movement = pressed
	TuningRegistry.apply_for_id(&"player", _profile)
	_save_config()


func _make_slider_row(row: Dictionary) -> Control:
	var prop: StringName = row["p"]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var lab := Label.new()
	lab.text = str(row["l"])
	lab.custom_minimum_size.x = 118
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(lab)
	var s := HSlider.new()
	s.min_value = float(row["mn"])
	s.max_value = float(row["mx"])
	s.step = float(row["st"])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(_on_slider_changed.bind(prop, bool(row["i"])))
	h.add_child(s)
	var vl := Label.new()
	vl.custom_minimum_size.x = 52
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(vl)
	_sliders[prop] = s
	_value_labels[prop] = vl
	return h


func _on_slider_changed(v: float, prop: StringName, as_int: bool) -> void:
	if _suppress_slider_signal:
		return
	if as_int:
		_profile.set(prop, int(round(v)))
	else:
		_profile.set(prop, v)
	_update_value_label(prop)
	TuningRegistry.apply_for_id(&"player", _profile)
	_save_config()


func _update_value_label(prop: StringName) -> void:
	var vl: Label = _value_labels.get(prop) as Label
	if vl == null:
		return
	var val: Variant = _profile.get(prop)
	if val is int:
		vl.text = str(val)
	elif val is float:
		vl.text = "%.3f" % float(val)
	else:
		vl.text = str(val)


func _refresh_all_sliders() -> void:
	_suppress_slider_signal = true
	for prop: Variant in _sliders.keys():
		var s: HSlider = _sliders[prop] as HSlider
		var v: Variant = _profile.get(prop)
		s.value = float(v) if v != null else s.min_value
		_update_value_label(prop as StringName)
	_suppress_slider_signal = false
	if _recenter_on_movement_cb:
		_recenter_on_movement_cb.set_block_signals(true)
		_recenter_on_movement_cb.button_pressed = _profile.camera_recenter_on_movement
		_recenter_on_movement_cb.set_block_signals(false)


func _load_config_and_apply() -> void:
	var cf := ConfigFile.new()
	if cf.load(CONFIG_PATH) == OK:
		for block: Dictionary in _ROWS:
			var section: String = str(block.get("section", ""))
			for row: Dictionary in block.get("rows", []):
				var prop: String = str(row["p"])
				if not cf.has_section_key(section, prop):
					continue
				var raw: Variant = cf.get_value(section, prop)
				if bool(row["i"]):
					_profile.set(prop, int(raw))
				else:
					_profile.set(prop, float(raw))
		if cf.has_section_key("camera", "camera_recenter_on_movement"):
			_profile.camera_recenter_on_movement = bool(cf.get_value("camera", "camera_recenter_on_movement"))
	_refresh_all_sliders()
	TuningRegistry.apply_for_id(&"player", _profile)


func _save_config() -> void:
	var cf := ConfigFile.new()
	for block: Dictionary in _ROWS:
		var section: String = str(block.get("section", ""))
		for row: Dictionary in block.get("rows", []):
			var prop: String = str(row["p"])
			cf.set_value(section, prop, _profile.get(prop))
	cf.set_value("camera", "camera_recenter_on_movement", _profile.camera_recenter_on_movement)
	cf.save(CONFIG_PATH)


func _on_save_pressed() -> void:
	_save_config()


func _on_reset_pressed() -> void:
	_profile = CharacterTuningProfile.new()
	_refresh_all_sliders()
	TuningRegistry.apply_for_id(&"player", _profile)
	_save_config()
