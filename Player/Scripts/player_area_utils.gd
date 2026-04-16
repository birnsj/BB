class_name PlayerAreaUtils
extends RefCounted

## Resolves the [CharacterBody2D] player from an [Area2D] parented either directly to the player or under an intermediate [Node2D] (e.g. [code]Interactions[/code]).


static func character_from_area_parent(node: Node) -> CharacterBody2D:
	if node == null:
		return null
	var p: Node = node.get_parent()
	if p is CharacterBody2D:
		return p as CharacterBody2D
	if p:
		return p.get_parent() as CharacterBody2D
	return null
