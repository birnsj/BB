extends Node2D


func _ready() -> void:
	## Player resolves hits via [method Player._resolve_prop_attack_hits] + overlapping areas (reliable).
	($HitBox as Area2D).add_to_group(&"plant_prop_hit")
