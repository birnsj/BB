class_name PlayerAreaUtils
extends RefCounted

## [code]PropsInteract[/code] (layer 3) | [code]CharacterInteract[/code] (layer 7) — clicks here should not commit move-to-point.
const MOVE_TO_POINT_BLOCK_MASK := (1 << 2) | (1 << 6)

## Resolves the [CharacterBody2D] player from an [Area2D] parented either directly to the player or under an intermediate [Node2D] (e.g. [code]Interactions[/code]).


## [code]true[/code] if [param world_pos] overlaps a body/area on [member MOVE_TO_POINT_BLOCK_MASK] (items, character click areas, etc.).
static func world_point_blocks_move_to_point(world_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collision_mask = MOVE_TO_POINT_BLOCK_MASK
	params.collide_with_areas = true
	params.collide_with_bodies = true
	return not space_state.intersect_point(params, 16).is_empty()


static func character_from_area_parent(node: Node) -> CharacterBody2D:
	if node == null:
		return null
	var p: Node = node.get_parent()
	if p is CharacterBody2D:
		return p as CharacterBody2D
	if p:
		return p.get_parent() as CharacterBody2D
	return null
