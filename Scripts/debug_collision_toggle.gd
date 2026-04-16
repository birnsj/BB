extends Node

## Ctrl+Shift+C toggles a runtime outline of [CollisionShape2D] / [CollisionPolygon2D] / [TileMap] / [TileMapLayer] physics polygons under the current scene (engine debug hint is editor-only). Single F-keys are avoided (OS overlays / editor breakpoints).
const ACTION := &"debug_collision_shapes"

var _drawer: DebugCollisionDrawer


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
	_drawer = null


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(ACTION):
		return
	get_viewport().set_input_as_handled()
	if _drawer != null and is_instance_valid(_drawer):
		_drawer.queue_free()
		_drawer = null
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	_drawer = DebugCollisionDrawer.new()
	scene.call_deferred(&"add_child", _drawer)


class DebugCollisionDrawer extends Node2D:
	const _FILL := Color(0.2, 1.0, 0.35, 0.22)
	const _LINE := Color(0.15, 0.85, 0.3, 0.85)
	const _TILE_FILL := Color(0.35, 0.62, 1.0, 0.14)
	const _TILE_LINE := Color(0.28, 0.55, 0.95, 0.78)
	const _LINE_W := 1.5

	func _ready() -> void:
		z_index = 100000
		var t := Timer.new()
		t.wait_time = 1.0 / 15.0
		t.autostart = true
		t.timeout.connect(queue_redraw)
		add_child(t)
		queue_redraw()

	func _draw() -> void:
		var scene := get_parent()
		if scene:
			_visit(scene)

	func _visit(n: Node) -> void:
		if n == self:
			return
		if n is CollisionShape2D:
			_draw_collision_shape(n as CollisionShape2D)
		elif n is CollisionPolygon2D:
			_draw_collision_polygon(n as CollisionPolygon2D)
		elif n is TileMap:
			_draw_tile_map_collision(n as TileMap)
		elif n is TileMapLayer:
			_draw_tile_map_layer_collision(n as TileMapLayer)
		for c in n.get_children():
			_visit(c)

	func _draw_tile_map_collision(tm: TileMap) -> void:
		if not tm.is_visible_in_tree():
			return
		var ts := tm.tile_set
		if ts == null:
			return
		var n_phys := ts.get_physics_layers_count()
		if n_phys == 0:
			return
		var gxf := tm.global_transform
		for layer_i in range(tm.get_layers_count()):
			if not tm.is_layer_enabled(layer_i):
				continue
			for cell: Vector2i in tm.get_used_cells(layer_i):
				var td := tm.get_cell_tile_data(layer_i, cell)
				if td == null:
					continue
				_draw_tile_data_polygons(gxf, tm, cell, td, n_phys)

	func _draw_tile_map_layer_collision(tml: TileMapLayer) -> void:
		if not tml.is_visible_in_tree() or not tml.enabled or not tml.collision_enabled:
			return
		var ts := tml.tile_set
		if ts == null:
			return
		var n_phys := ts.get_physics_layers_count()
		if n_phys == 0:
			return
		var gxf := tml.global_transform
		for cell: Vector2i in tml.get_used_cells():
			var td := tml.get_cell_tile_data(cell)
			if td == null:
				continue
			_draw_tile_data_polygons(gxf, tml, cell, td, n_phys)

	func _draw_tile_data_polygons(
		gxf_tm: Transform2D, tm: Node2D, cell: Vector2i, td: TileData, n_phys: int
	) -> void:
		var local_origin: Vector2 = tm.map_to_local(cell) + Vector2(td.texture_origin)
		var cell_xf := Transform2D(0.0, local_origin)
		var compose: Transform2D = gxf_tm * cell_xf
		for phys_id in range(n_phys):
			var pc := td.get_collision_polygons_count(phys_id)
			for pi in range(pc):
				var pts := td.get_collision_polygon_points(phys_id, pi)
				if pts.size() < 2:
					continue
				if td.flip_h or td.flip_v or td.transpose:
					pts = _tile_vertices_with_flip_transpose(pts, td.flip_h, td.flip_v, td.transpose)
				_draw_poly_outline(compose, pts, true, _TILE_FILL, _TILE_LINE, _LINE_W)

	static func _tile_vertices_with_flip_transpose(
		pts: PackedVector2Array, flip_h: bool, flip_v: bool, transpose: bool
	) -> PackedVector2Array:
		var out := PackedVector2Array()
		out.resize(pts.size())
		for i in pts.size():
			var p: Vector2 = pts[i]
			var x := p.x
			var y := p.y
			if transpose:
				var t := x
				x = y
				y = t
			if flip_h:
				x = -x
			if flip_v:
				y = -y
			out[i] = Vector2(x, y)
		return out

	func _draw_collision_shape(cs: CollisionShape2D) -> void:
		if cs.disabled or cs.shape == null:
			return
		var xf := cs.global_transform
		var sh := cs.shape
		if sh is CircleShape2D:
			var c := sh as CircleShape2D
			_draw_circle_polyline(xf.origin, c.radius * _avg_scale(xf), _FILL, _LINE, _LINE_W)
		elif sh is RectangleShape2D:
			var r := sh as RectangleShape2D
			var half := r.size * 0.5
			var corners := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			]
			_draw_poly_outline(xf, corners, true)
		elif sh is CapsuleShape2D:
			var cap := sh as CapsuleShape2D
			_draw_capsule(xf, cap.radius, cap.height)
		elif sh is ConvexPolygonShape2D:
			var poly := sh as ConvexPolygonShape2D
			_draw_poly_outline(xf, poly.points, true)
		elif sh is ConcavePolygonShape2D:
			var conc := sh as ConcavePolygonShape2D
			_draw_polyline_segments(xf, conc.segments)
		elif sh is WorldBoundaryShape2D:
			var wb := sh as WorldBoundaryShape2D
			var norm := wb.normal.normalized()
			var d := wb.distance
			var p0 := norm * d
			var tang := Vector2(-norm.y, norm.x)
			var ext := 5000.0
			draw_line(to_local(xf * (p0 - tang * ext)), to_local(xf * (p0 + tang * ext)), _LINE, _LINE_W)

	func _draw_collision_polygon(cp: CollisionPolygon2D) -> void:
		if cp.polygon.size() < 2:
			return
		if cp.build_mode == CollisionPolygon2D.BUILD_SEGMENTS:
			_draw_polyline_segments(cp.global_transform, cp.polygon)
		else:
			_draw_poly_outline(cp.global_transform, cp.polygon, true)

	func _avg_scale(xf: Transform2D) -> float:
		return (xf.get_scale().x + xf.get_scale().y) * 0.5

	func _draw_poly_outline(
		xf: Transform2D,
		local_pts: PackedVector2Array,
		closed: bool,
		fill: Color = _FILL,
		line: Color = _LINE,
		line_w: float = _LINE_W,
	) -> void:
		var n := local_pts.size()
		if n < 2:
			return
		var world: PackedVector2Array = []
		world.resize(n)
		for i in n:
			world[i] = xf * local_pts[i]
		var loc: PackedVector2Array = []
		loc.resize(n)
		for i in n:
			loc[i] = to_local(world[i])
		draw_colored_polygon(loc, fill)
		for i in n - 1:
			draw_line(loc[i], loc[i + 1], line, line_w)
		if closed and n > 2:
			draw_line(loc[n - 1], loc[0], line, line_w)

	func _draw_polyline_segments(xf: Transform2D, segments: PackedVector2Array) -> void:
		var i := 0
		while i + 1 < segments.size():
			draw_line(to_local(xf * segments[i]), to_local(xf * segments[i + 1]), _LINE, _LINE_W)
			i += 2

	func _draw_circle_polyline(center: Vector2, radius: float, fill: Color, line: Color, line_w: float) -> void:
		var steps := clampi(int(radius * 0.45), 16, 48)
		var loc: PackedVector2Array = []
		loc.resize(steps)
		for i in steps:
			var a := TAU * float(i) / float(steps)
			loc[i] = to_local(center + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(loc, fill)
		for i in steps:
			draw_line(loc[i], loc[(i + 1) % steps], line, line_w)

	func _draw_capsule(xf: Transform2D, radius: float, height: float) -> void:
		## Godot capsule: [code]height[/code] is distance between the two circle centers along local Y.
		var half_h := height * 0.5
		var s := _avg_scale(xf)
		var r := radius * s
		var c_top := Vector2(0, -half_h)
		var c_bot := Vector2(0, half_h)
		_draw_circle_polyline(xf * c_top, r, _FILL, _LINE, _LINE_W)
		_draw_circle_polyline(xf * c_bot, r, _FILL, _LINE, _LINE_W)
		var y0 := -half_h + radius
		var y1 := half_h - radius
		if y1 > y0 + 0.01:
			var corners := [
				Vector2(-radius, y0),
				Vector2(radius, y0),
				Vector2(radius, y1),
				Vector2(-radius, y1),
			]
			_draw_poly_outline(xf, corners, true)
