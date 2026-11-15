extends "res://scripts/entity.gd"
# Structure: occupies grid cells, produces units, supplies/consumes power, may defend itself.

var origin = Vector2()        # top-left cell
var size_cells = Vector2(1, 1)
var queue = []                # unit kinds waiting to be built
var progress = 0.0
var rise = 0.0                # construction "pop-up" animation 0..1
var anim = 0.0


func setup_building(g, k, t, cell):
	setup(g, k, t)
	is_building = true
	origin = cell
	size_cells = def["size"]
	radius = size_cells.x * Data.CELL * 0.45
	position = cell * Data.CELL + size_cells * Data.CELL / 2.0
	add_to_group("buildings")


func get_rect():
	var s = size_cells * Data.CELL
	return Rect2(position - s / 2.0 + Vector2(4, 4), s - Vector2(8, 8))


func cells():
	var out = []
	for y in range(int(size_cells.y)):
		for x in range(int(size_cells.x)):
			out.append(origin + Vector2(x, y))
	return out


func dock_point():
	return position + Vector2(0, size_cells.y * Data.CELL / 2.0 + 18)


func exit_point():
	return position + Vector2(rand_range(-20, 20), size_cells.y * Data.CELL / 2.0 + 22)


func enqueue(unit_kind):
	queue.append(unit_kind)


func _process(delta):
	if dead:
		return
	_tick_common(delta)
	anim += delta
	if rise < 1.0:
		rise = min(1.0, rise + delta * 1.5)
		update()
		return
	if queue.size() > 0:
		var ud = Data.get_def(queue[0])
		progress += delta * game.power_factor(team) * game.build_speed(team)
		if progress >= ud["build_time"]:
			progress = 0.0
			var k = queue.pop_front()
			game.spawn_unit(k, team, exit_point(), self)
	if def.get("defense", false):
		_defend(delta)
	if def["shape"] in ["power", "tesla_coil", "refinery", "helipad"] or flash > 0 or queue.size() > 0:
		update()


func _defend(delta):
	if not game.has_power(team):
		target = null
		return
	if target != null and (not can_attack(target) or not in_range(target)):
		target = null
	scan_timer -= delta
	if target == null and scan_timer <= 0:
		scan_timer = 0.3
		var t = find_target(def["range"])
		if t and in_range(t):
			target = t
	if target and reload_left <= 0:
		fire_at(target)
		update()


func die():
	if dead:
		return
	game.fx_explosion(position, 1.8)
	.die()


# ---------------------------------------------------------------- drawing (placeholder comic style)

func _draw():
	var s = size_cells * Data.CELL
	var scale_y = 0.3 + 0.7 * rise
	draw_set_transform(Vector2(0, s.y / 2 * (1 - scale_y)), 0, Vector2(1, scale_y))
	var r = Rect2(-s / 2 + Vector2(6, 6), s - Vector2(12, 12))
	# Shadow and concrete slab.
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.25))
	draw_outlined_poly(rect_points(Vector2.ZERO, r.size), Color("#b8ad9a"), 4.0)
	var c = team_color()
	if flash > 0:
		c = Color(1, 1, 1)
	var d = team_dark()
	match def["shape"]:
		"hq":
			draw_outlined_poly(rect_points(Vector2(0, 10), Vector2(r.size.x - 30, r.size.y * 0.45)), d)
			draw_outlined_circle(Vector2(0, -12), 40, c, 4.0)
			draw_arc(Vector2(-8, -20), 22, PI, PI * 1.5, 8, Color(1, 1, 1, 0.5), 4.0)
			draw_line(Vector2(0, -52), Vector2(0, -82), INK, 3.0)
			draw_outlined_poly([Vector2(0, -82), Vector2(24, -75), Vector2(0, -68)], c, 2.0)
		"power":
			for x in [-22, 22]:
				draw_outlined_poly(rect_points(Vector2(x, 0), Vector2(26, 60)), d)
				var pulse = 0.5 + 0.5 * sin(anim * 4.0 + x)
				draw_rect(Rect2(Vector2(x - 7, -20), Vector2(14, 40)), Color(1, 0.85, 0.3, 0.4 + pulse * 0.5))
			draw_outlined_circle(Vector2(0, -30), 8, c, 2.5)
		"refinery":
			for x in [-50, -10]:
				draw_outlined_circle(Vector2(x, -6), 22, d, 3.5)
				draw_circle(Vector2(x, -6), 12, Color("#c0392b"))
			draw_outlined_poly(rect_points(Vector2(45, -2), Vector2(56, 70)), c)
			draw_rect(Rect2(Vector2(-24, 34), Vector2(48, 12)), Color("#5c5c5c"))
		"barracks":
			draw_outlined_poly([Vector2(-45, 30), Vector2(-45, -15), Vector2(0, -42), Vector2(45, -15), Vector2(45, 30)], c)
			draw_outlined_poly(rect_points(Vector2(0, 16), Vector2(22, 28)), INK, 2.0)
		"factory":
			draw_outlined_poly(rect_points(Vector2(0, -6), Vector2(r.size.x - 20, r.size.y - 40)), c)
			draw_outlined_poly(rect_points(Vector2(0, 30), Vector2(80, 50)), Color("#4a4a4a"))
			for k in range(4):
				draw_line(Vector2(-38, 12 + k * 11), Vector2(38, 12 + k * 11), INK, 2.0)
			draw_outlined_circle(Vector2(-55, -50), 10, d)
			if queue.size() > 0:
				draw_circle(Vector2(-55, -50), 5, Color(1, 0.6, 0.2))
		"helipad":
			draw_outlined_circle(Vector2.ZERO, 46, Color("#5a5a5a"), 4.0)
			draw_line(Vector2(-14, -18), Vector2(-14, 18), Color(1, 1, 1), 6.0)
			draw_line(Vector2(14, -18), Vector2(14, 18), Color(1, 1, 1), 6.0)
			draw_line(Vector2(-14, 0), Vector2(14, 0), Color(1, 1, 1), 6.0)
			var blink = Color(1, 0.3, 0.2) if int(anim * 2) % 2 == 0 else c
			for p in [Vector2(-44, -44), Vector2(44, -44), Vector2(-44, 44), Vector2(44, 44)]:
				draw_circle(p * 0.75, 4, blink)
		"gun_tower":
			draw_outlined_circle(Vector2.ZERO, 20, d)
			var dir = Vector2.RIGHT.rotated((target.global_position - global_position).angle()) if is_instance_valid(target) else Vector2.DOWN
			draw_line(Vector2.ZERO, dir * 28, INK, 7.0)
			draw_outlined_circle(Vector2.ZERO, 11, c, 3.0)
		"tesla_coil":
			draw_outlined_poly([Vector2(-18, 24), Vector2(18, 24), Vector2(8, -20), Vector2(-8, -20)], d)
			for k in range(4):
				draw_outlined_circle(Vector2(0, -8 - k * 9), 12 - k * 1.5, c, 2.0)
			var charged = reload_left <= 0 and game.has_power(team)
			draw_outlined_circle(Vector2(0, -48), 9, Color(0.55, 0.9, 1.0) if charged else Color(0.3, 0.35, 0.4), 2.5)
			if charged and int(anim * 8) % 3 == 0:
				var a = Vector2(0, -48)
				draw_polyline(PoolVector2Array([a, a + Vector2(8, -6), a + Vector2(4, -14), a + Vector2(12, -20)]), Color(0.7, 0.95, 1), 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if selected:
		draw_rect(Rect2(-s / 2 + Vector2(2, 2), s - Vector2(4, 4)), Color(0.4, 1, 0.4), false, 2.0)
	if queue.size() > 0 and team == game.player_team:
		var frac = progress / Data.get_def(queue[0])["build_time"]
		draw_rect(Rect2(Vector2(-s.x / 2 + 8, s.y / 2 - 14), Vector2(s.x - 16, 6)), INK)
		draw_rect(Rect2(Vector2(-s.x / 2 + 9, s.y / 2 - 13), Vector2((s.x - 18) * frac, 4)), Color(0.3, 0.8, 1.0))
	if not game.has_power(team) and def.get("power", 0) < 0:
		if int(anim * 2) % 2 == 0:
			draw_outlined_circle(Vector2(s.x / 2 - 18, -s.y / 2 + 18), 9, Color(1, 0.85, 0.1), 2.0)
	draw_health(s.x - 20, -s.y / 2 - 4)
