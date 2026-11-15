extends "res://scripts/entity.gd"
# Structure: occupies grid cells, produces units, supplies/consumes power, may defend itself.

var origin = Vector2()        # top-left cell
var size_cells = Vector2(1, 1)
var queue = []                # unit kinds waiting to be built
var progress = 0.0
var rise = 0.0                # construction "pop-up" animation 0..1
var anim = 0.0
var aim = PI / 2          # gun tower turret angle
var fx_timer = 0.0


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
	return position + Vector2(0, size_cells.y * Data.CELL / 2.0 + 32)


func exit_point():
	return position + Vector2(rand_range(-20, 20), size_cells.y * Data.CELL / 2.0 + 34)


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
	_emit_effects(delta)
	if def["shape"] in ["tesla_coil", "refinery", "helipad", "uplink", "hq", "gun_tower"] or flash > 0 or queue.size() > 0:
		update()


func _emit_effects(delta):
	fx_timer -= delta
	if fx_timer > 0:
		return
	fx_timer = 0.22
	var s = size_cells * Data.CELL
	if def["shape"] == "power" and game.has_power(team):
		game.fx_steam(position + Vector2(-27 if randf() < 0.5 else 27, -62))
	var frac = hp / max_hp
	if frac < 0.6:
		# Damage shows as smoke, then fire.
		var spot = position + Vector2(s.x * (fmod(anim * 0.37, 1.0) - 0.5) * 0.5, -s.y * 0.2)
		game.fx_smoke_column(spot, frac < 0.3)


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


func muzzle_offset(other):
	var dir = (other.global_position - global_position).normalized()
	match def["shape"]:
		"tesla_coil":
			return Vector2(0, -49)
		"gun_tower":
			return Vector2(0, -19) + dir * 26
	return dir * radius


# ---------------------------------------------------------------- drawing

func art_id():
	return kind + "/" + faction


func _draw():
	var s = size_cells * Data.CELL
	var id = art_id()
	var mod = Color(1.6, 1.6, 1.6) if flash > 0 else Color(1, 1, 1)
	mod.a = 0.35 + 0.65 * rise
	if Art.has(id):
		Art.draw_part(self, id, 0, Vector2(0, (1.0 - rise) * 14), mod)
	else:
		draw_rect(Rect2(-s / 2 + Vector2(6, 6), s - Vector2(12, 12)), team_dark())
	if rise >= 1.0:
		_draw_live(s)
	if selected:
		_draw_brackets(Rect2(-s / 2 + Vector2(2, 2), s - Vector2(4, 4)))
	if queue.size() > 0 and team == game.player_team:
		var frac = progress / Data.get_def(queue[0])["build_time"]
		var r = Rect2(Vector2(-s.x / 2 + 10, s.y / 2 - 12), Vector2(s.x - 20, 4))
		draw_rect(r.grow(1), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(r.position, Vector2(r.size.x * frac, 4)), Color(0.35, 0.8, 1.0))
	if not game.has_power(team) and def.get("power", 0) < 0 and int(anim * 2) % 2 == 0:
		var c = Vector2(s.x / 2 - 16, -s.y / 2 + 4)
		draw_colored_polygon(PoolVector2Array([c + Vector2(0, -10), c + Vector2(9, 6), c + Vector2(-9, 6)]), Color(1, 0.82, 0.1))
		draw_line(c + Vector2(0, -4), c + Vector2(0, 1), Color(0.1, 0.1, 0.1), 2.0)
		draw_circle(c + Vector2(0, 3.5), 1.2, Color(0.1, 0.1, 0.1))
	draw_health(s.x - 24, -s.y / 2 - 22)


func _draw_brackets(r):
	var col = Color(0.45, 1.0, 0.55, 0.95)
	var l = 14.0
	for corner in [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)], [r.end, Vector2(-1, -1)], [Vector2(r.position.x, r.end.y), Vector2(1, -1)]]:
		var c = corner[0]
		var d = corner[1]
		draw_line(c, c + Vector2(l * d.x, 0), col, 2.0)
		draw_line(c, c + Vector2(0, l * d.y), col, 2.0)


func _draw_live(_s):
	# Moving and glowing parts drawn on top of the pre-rendered building.
	var glow = Color(0.55, 0.85, 1.0)
	match def["shape"]:
		"gun_tower":
			if is_instance_valid(target):
				aim = (target.global_position - global_position).angle()
			Art.draw_part(self, "gun_tower/turret/" + faction, aim, Vector2(0, -19))
		"uplink":
			Art.draw_shadow(self, "orbital_uplink/dish/" + faction, anim * 0.25, Vector2(16, -21), Vector2(26, 30), 0.25)
			Art.draw_part(self, "orbital_uplink/dish/" + faction, anim * 0.25, Vector2(16, -21))
			var charge = game.orbital_charge[team] / def["charge_time"]
			draw_arc(Vector2(16, -21), 6, -PI / 2, -PI / 2 + TAU * charge, 20, glow, 3.0, true)
		"tesla_coil":
			if reload_left <= 0 and game.has_power(team):
				var top = Vector2(0, -49)
				draw_circle(top, 13 + sin(anim * 11.0) * 2.0, Color(0.5, 0.8, 1.0, 0.28))
				if int(anim * 9) % 3 == 0:
					var a = anim * 7.0
					var p1 = top + Vector2.RIGHT.rotated(a) * 9
					draw_polyline(PoolVector2Array([p1, p1 + Vector2.RIGHT.rotated(a + 0.6) * 8, p1 + Vector2.RIGHT.rotated(a - 0.4) * 15]), Color(0.8, 0.95, 1.0), 1.5, true)
		"refinery":
			var tip = Vector2(76, -99)
			var f = 1.0 + sin(anim * 13.0) * 0.2
			draw_circle(tip + Vector2(0, -4), 7 * f, Color(1.0, 0.55, 0.15, 0.45))
			draw_circle(tip + Vector2(0, -3), 3.5 * f, Color(1.0, 0.9, 0.5, 0.9))
		"helipad":
			var on = int(anim * 2) % 2 == 0
			for i in range(8):
				var a2 = i * TAU / 8
				draw_circle(Vector2(-6, 6) + Vector2(cos(a2), sin(a2)) * 46, 2.0, Color(1, 0.3, 0.2) if on else Color(0.4, 0.1, 0.08))
		"hq":
			if int(anim * 1.5) % 2 == 0:
				draw_circle(Vector2(-30, -22 - 46.5), 3.0, Color(1, 0.25, 0.2, 0.8))
