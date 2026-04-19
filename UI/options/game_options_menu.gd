extends PanelContainer

## Declarative rows: add a block or row to extend the menu.
signal close_requested

const PANEL_MAX_SIZE := Vector2(304, 260)

## type: "bool" | "float" — key must exist on [GameOptions].
const _OPTION_BLOCKS: Array[Dictionary] = [
	{
		"title": "Camera",
		"rows": [
			{"type": "bool", "key": &"edge_scroll_enabled", "label": "Edge scrolling"},
			{
				"type": "float",
				"key": &"pan_speed",
				"label": "Pan / scroll speed",
				"mn": 50.0,
				"mx": 600.0,
				"st": 5.0
			},
			{
				"type": "float",
				"key": &"edge_scroll_speed_scale",
				"label": "Edge scroll strength",
				"mn": 0.25,
				"mx": 2.0,
				"st": 0.05
			},
		]
	},
	{
		"title": "Audio",
		"rows": [
			{
				"type": "float",
				"key": &"master_volume_linear",
				"label": "Master volume",
				"mn": 0.0,
				"mx": 1.0,
				"st": 0.02
			},
		]
	},
	{
		"title": "Display",
		"rows": [
			{"type": "bool", "key": &"fullscreen", "label": "Fullscreen"},
			{"type": "bool", "key": &"vsync", "label": "VSync"},
		]
	},
]

var _checkboxes: Dictionary = {} ## StringName -> CheckBox
var _sliders: Dictionary = {} ## StringName -> HSlider
var _value_labels: Dictionary = {} ## StringName -> Label
var _suppress: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	GameOptions.settings_changed.connect(_refresh_from_game_options)
	call_deferred(&"_refresh_from_game_options")


func _build_ui() -> void:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override(&"separation", 4)
	add_child(outer)

	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override(&"font_size", 16)
	outer.add_child(title)

	var btn_row := HBoxContainer.new()
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	btn_row.add_child(close_btn)
	outer.add_child(btn_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 4)
	scroll.add_child(list)

	for block: Dictionary in _OPTION_BLOCKS:
		var sec := Label.new()
		sec.text = str(block.get("title", ""))
		sec.add_theme_font_size_override(&"font_size", 13)
		list.add_child(sec)
		for row: Dictionary in block.get("rows", []):
			var t: String = str(row.get("type", ""))
			if t == "bool":
				list.add_child(_make_bool_row(row))
			elif t == "float":
				list.add_child(_make_float_row(row))


func _make_bool_row(row: Dictionary) -> Control:
	var key: StringName = row["key"]
	var cb := CheckBox.new()
	cb.text = str(row["label"])
	cb.tooltip_text = str(row.get("tooltip", ""))
	cb.toggled.connect(_on_bool_toggled.bind(key))
	_checkboxes[key] = cb
	return cb


func _make_float_row(row: Dictionary) -> Control:
	var key: StringName = row["key"]
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 4)
	var lab := Label.new()
	lab.text = str(row["label"])
	lab.custom_minimum_size.x = 132
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(lab)
	var s := HSlider.new()
	s.min_value = float(row["mn"])
	s.max_value = float(row["mx"])
	s.step = float(row["st"])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(_on_float_changed.bind(key))
	h.add_child(s)
	var vl := Label.new()
	vl.custom_minimum_size.x = 52
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(vl)
	_sliders[key] = s
	_value_labels[key] = vl
	return h


func _on_bool_toggled(pressed: bool, key: StringName) -> void:
	if _suppress:
		return
	GameOptions.set_option_value(key, pressed)


func _on_float_changed(v: float, key: StringName) -> void:
	if _suppress:
		return
	GameOptions.set_option_value(key, v)
	_update_value_label(key)


func _update_value_label(key: StringName) -> void:
	var vl: Label = _value_labels.get(key) as Label
	if vl == null:
		return
	var val: Variant = GameOptions.get_option_value(key)
	if key == &"master_volume_linear":
		vl.text = "%d%%" % int(round(float(val) * 100.0))
	elif val is float:
		vl.text = "%.2f" % float(val)
	else:
		vl.text = str(val)


func _refresh_from_game_options() -> void:
	_suppress = true
	for key: Variant in _checkboxes.keys():
		var cb: CheckBox = _checkboxes[key] as CheckBox
		cb.set_block_signals(true)
		cb.button_pressed = bool(GameOptions.get_option_value(key as StringName))
		cb.set_block_signals(false)
	for key: Variant in _sliders.keys():
		var s: HSlider = _sliders[key] as HSlider
		var k := key as StringName
		s.set_block_signals(true)
		s.value = float(GameOptions.get_option_value(k))
		s.set_block_signals(false)
		_update_value_label(k)
	_suppress = false


func apply_viewport_max_size(max_inner: Vector2) -> void:
	var sz := Vector2(minf(PANEL_MAX_SIZE.x, max_inner.x), minf(PANEL_MAX_SIZE.y, max_inner.y))
	custom_minimum_size = sz
	size = sz
