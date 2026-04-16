extends Camera2D

## WASD pans the view relative to the player ([member position] in the player's local space). Arrow keys move the player.
## Mouse near the viewport edge pans like RTS games ([member edge_scroll_enabled], [member edge_scroll_margin_px]).
## [kbd]Space[/kbd] and walk start both use the same smooth recenter ([member recenter_duration]) toward the player.
## Pan range: [member pan_limit_half_screens] viewport half-widths/heights each way (4 screens total span).

@export var pan_speed: float = 220.0
## When [code]true[/code], moving the cursor within [member edge_scroll_margin_px] of the window edge pans the camera (same axes as [code]cam_pan_*[/code]).
@export var edge_scroll_enabled: bool = true
## Viewport pixels from each edge where edge scrolling ramps from 0 to full ([member edge_scroll_speed_scale]).
@export var edge_scroll_margin_px: float = 36.0
## Multiplier for the edge-scroll component (keyboard pan uses [member pan_speed] as-is).
@export var edge_scroll_speed_scale: float = 1.0
@export var recenter_duration: float = 0.45
## Max offset from the player along each axis, in multiples of the base viewport size (480×270). 2 = ±2 screens = 4 screens total width/height.
@export var pan_limit_half_screens: float = 2.0
## Squared speed above this counts as "moving" (align with player walk vs idle, ~4.0).
@export var player_move_eps2: float = 4.0
## Hold-drag: recenter only after this many consecutive physics ticks with movement (avoids yanking the view on a quick tap while panned).
@export var mouse_drag_recenter_sustain_ticks: int = 4
## If [code]false[/code], movement no longer triggers smooth recenter; Space / [code]camera_recenter[/code] still recenter.
@export var recenter_on_movement: bool = true

var _recenter_tween: Tween
var _player_was_moving: bool = false
var _mouse_drag_moving_ticks: int = 0
var _recentered_this_mouse_drag: bool = false
var _pan_limit_label: Label


func _ready() -> void:
	# Match gameplay / state machine (physics). Idle-updated cameras leave get_canvas_transform() stale during _physics_process.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var p := _player_character()
	if p:
		_player_was_moving = p.velocity.length_squared() > player_move_eps2
	_ensure_pan_limit_label()


func _player_character() -> CharacterBody2D:
	var rig := get_parent()
	if rig is CameraLagRig:
		return rig.player_root
	if rig is CharacterBody2D:
		return rig
	if rig is Node2D and rig.get_parent() is CharacterBody2D:
		return rig.get_parent() as CharacterBody2D
	return null


## Viewport pixel coords (same as [member InputEventMouse.position]) -> world on the game canvas. Use this when the camera is not parented to the player.
func viewport_px_to_world(px: Vector2) -> Vector2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * px


func _ensure_pan_limit_label() -> void:
	if _pan_limit_label != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var label := Label.new()
	label.name = &"PanLimitStopLabel"
	label.text = "stop"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 36)
	label.add_theme_color_override(&"font_color", Color(0.95, 0.35, 0.35))
	label.visible = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = -80.0
	label.offset_right = 80.0
	label.offset_top = -56.0
	label.offset_bottom = -12.0
	layer.add_child(label)
	_pan_limit_label = label


func _physics_process(_delta: float) -> void:
	var p := _player_character()
	if p == null:
		return
	var moving := p.velocity.length_squared() > player_move_eps2
	var sm := p.get_node_or_null(^"StateMachine") as StateMachine
	var k := sm.current_key if sm else &""

	# Keyboard (and any non-mouse state): classic walk-start recenter.
	var skip_velocity_edge := k == &"mouse_drag" or k == &"move_to_point"
	if (
		recenter_on_movement
		and moving
		and not _player_was_moving
		and not skip_velocity_edge
	):
		_start_recenter_tween()

	# Hold LMB drag: recenter after sustained movement so quick taps stay clean when panned.
	if k == &"mouse_drag" and recenter_on_movement:
		if moving:
			_mouse_drag_moving_ticks += 1
		else:
			_mouse_drag_moving_ticks = 0
		if (
			moving
			and _mouse_drag_moving_ticks >= mouse_drag_recenter_sustain_ticks
			and not _recentered_this_mouse_drag
		):
			_start_recenter_tween()
			_recentered_this_mouse_drag = true
	else:
		_mouse_drag_moving_ticks = 0
		_recentered_this_mouse_drag = false

	_player_was_moving = moving


func _input(event: InputEvent) -> void:
	_try_recenter_from_key_event(event)


func _unhandled_input(event: InputEvent) -> void:
	_try_recenter_from_key_event(event)


func _try_recenter_from_key_event(event: InputEvent) -> void:
	# Poll-based InputMap misses some keys when GUI/focus runs first; handle raw KEY_SPACE + mapped action.
	if not event is InputEventKey:
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if k.keycode == KEY_SPACE or k.physical_keycode == KEY_SPACE or event.is_action_pressed(&"camera_recenter"):
		_start_recenter_tween()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var kb := Input.get_vector(&"cam_pan_left", &"cam_pan_right", &"cam_pan_up", &"cam_pan_down")
	var edge := Vector2.ZERO
	if edge_scroll_enabled:
		var vp := get_viewport()
		var vsize := vp.get_visible_rect().size
		var mouse := vp.get_mouse_position()
		edge = _edge_scroll_vector_clamped(mouse, vsize) * edge_scroll_speed_scale
	var pan := kb + edge
	if pan.length_squared() <= 0.0001:
		if _pan_limit_label:
			_pan_limit_label.visible = false
		return
	_kill_recenter_tween_if_running()
	var move := pan.limit_length(1.0) * pan_speed * delta
	var intended := position + move
	var half := _viewport_half_extent()
	var clamped := _clamp_position_to_limit(intended)
	var hit_limit := intended != clamped
	position = clamped
	if _pan_limit_label:
		_pan_limit_label.visible = hit_limit


## Returns a vector in the same space as [method Input.get_vector] for [code]cam_pan_*[/code] (each axis roughly [code]-1…1[/code]).
func _edge_scroll_vector_clamped(mouse: Vector2, vsize: Vector2) -> Vector2:
	if vsize.x < 2.0 or vsize.y < 2.0:
		return Vector2.ZERO
	var m := maxf(edge_scroll_margin_px, 1.0)
	m = minf(m, minf(vsize.x, vsize.y) * 0.45)
	var mx := clampf(mouse.x, 0.0, vsize.x)
	var my := clampf(mouse.y, 0.0, vsize.y)
	var vx := 0.0
	var vy := 0.0
	if mx < m:
		vx = lerpf(-1.0, 0.0, mx / m)
	elif mx > vsize.x - m:
		vx = lerpf(0.0, 1.0, (mx - (vsize.x - m)) / m)
	if my < m:
		vy = lerpf(-1.0, 0.0, my / m)
	elif my > vsize.y - m:
		vy = lerpf(0.0, 1.0, (my - (vsize.y - m)) / m)
	return Vector2(vx, vy)


## Called when click-to-move commits a destination (always runs, even if drag already had velocity).
func request_walk_start_recenter() -> void:
	if not recenter_on_movement:
		return
	_start_recenter_tween()


func _start_recenter_tween() -> void:
	if position.length_squared() < 0.25:
		return
	_kill_recenter_tween_if_running()
	_recenter_tween = create_tween()
	_recenter_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_recenter_tween.tween_property(self, ^"position", Vector2.ZERO, recenter_duration)


func _kill_recenter_tween_if_running() -> void:
	if _recenter_tween != null and _recenter_tween.is_valid():
		_recenter_tween.kill()
	_recenter_tween = null


func _clamp_position_to_limit(pos: Vector2) -> Vector2:
	var half := _viewport_half_extent()
	return Vector2(clampf(pos.x, -half.x, half.x), clampf(pos.y, -half.y, half.y))


func _viewport_half_extent() -> Vector2:
	var vs := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	return vs * pan_limit_half_screens
