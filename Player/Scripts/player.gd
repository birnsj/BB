class_name Player
extends CharacterBody2D

signal damaged(amount: int)

## Movement speed and arrival distance: [member StateMachine.MOVE_SPEED] and [member StateMachine.ARRIVE_DISTANCE].
## Treat velocity under this squared length as idle for animation.
const MOVE_ANIM_EPS2: float = 4.0

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _attack_hitbox: PlayerAttackHitbox = $Interactions/AttackBox
@onready var _sprite: Sprite2D = $PlayerSprite
@onready var _attack_sprite: Sprite2D = $PlayerSprite/AttackSprite
@onready var _attack_sprite_anim: AnimationPlayer = $PlayerSprite/AttackSprite/AnimationPlayer
@onready var _state_label: Label = $StateDebugLayer/StateLabel
@onready var _state_machine: StateMachine = $StateMachine

## Last facing for idle: "up", "down", or "side" (left/right via flip_h).
var _face: String = "down"
var _face_side_is_left: bool = false
## While attacking from movement, [method get_attack_aim_direction] uses this (full diagonal). Cleared when attack FX ends.
var _attack_aim_override: Vector2 = Vector2.ZERO


func _ready() -> void:
	_attack_sprite.hide()
	_state_machine.state_changed.connect(_on_state_changed)
	_state_machine.configure(self)
	_anim.play(&"idle_down")
	_attack_hitbox.sync_to_facing()


func _on_state_changed(state_key: StringName) -> void:
	var readable := String(state_key).replace("_", " ")
	_state_label.text = "State: %s" % readable


func _input(event: InputEvent) -> void:
	_state_machine.handle_input(event)


func _process(_delta: float) -> void:
	# Idle + cursor facing: refresh every rendered frame (not only physics ticks) so turning tracks the mouse faster.
	if _state_machine.current_key == &"attack":
		return
	if velocity.length_squared() > MOVE_ANIM_EPS2:
		return
	_refresh_locomotion_animation()


func _physics_process(_delta: float) -> void:
	_state_machine.physics_update(_delta)
	move_and_slide()
	# Moving: facing follows velocity on the physics step.
	if _state_machine.current_key == &"attack":
		return
	if velocity.length_squared() <= MOVE_ANIM_EPS2:
		return
	_refresh_locomotion_animation()


func _refresh_locomotion_animation() -> void:
	if _state_machine.current_key == &"attack":
		return
	var moving := velocity.length_squared() > MOVE_ANIM_EPS2
	if moving:
		_set_face_from_velocity(velocity)
	else:
		_set_face_from_cursor()

	var clip := ("walk_" if moving else "idle_") + _face
	if _face == "side":
		_sprite.flip_h = _face_side_is_left
	else:
		_sprite.flip_h = false

	if _anim.current_animation != clip:
		_anim.play(clip)

	_attack_hitbox.sync_to_facing()


func play_attack_animation(velocity_snapshot: Vector2 = Vector2.ZERO) -> void:
	if velocity_snapshot.length_squared() > MOVE_ANIM_EPS2:
		_set_face_from_velocity(velocity_snapshot)
		_attack_aim_override = velocity_snapshot.normalized()
	else:
		_set_face_from_cursor()
		_attack_aim_override = Vector2.ZERO

	var clip := StringName("attack_" + _face)
	if _face == "side":
		_sprite.flip_h = _face_side_is_left
		_attack_sprite.flip_h = _face_side_is_left
	else:
		_sprite.flip_h = false
		_attack_sprite.flip_h = false
	_attack_hitbox.sync_to_facing()
	_attack_hitbox.enable_for_attack()
	_anim.play(clip)
	_attack_sprite.show()
	# FX mirrors the same clip once per swing (no extra seek; loop_mode none on attack_* in scene).
	_attack_sprite_anim.play(clip)


func hide_attack_fx() -> void:
	# Called when root body attack finishes; FX player is not used for signals (stop won't re-enter attack state).
	_attack_hitbox.clear_swing_hits()
	_attack_hitbox.disable_for_attack()
	_attack_sprite_anim.stop()
	_attack_sprite.frame = 0
	_attack_sprite.visible = false
	_attack_sprite.hide()
	_attack_aim_override = Vector2.ZERO


func _set_face_from_velocity(v: Vector2) -> void:
	# Prefer vertical when |vy| >= |vx| so moving up/down (including diagonals) uses up/down facing.
	if absf(v.y) >= absf(v.x):
		if v.y < 0.0:
			_face = "up"
		else:
			_face = "down"
	else:
		_face = "side"
		_face_side_is_left = v.x < 0.0


func _set_face_from_cursor() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	if absf(to_mouse.y) >= absf(to_mouse.x):
		if to_mouse.y < 0.0:
			_face = "up"
		else:
			_face = "down"
	else:
		_face = "side"
		_face_side_is_left = to_mouse.x < 0.0


func sync_locomotion_animation() -> void:
	_refresh_locomotion_animation()


func get_facing() -> String:
	return _face


func is_facing_side_left() -> bool:
	return _face_side_is_left


func get_attack_aim_direction() -> Vector2:
	if _attack_aim_override.length_squared() > 0.0001:
		return _attack_aim_override
	if velocity.length_squared() > MOVE_ANIM_EPS2:
		return velocity.normalized()
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length_squared() > 1.0:
		return to_mouse.normalized()
	return _direction_from_face()


func _direction_from_face() -> Vector2:
	match _face:
		"up":
			return Vector2(0, -1)
		"down":
			return Vector2(0, 1)
		"side":
			return Vector2(-1.0 if _face_side_is_left else 1.0, 0.0)
		_:
			return Vector2(0, 1)


func on_attack_state_exit() -> void:
	hide_attack_fx()
