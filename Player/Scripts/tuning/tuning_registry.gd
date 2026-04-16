## Central registry for in-game tuning targets. V1: register [code]&"player"[/code] from [method Player._ready].
## Later: enemies/NPCs call [method register] with their own [Callable] that applies a [CharacterTuningProfile].
class_name TuningRegistry
extends RefCounted

static var _apply_by_id: Dictionary = {}


static func register(id: StringName, apply_profile: Callable) -> void:
	_apply_by_id[id] = apply_profile


static func unregister(id: StringName) -> void:
	_apply_by_id.erase(id)


static func apply_for_id(id: StringName, profile: CharacterTuningProfile) -> void:
	var cb: Variant = _apply_by_id.get(id)
	if cb == null or not cb is Callable:
		push_warning("TuningRegistry: no apply callback for '%s'." % String(id))
		return
	(cb as Callable).call(profile)


static func has_id(id: StringName) -> bool:
	return _apply_by_id.has(id)


static func registered_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: Variant in _apply_by_id.keys():
		out.append(k as StringName)
	return out
