extends CharacterBody2D

signal damaged(amount: int)

## Movement speed and arrival distance: [member StateMachine.MOVE_SPEED] and [member StateMachine.ARRIVE_DISTANCE].
## Treat velocity under this squared length as idle for animation.
const MOVE_ANIM_EPS2: float = 4.0
## Bitmask for project physics layer "PlayerHurt" (layer 2): player weapon / attack shape.
const PLAYER_ATTACK_PHYSICS_LAYER: int = 2
## Bitmask for [code]PropsInteract[/code] (layer 3): destructible prop hit targets (plants, etc.).
const PROPS_INTERACT_PHYSICS_LAYER: int = 4
## Bitmask for project physics layer "Enemy" (layer 9): enemy attack [member HitBox] shapes.
const ENEMY_ATTACK_PHYSICS_LAYER: int = 256

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _interaction_host: PlayerInteractionHost = $Interactions
## Sword / prop overlap — transform stays as placed in the scene (not driven by facing).
var _attack_hitbox: Area2D
@onready var _sprite: Sprite2D = $PlayerSprite
@onready var _attack_sprite: Sprite2D = $PlayerSprite/AttackSprite
@onready var _attack_sprite_anim: AnimationPlayer = $PlayerSprite/AttackSprite/AnimationPlayer
@onready var _state_label: Label = $StateDebugLayer/StateLabel
@onready var _state_machine: StateMachine = $StateMachine

## Last facing for idle: "up", "down", or "side" (left/right via flip_h).
var _face: String = "down"
var _face_side_is_left: bool = false
## While attacking from movement, hurtbox uses this direction (full diagonal). Cleared when attack FX ends.
var _hurtbox_dir_override: Vector2 = Vector2.ZERO
## Dedupe [method Area2D.get_overlapping_areas] hits within one swing (cleared in [method hide_attack_fx]).
var _prop_hits_this_swing: Dictionary = {}
## True while any enemy attack shape overlaps the hurtbox (for edge-triggered [signal damaged]).
var _enemy_attack_overlapping_hurtbox: bool = false


func _ready() -> void:
	_attack_hitbox = _find_attack_hitbox()
	if _attack_hitbox:
		_attack_hitbox.add_to_group(&"player_attack")
		_attack_hitbox.collision_layer = 0
		_attack_hitbox.collision_mask = 0
	_attack_sprite.hide()
	_state_machine.state_changed.connect(_on_state_changed)
	_state_machine.configure(self)
	_anim.play(&"idle_down")
	_interaction_host.sync_hurtbox_to_facing()


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
	_resolve_prop_attack_hits()
	_resolve_hurtbox_enemy_hits()
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

	_interaction_host.sync_hurtbox_to_facing()


func play_attack_animation(velocity_snapshot: Vector2 = Vector2.ZERO) -> void:
	if velocity_snapshot.length_squared() > MOVE_ANIM_EPS2:
		_set_face_from_velocity(velocity_snapshot)
		_hurtbox_dir_override = velocity_snapshot.normalized()
	else:
		_set_face_from_cursor()
		_hurtbox_dir_override = Vector2.ZERO

	var clip := StringName("attack_" + _face)
	if _face == "side":
		_sprite.flip_h = _face_side_is_left
		_attack_sprite.flip_h = _face_side_is_left
	else:
		_sprite.flip_h = false
		_attack_sprite.flip_h = false
	_interaction_host.sync_hurtbox_to_facing()
	if _attack_hitbox:
		_attack_hitbox.collision_layer = PLAYER_ATTACK_PHYSICS_LAYER
		_attack_hitbox.collision_mask = PROPS_INTERACT_PHYSICS_LAYER
	_anim.play(clip)
	_attack_sprite.show()
	# FX mirrors the same clip once per swing (no extra seek; loop_mode none on attack_* in scene).
	_attack_sprite_anim.play(clip)


func hide_attack_fx() -> void:
	# Called when root body attack finishes; FX player is not used for signals (stop won't re-enter attack state).
	_prop_hits_this_swing.clear()
	_hurtbox_dir_override = Vector2.ZERO
	if _attack_hitbox:
		_attack_hitbox.collision_layer = 0
		_attack_hitbox.collision_mask = 0
	_attack_sprite_anim.stop()
	_attack_sprite.frame = 0
	_attack_sprite.visible = false
	_attack_sprite.hide()


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


func _find_attack_hitbox() -> Area2D:
	var n := get_node_or_null("AttackHitBox") as Area2D
	if n:
		return n
	n = get_node_or_null("HitBox") as Area2D
	if n:
		return n
	return find_child("HitBox", true, false) as Area2D


func _resolve_prop_attack_hits() -> void:
	if _state_machine.current_key != &"attack":
		return
	if _attack_hitbox == null:
		return
	var cs := _attack_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.disabled or cs.shape == null:
		return
	# Shape query avoids one-frame lag when toggling Area2D layers (get_overlapping_areas can miss).
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = cs.shape
	params.transform = cs.global_transform
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = PROPS_INTERACT_PHYSICS_LAYER
	var space := get_world_2d().direct_space_state
	var hits: Array = space.intersect_shape(params, 32)
	for hit: Variant in hits:
		var d: Dictionary = hit
		var collider: Object = d.get("collider")
		if collider == null or not (collider is Area2D):
			continue
		var area := collider as Area2D
		if not area.is_in_group(&"plant_prop_hit"):
			continue
		var rid: int = area.get_instance_id()
		if _prop_hits_this_swing.has(rid):
			continue
		_prop_hits_this_swing[rid] = true
		var prop := area.get_parent()
		if prop and is_instance_valid(prop):
			prop.queue_free()


func _resolve_hurtbox_enemy_hits() -> void:
	## Uses the same world [CollisionShape2D] as [member HurtBox] so hits match what you see in the debugger.
	var hb := get_node_or_null("Interactions/HurtBox") as Area2D
	if hb == null:
		return
	var cs := hb.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.disabled or cs.shape == null:
		return
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = cs.shape
	params.transform = cs.global_transform
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = ENEMY_ATTACK_PHYSICS_LAYER
	var space := get_world_2d().direct_space_state
	var hits: Array = space.intersect_shape(params, 16)
	var touching := not hits.is_empty()
	if touching and not _enemy_attack_overlapping_hurtbox:
		damaged.emit(1)
	_enemy_attack_overlapping_hurtbox = touching


func sync_locomotion_animation() -> void:
	_refresh_locomotion_animation()


func get_facing() -> String:
	return _face


func is_facing_side_left() -> bool:
	return _face_side_is_left


func get_hurtbox_direction() -> Vector2:
	if _hurtbox_dir_override.length_squared() > 0.0001:
		return _hurtbox_dir_override
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
