class_name PlayerInteractionHost
extends Node

## Places [member HurtBox] along [method Player.get_hurtbox_direction] with extra reach toward north (screen-up), including diagonals.

const HURTBOX_BASE_DISTANCE: float = 12.0
## Extra distance when aiming north; scales with how "northward" the direction is (1 = pure up, 0 = east/west/south).
const HURTBOX_NORTH_EXTRA: float = 14.0

var _hurtbox: Area2D


func _ready() -> void:
	# [member HurtBox] is a sibling under the Interactions branch (this node's child).
	_hurtbox = get_node_or_null("HurtBox") as Area2D


func sync_hurtbox_to_facing() -> void:
	if _hurtbox == null:
		_hurtbox = get_node_or_null("HurtBox") as Area2D
	if _hurtbox == null:
		return

	# Player is the CharacterBody2D above the Interactions branch.
	var player := get_parent()
	if player == null or not player.has_method(&"get_hurtbox_direction"):
		return

	var dir: Vector2 = player.call(&"get_hurtbox_direction")
	if dir.length_squared() < 0.0001:
		dir = Vector2(0, 1)
	else:
		dir = dir.normalized()

	# Godot 2D: negative Y is north. Blend base distance with extra reach for north and north-diagonals.
	var northness: float = clampf(-dir.y, 0.0, 1.0)
	var dist: float = lerpf(HURTBOX_BASE_DISTANCE, HURTBOX_BASE_DISTANCE + HURTBOX_NORTH_EXTRA, northness)
	_hurtbox.position = dir * dist
