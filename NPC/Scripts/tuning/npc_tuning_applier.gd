class_name NpcTuningApplier
extends RefCounted


static func apply(player: Player, profile: CharacterTuningProfile) -> void:
	if player == null or profile == null:
		return
	var sm := player.get_node_or_null("StateMachine") as NpcStateMachine
	if sm:
		sm.move_speed = profile.move_speed
		sm.arrive_distance = profile.arrive_distance
		sm.mouse_drag_lmb_up_streak_required = profile.mouse_drag_lmb_up_streak_required
		sm.mouse_drag_close_speed_multiplier = profile.mouse_drag_close_speed_multiplier
		sm.mouse_drag_speed_blend_distance = profile.mouse_drag_speed_blend_distance
		sm.move_to_point_far_speed_multiplier = profile.move_to_point_far_speed_multiplier
		sm.move_to_point_speed_blend_distance = profile.move_to_point_speed_blend_distance
		sm.move_to_point_arrival_slow_radius = profile.move_to_point_arrival_slow_radius
		sm.move_to_point_arrival_min_speed_mul = profile.move_to_point_arrival_min_speed_mul
		var md := sm.get_node_or_null("MouseDrag") as NpcMouseDragState
		if md:
			md.click_max_duration_ms = profile.click_max_duration_ms
			md.click_max_move_px = profile.click_max_move_px
	player.move_anim_eps2 = profile.move_anim_eps2
	player.facing_vertical_bias = profile.facing_vertical_bias
	var atk := player.get_node_or_null("Interactions/AttackBox") as NpcAttackHitbox
	if atk:
		atk.attack_offset_base = profile.attack_offset_base
		atk.attack_offset_north_extra = profile.attack_offset_north_extra
	var cam := player.get_tree().get_first_node_in_group(&"game_camera") as Camera2D
	if cam:
		cam.recenter_on_movement = profile.camera_recenter_on_movement
		cam.pan_speed = profile.pan_speed
		cam.recenter_duration = profile.recenter_duration
		cam.pan_limit_half_screens = profile.pan_limit_half_screens
		cam.player_move_eps2 = profile.camera_player_move_eps2
		cam.mouse_drag_recenter_sustain_ticks = profile.mouse_drag_recenter_sustain_ticks
		var rig := cam.get_parent()
		if rig is NpcCameraLagRig:
			(rig as NpcCameraLagRig).follow_smoothness = profile.follow_smoothness
