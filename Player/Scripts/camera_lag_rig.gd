class_name CameraLagRig
extends Node2D

## Must run after the player’s [method CharacterBody2D.move_and_slide] so we chase the new position.
const PHYSICS_PRIORITY_AFTER_PLAYER: int = 64

## Exponential follow rate toward the player. Higher = snappier (less lag); lower = more lag.
## Typical range ~1.0 (heavy) – 6.0 (light).
@export var follow_smoothness: float = 3.0

## Who to follow. From a sibling rig under the same level root, use [code]../Player[/code].
@export var follow_target: NodePath = NodePath()

## Filled from [member follow_target]; used by [member PlayerCamera] and follow logic.
var player_root: CharacterBody2D


func _ready() -> void:
	process_physics_priority = PHYSICS_PRIORITY_AFTER_PLAYER
	_resolve_follow_target()
	if player_root == null:
		push_error(
			"CameraLagRig: set follow_target (e.g. NodePath('../Player')) or add group 'game_follow_target' on the player."
		)
		return
	global_position = player_root.global_position


func _resolve_follow_target() -> void:
	if not follow_target.is_empty():
		player_root = get_node_or_null(follow_target) as CharacterBody2D
		if player_root != null:
			return
	var g := get_tree().get_first_node_in_group(&"game_follow_target") as CharacterBody2D
	if g != null:
		player_root = g


func _physics_process(delta: float) -> void:
	if player_root == null or not is_instance_valid(player_root):
		return
	var target := player_root.global_position
	var t := 1.0 - exp(-follow_smoothness * delta)
	global_position = global_position.lerp(target, t)
