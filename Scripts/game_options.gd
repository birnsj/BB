extends Node

## Player-facing settings: [member CONFIG_PATH]. Applied after character tuning so edge scroll and display prefs win.
signal settings_changed

const CONFIG_PATH := "user://game_options.cfg"

var edge_scroll_enabled: bool = true
## WASD pan speed and base multiplier for edge scroll ([code]pan_speed[/code] on the game camera).
var pan_speed: float = 220.0
var edge_scroll_speed_scale: float = 1.0
var master_volume_linear: float = 1.0
var fullscreen: bool = false
var vsync: bool = true


func _ready() -> void:
	load_from_disk()
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred(&"apply")


func _on_scene_changed() -> void:
	call_deferred(&"apply")


func load_from_disk() -> void:
	var cf := ConfigFile.new()
	if cf.load(CONFIG_PATH) != OK:
		return
	if cf.has_section_key("camera", "edge_scroll_enabled"):
		edge_scroll_enabled = bool(cf.get_value("camera", "edge_scroll_enabled"))
	if cf.has_section_key("camera", "edge_scroll_speed_scale"):
		edge_scroll_speed_scale = float(cf.get_value("camera", "edge_scroll_speed_scale"))
	if cf.has_section_key("camera", "pan_speed"):
		pan_speed = float(cf.get_value("camera", "pan_speed"))
	if cf.has_section_key("audio", "master_volume_linear"):
		master_volume_linear = float(cf.get_value("audio", "master_volume_linear"))
	if cf.has_section_key("display", "fullscreen"):
		fullscreen = bool(cf.get_value("display", "fullscreen"))
	if cf.has_section_key("display", "vsync"):
		vsync = bool(cf.get_value("display", "vsync"))


func save_to_disk() -> void:
	var cf := ConfigFile.new()
	cf.set_value("camera", "edge_scroll_enabled", edge_scroll_enabled)
	cf.set_value("camera", "pan_speed", pan_speed)
	cf.set_value("camera", "edge_scroll_speed_scale", edge_scroll_speed_scale)
	cf.set_value("audio", "master_volume_linear", master_volume_linear)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "vsync", vsync)
	cf.save(CONFIG_PATH)


func apply() -> void:
	_apply_camera()
	_apply_audio()
	_apply_display()
	settings_changed.emit()


func _apply_camera() -> void:
	var cam := get_tree().get_first_node_in_group(&"game_camera") as Node
	if cam == null:
		return
	cam.set(&"edge_scroll_enabled", edge_scroll_enabled)
	cam.set(&"pan_speed", pan_speed)
	cam.set(&"edge_scroll_speed_scale", edge_scroll_speed_scale)


func get_option_value(key: StringName) -> Variant:
	match key:
		&"edge_scroll_enabled":
			return edge_scroll_enabled
		&"pan_speed":
			return pan_speed
		&"edge_scroll_speed_scale":
			return edge_scroll_speed_scale
		&"master_volume_linear":
			return master_volume_linear
		&"fullscreen":
			return fullscreen
		&"vsync":
			return vsync
	return null


func set_option_value(key: StringName, value: Variant) -> void:
	match key:
		&"edge_scroll_enabled":
			edge_scroll_enabled = bool(value)
		&"pan_speed":
			pan_speed = float(value)
		&"edge_scroll_speed_scale":
			edge_scroll_speed_scale = float(value)
		&"master_volume_linear":
			master_volume_linear = float(value)
		&"fullscreen":
			fullscreen = bool(value)
		&"vsync":
			vsync = bool(value)
		_:
			return
	save_to_disk()
	apply()


func _apply_audio() -> void:
	var idx := AudioServer.get_bus_index(&"Master")
	if idx < 0:
		return
	var lin := clampf(master_volume_linear, 0.0, 1.0)
	if lin <= 0.0001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(lin))


func _apply_display() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
