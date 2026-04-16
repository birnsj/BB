class_name CharacterTuningProfile
extends Resource

## Stable id for [member TuningRegistry] (e.g. [code]&"player"[/code], future [code]&"goblin"[/code]).
@export var tuning_id: StringName = &"player"
@export var display_name: String = "Player"

@export_group("Movement")
@export var move_speed: float = 200.0
@export var arrive_distance: float = 4.0
@export var mouse_drag_lmb_up_streak_required: int = 6
## LMB drag: speed multiplier at the arrival edge (closest while still moving); lerps to [code]1.0[/code] by [member mouse_drag_speed_blend_distance].
@export var mouse_drag_close_speed_multiplier: float = 1.28
## World px from cursor: at this distance (and farther) drag speed is full [member move_speed] only ([code]1.0[/code]×).
@export var mouse_drag_speed_blend_distance: float = 220.0
## Click-to-move: speed multiplier when the clicked point is at/ beyond [member move_to_point_speed_blend_distance] from the player at click time.
@export var move_to_point_far_speed_multiplier: float = 1.28
## Click-to-move: world distance from player to click at commit; at [code]0[/code] speed is [code]1.0[/code]×, ramps up to multiplier at this distance.
@export var move_to_point_speed_blend_distance: float = 320.0
## Click-move & LMB drag: within this distance (world px) of the goal, speed eases down toward [member move_to_point_arrival_min_speed_mul].
@export var move_to_point_arrival_slow_radius: float = 88.0
## Minimum speed multiplier just above [member arrive_distance] before stopping ([code]0.2[/code]–[code]0.45[/code] typical).
@export var move_to_point_arrival_min_speed_mul: float = 0.28

@export_group("Facing")
@export var move_anim_eps2: float = 4.0
@export var facing_vertical_bias: float = 1.0

@export_group("Input_mouse")
@export var click_max_duration_ms: int = 520
@export var click_max_move_px: float = 56.0

@export_group("Combat")
@export var attack_offset_base: float = 12.0
@export var attack_offset_north_extra: float = 14.0

@export_group("Camera")
## When [code]true[/code], keyboard walk-start, LMB-drag sustain, and click-to-move start smooth the camera back toward the player. Space / mapped recenter still work when [code]false[/code].
@export var camera_recenter_on_movement: bool = true
@export var pan_speed: float = 220.0
@export var recenter_duration: float = 0.45
@export var pan_limit_half_screens: float = 2.0
@export var camera_player_move_eps2: float = 4.0
@export var mouse_drag_recenter_sustain_ticks: int = 4
@export var follow_smoothness: float = 3.0


func duplicate_as_profile() -> CharacterTuningProfile:
	return duplicate(true) as CharacterTuningProfile
