class_name NpcHurtBox
extends Area2D

var _player: CharacterBody2D
var _enemy_attack_overlapping: bool = false


func _ready() -> void:
	_player = PlayerAreaUtils.character_from_area_parent(self)


func _physics_process(_delta: float) -> void:
	_resolve_enemy_hits()


func _resolve_enemy_hits() -> void:
	if _player == null:
		_player = PlayerAreaUtils.character_from_area_parent(self)
	if _player == null:
		return

	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.disabled or cs.shape == null:
		return

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = cs.shape
	params.transform = cs.global_transform
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = collision_mask
	var space := get_world_2d().direct_space_state
	var hits: Array = space.intersect_shape(params, 16)
	var touching := not hits.is_empty()
	if touching and not _enemy_attack_overlapping:
		_player.emit_signal(&"damaged", 1)
	_enemy_attack_overlapping = touching
