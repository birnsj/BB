extends Node2D


func _ready() -> void:
	var hitbox := $HitBox as Area2D
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player_attack"):
		queue_free()
