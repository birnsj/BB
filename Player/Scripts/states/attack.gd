class_name AttackState
extends State

var _sword_sfx: AudioStreamPlayer


func enter(_payload: Variant = null) -> void:
	player.velocity = Vector2.ZERO
	if _sword_sfx == null:
		_sword_sfx = player.get_node_or_null("SwordSwoosh") as AudioStreamPlayer
	# One swing = one body attack clip; FX follows in play_attack_animation. Finished comes from root player only.
	var anim_player: AnimationPlayer = player.get_node("AnimationPlayer") as AnimationPlayer
	var on_finished := Callable(self, "_on_attack_anim_finished")
	if not anim_player.is_connected("animation_finished", on_finished):
		anim_player.connect("animation_finished", on_finished)
	_play_swing_sound()
	player.call("play_attack_animation")


func exit() -> void:
	var anim_player: AnimationPlayer = player.get_node("AnimationPlayer") as AnimationPlayer
	var on_finished := Callable(self, "_on_attack_anim_finished")
	if anim_player.is_connected("animation_finished", on_finished):
		anim_player.disconnect("animation_finished", on_finished)
	player.call("on_attack_state_exit")


func physics_update(_delta: float) -> void:
	player.velocity = Vector2.ZERO


func _on_attack_anim_finished(anim_name: StringName) -> void:
	if state_machine.current != self:
		return
	# Switching away from idle/walk can emit finished for the previous clip first.
	if not String(anim_name).begins_with("attack_"):
		return
	# End of body attack clip: hide FX (started once per play_attack_animation) then repeat or leave.
	player.call("hide_attack_fx")
	if State.is_attack_input_held():
		_play_swing_sound()
		player.call("play_attack_animation")
	else:
		_transition_after_attack()


func _transition_after_attack() -> void:
	if Input.get_vector("left", "right", "up", "down").length_squared() > 0.0:
		state_machine.transition_to(&"keyboard_move")
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state_machine.transition_to(&"mouse_drag")
	else:
		state_machine.transition_to(&"idle")
	# Root AnimationPlayer still held the last body attack frame; reapply idle/walk now that current_key is updated.
	player.call("sync_locomotion_animation")


func _play_swing_sound() -> void:
	if _sword_sfx:
		_sword_sfx.play()
