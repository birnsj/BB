extends Player

## Non-controlled clone of [Player]: no input, idle facing does not track the mouse.


func _ready() -> void:
	super._ready()
	# States poll Input in physics_update, not only _input — we skip the state machine in _physics_process.
	set_process_input(false)
	if _state_label:
		_state_label.visible = false


func _register_tuning_target() -> void:
	# Do not register as &"player" — that would overwrite the real player's tuning callback.
	var defaults := CharacterTuningProfile.new()
	PlayerTuningApplier.apply(self, defaults)


func _on_state_changed(_state_key: StringName) -> void:
	pass


func _process(_delta: float) -> void:
	# Skip idle cursor-facing from [method Player._process]; physics still updates locomotion when moving.
	pass


func _physics_process(_delta: float) -> void:
	# Do not run the state machine: movement states read Input every physics frame.
	velocity = Vector2.ZERO
	# Do not call move_and_slide — it would resolve pushes from the player and slide this body. The player
	# still collides with our motionless CharacterBody2D shape via their own move_and_slide.
