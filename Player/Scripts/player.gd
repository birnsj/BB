extends CharacterBody2D

## Movement speed and arrival distance: [member StateMachine.MOVE_SPEED] and [member StateMachine.ARRIVE_DISTANCE].
## Treat velocity under this squared length as idle for animation.
const MOVE_ANIM_EPS2: float = 4.0

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _sprite: Sprite2D = $PlayerSprite
@onready var _state_label: Label = $StateDebugLayer/StateLabel
@onready var _state_machine: StateMachine = $StateMachine

## Last facing for idle: "up", "down", or "side" (left/right via flip_h).
var _face: String = "down"
var _face_side_is_left: bool = false


func _ready() -> void:
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
	else:
		_sprite.flip_h = false
	# Do not call stop() here: it can emit animation_finished for the idle/walk clip
	# synchronously and confuse AttackState before the attack animation runs.
	_anim.play(clip)
