class_name PlayerAttackHitbox
extends Area2D

const ATTACK_OFFSET_BASE: float = 12.0
const ATTACK_OFFSET_NORTH_EXTRA: float = 14.0

var _player: CharacterBody2D
var _state_machine: StateMachine
var _swing_hits: Dictionary = {}


func _ready() -> void:
	add_to_group(&"player_attack")
	_player = PlayerAreaUtils.character_from_area_parent(self)
	if _player:
		_state_machine = _player.get_node("StateMachine") as StateMachine


func sync_to_facing() -> void:
	if _player == null:
		_player = PlayerAreaUtils.character_from_area_parent(self)
	if _player == null:
		return
	var aim_player := _player as Player
	if aim_player == null:
		return

	var dir: Vector2 = aim_player.get_attack_aim_direction()
	if dir.length_squared() < 0.0001:
		dir = Vector2(0, 1)
	else:
		dir = dir.normalized()

	var northness: float = clampf(-dir.y, 0.0, 1.0)
	var dist: float = lerpf(ATTACK_OFFSET_BASE, ATTACK_OFFSET_BASE + ATTACK_OFFSET_NORTH_EXTRA, northness)
	position = dir * dist


func clear_swing_hits() -> void:
	_swing_hits.clear()


func enable_for_attack() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.disabled = false


func disable_for_attack() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.disabled = true


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = PlayerAreaUtils.character_from_area_parent(self)
	if _state_machine == null and _player:
		_state_machine = _player.get_node("StateMachine") as StateMachine
	if _state_machine == null or _state_machine.current_key != &"attack":
		return
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
	var hits: Array = space.intersect_shape(params, 32)
	for hit: Variant in hits:
		var d: Dictionary = hit
		var collider: Object = d.get("collider")
		if collider == null or not (collider is Area2D):
			continue
		var area := collider as Area2D
		if not area.has_method(&"on_player_attack_hit"):
			continue
		var rid: int = area.get_instance_id()
		if _swing_hits.has(rid):
			continue
		_swing_hits[rid] = true
		area.call(&"on_player_attack_hit")
