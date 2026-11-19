extends Control

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.025, 0.045, 0.09, 0.82), true)
	draw_rect(rect, Color(0.35, 0.62, 0.95, 0.9), false, 2.0)
	var mid_x := size.x * 0.5
	draw_line(Vector2(mid_x, 5), Vector2(mid_x, size.y - 5), Color(0.25, 0.34, 0.48, 0.7), 1.0)
	draw_line(Vector2(5, size.y * 0.5), Vector2(size.x - 5, size.y * 0.5), Color(0.25, 0.34, 0.48, 0.7), 1.0)
	_draw_group("blue_team", Color(0.2, 0.68, 1.0))
	_draw_group("enemies", Color(1.0, 0.25, 0.2))

func _draw_group(group_name: String, color: Color) -> void:
	for unit in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(unit):
			continue
		var world_pos: Vector3 = unit.global_position
		var px := clampf((world_pos.x + 17.0) / 34.0, 0.0, 1.0) * size.x
		var py := clampf((world_pos.z + 17.0) / 34.0, 0.0, 1.0) * size.y
		var radius := 4.5 if unit.is_in_group("player") else 3.2
		draw_circle(Vector2(px, py), radius, color)
