extends CharacterBody2D

## Movement speed and arrival distance: [member StateMachine.MOVE_SPEED] and [member StateMachine.ARRIVE_DISTANCE].
## Treat velocity under this squared length as idle for animation.
const MOVE_ANIM_EPS2: float = 4.0

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _sprite: Sprite2D = $PlayerSprite
@onready var _attack_sprite: Sprite2D = $PlayerSprite/AttackSprite
@onready var _attack_sprite_anim: AnimationPlayer = $PlayerSprite/AttackSprite/AnimationPlayer
@onready var _state_label: Label = $StateDebugLayer/StateLabel
@onready var _state_machine: StateMachine = $StateMachine

## Last facing for idle: "up", "down", or "side" (left/right via flip_h).
var _face: String = "down"
var _face_side_is_left: bool = false


func _ready() -> void:
	_attack_sprite.hide()
	_state_machine.state_changed.connect(_on_state_changed)
	_state_machine.configure(self)
	_anim.play(&"idle_down")


func _on_state_changed(state_key: StringName) -> void:
	var readable := String(state_key).replace("_", " ")
	_state_label.text = "State: %s" % readable


func _input(event: InputEvent) -> void:
	_state_machine.handle_input(event)


func _physics_process(_delta: float) -> void:
	_state_machine.physics_update(_delta)
	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if _state_machine.current_key == &"attack":
		return
	var moving := velocity.length_squared() > MOVE_ANIM_EPS2
	if moving:
		if absf(velocity.x) > absf(velocity.y):
			_face = "side"
			_face_side_is_left = velocity.x < 0.0
		elif velocity.y < 0.0:
			_face = "up"
		else:
			_face = "down"

	var clip := ("walk_" if moving else "idle_") + _face
	if _face == "side":
		_sprite.flip_h = _face_side_is_left
	else:
		_sprite.flip_h = false

	if _anim.current_animation != clip:
		_anim.play(clip)


func play_attack_animation() -> void:
	var clip := StringName("attack_" + _face)
	if _face == "side":
		_sprite.flip_h = _face_side_is_left
		_attack_sprite.flip_h = _face_side_is_left
	else:
		_sprite.flip_h = false
		_attack_sprite.flip_h = false
	_anim.play(clip)
	_attack_sprite.show()
	# FX mirrors the same clip once per swing (no extra seek; loop_mode none on attack_* in scene).
	_attack_sprite_anim.play(clip)


func hide_attack_fx() -> void:
	# Called when root body attack finishes; FX player is not used for signals (stop won't re-enter attack state).
	_attack_sprite_anim.stop()
	_attack_sprite.frame = 0
	_attack_sprite.visible = false
	_attack_sprite.hide()


func sync_locomotion_animation() -> void:
	_update_animation()


func on_attack_state_exit() -> void:
	hide_attack_fx()
