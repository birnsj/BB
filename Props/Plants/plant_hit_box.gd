class_name PlantHitBox
extends Area2D


func _ready() -> void:
	add_to_group(&"plant_prop_hit")


func on_player_attack_hit() -> void:
	var prop := get_parent()
	if prop and is_instance_valid(prop):
		prop.queue_free()
