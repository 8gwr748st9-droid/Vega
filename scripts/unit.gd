extends "res://scripts/entity.gd"
# Mobile unit: movement, orders, auto-targeting and placeholder "comic" drawing.

var state = "idle"         # idle | move | attack | attack_move
var dest = Vector2()
var guard_pos = Vector2()
var facing = 0.0
var turret_angle = 0.0
var anim = 0.0
var moving = false
var track_acc = 0.0
var stuck = 0.0
var last_d = INF
var cargo = 0.0            # used by harvesters for drawing
var panic_time = 0.0       # fleeing in terror (e.g. from the orbital vaporiser)
var panic_from = Vector2()


func _ready():
	guard_pos = position
	dest = position
	facing = rand_range(-PI, PI)
	turret_angle = facing
	if is_air:
		add_to_group("air_units")
	else:
		add_to_group("ground_units")
	add_to_group("units")


# ---------------------------------------------------------------- orders

func order_move(p):
	state = "move"
	dest = game.map.clamp_to_map(p)
	target = null
	_reset_stuck()


func order_attack(e):
	if not can_attack(e):
		order_move(e.global_position)
		return
	state = "attack"
	target = e


func order_attack_move(p):
	state = "attack_move"
	dest = game.map.clamp_to_map(p)
	target = null
	_reset_stuck()


func order_stop():
	state = "idle"
	target = null
	guard_pos = position


func _reset_stuck():
	stuck = 0.0
	last_d = INF


# ---------------------------------------------------------------- update

func _process(delta):
	if dead:
		return
	_tick_common(delta)
	anim += delta
	moving = false
	if panic_time > 0:
		panic_time -= delta
		target = null
		_step_to(position + (position - panic_from).normalized() * 80, delta)
		if panic_time <= 0:
			order_stop()
	else:
		_update_state(delta)
	if not is_air:
		_separate(delta)
	update()


func _update_state(delta):
	match state:
		"idle":
			_do_idle(delta)
		"move":
			if _step_to(dest, delta, true):
				order_stop()
		"attack":
			if not can_attack(target):
				order_stop()
			else:
				_engage(target, delta)
		"attack_move":
			_do_attack_move(delta)


func _do_idle(delta):
	if def.get("damage", 0) <= 0:
		return
	if target != null and not can_attack(target):
		target = null
	scan_timer -= delta
	if target == null and scan_timer <= 0:
		scan_timer = 0.4
		target = find_target(def["sight"])
	if target:
		if in_range(target):
			_aim_and_fire(target)
		elif target.global_position.distance_to(guard_pos) < def["sight"] * 1.4:
			_step_to(target.global_position, delta)
		else:
			target = null
	elif position.distance_to(guard_pos) > 14:
		_step_to(guard_pos, delta)


func _do_attack_move(delta):
	if target != null and not can_attack(target):
		target = null
	scan_timer -= delta
	if target == null and scan_timer <= 0 and def.get("damage", 0) > 0:
		scan_timer = 0.4
		target = find_target(def["sight"])
	if target:
		_engage(target, delta)
	elif _step_to(dest, delta, true):
		order_stop()


func _engage(t, delta):
	if in_range(t):
		_aim_and_fire(t)
	else:
		_step_to(t.global_position, delta)


func _aim_and_fire(t):
	turret_angle = (t.global_position - global_position).angle()
	if reload_left <= 0:
		fire_at(t)


func panic(from_pos, duration):
	panic_time = duration
	panic_from = from_pos
	if randf() < 0.3:
		game.fx_text(position + Vector2(0, -26), ["AAAH!", "RUN!", "RETREAT!"][randi() % 3], Color(1, 1, 1))


func speed_mult():
	if is_air:
		return 1.0
	if game.map.is_sand_at(position):
		return Data.FACTIONS[faction]["sand_speed"]
	return 1.0


func _step_to(p, delta, check_stuck = false):
	var to = p - position
	var d = to.length()
	if d < 6:
		return true
	if check_stuck:
		if d > last_d - 0.2:
			stuck += delta
		else:
			stuck = max(0.0, stuck - delta)
		last_d = d
		if d < 60 and stuck > 0.5:
			return true
	var spd = def["speed"] * speed_mult()
	var step = to / d * min(d, spd * delta)
	position = game.map.clamp_to_map(position + step)
	facing = lerp_angle(facing, to.angle(), min(1.0, delta * 6.0))
	if target == null:
		turret_angle = lerp_angle(turret_angle, facing, min(1.0, delta * 4.0))
	moving = true
	_leave_tracks(step.length())
	return false


func _leave_tracks(dist):
	if is_air or Data.FACTIONS[faction].get("no_tracks", false):
		return
	track_acc += dist
	if track_acc >= 14.0:
		track_acc = 0.0
		if game.map.is_sand_at(position):
			game.tracks.add_mark(position, facing, def["shape"].begins_with("infantry"))


func _separate(delta):
	var push = Vector2.ZERO
	for e in get_tree().get_nodes_in_group("ground_units"):
		if e == self or e.dead:
			continue
		var off = position - e.position
		var min_d = radius + e.radius
		var dsq = off.length_squared()
		if dsq >= min_d * min_d:
			continue
		if dsq < 0.01:
			push += Vector2(randf() - 0.5, randf() - 0.5)
		else:
			var dd = sqrt(dsq)
			push += off / dd * (min_d - dd) * 0.5
	position += push * min(1.0, delta * 12.0)
	for b in get_tree().get_nodes_in_group("buildings"):
		var r = b.get_rect().grow(radius)
		if r.has_point(position):
			var dl = position.x - r.position.x
			var dr = r.end.x - position.x
			var dt = position.y - r.position.y
			var db = r.end.y - position.y
			var m = min(min(dl, dr), min(dt, db))
			if m == dl:
				position.x = r.position.x
			elif m == dr:
				position.x = r.end.x
			elif m == dt:
				position.y = r.position.y
			else:
				position.y = r.end.y
	position = game.map.clamp_to_map(position)


# ---------------------------------------------------------------- drawing

func _draw():
	var shape = def["shape"]
	var lift = Vector2.ZERO
	if is_air:
		lift = Vector2(0, -22 + sin(anim * 3.0) * 3.0)
		draw_circle(Vector2(6, 10), radius * 0.9, Color(0, 0, 0, 0.25))
	else:
		draw_circle(Vector2(3, 4), radius, Color(0, 0, 0, 0.22))
	draw_selection(radius + 5)

	var body = team_color()
	if flash > 0:
		body = Color(1, 1, 1)
	match shape:
		"infantry", "infantry_heavy", "infantry_cloak":
			_draw_infantry(shape, body)
		"buggy":
			_draw_buggy(body)
		"harvester":
			_draw_harvester(body)
		"tank_tesla", "tank_siege":
			_draw_tank(shape, body)
		"drone":
			_draw_drone(body, lift)
		"heli":
			_draw_heli(body, lift)
		_:
			draw_outlined_circle(Vector2.ZERO, radius, body)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_health(radius * 2.4, -radius - 14 + lift.y)
	if panic_time > 0 and int(anim * 6) % 2 == 0:
		draw_string(game.font, Vector2(-3, -radius - 18 + lift.y), "!", Color(1, 0.9, 0.2))


func _draw_infantry(shape, body):
	var bob = sin(anim * 14.0) * 1.5 if moving else 0.0
	var o = Vector2(0, bob)
	var gun_dir = Vector2.RIGHT.rotated(turret_angle)
	if shape == "infantry_cloak":
		draw_outlined_poly([o + Vector2(0, -9), o + Vector2(8, 8), o + Vector2(-8, 8)], Color("#c9a46a"), 2.5)
		draw_line(o + Vector2(-5, -1), o + Vector2(5, -1), body, 3.0)
	elif shape == "infantry_heavy":
		draw_outlined_poly(rect_points(o + Vector2(0, 2), Vector2(16, 12)), body, 2.5)
	else:
		draw_outlined_circle(o + Vector2(0, 2), 6, body, 2.5)
	draw_line(o, o + gun_dir * 13, INK, 3.0)
	var head = Color("#e2b48a") if shape != "infantry_heavy" else team_dark()
	draw_outlined_circle(o + Vector2(0, -6), 4.5, head, 2.0)


func _draw_buggy(body):
	draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
	for w in [Vector2(-9, -9), Vector2(9, -9), Vector2(-9, 9), Vector2(9, 9)]:
		draw_rect(Rect2(w - Vector2(5, 3), Vector2(10, 6)), INK)
	draw_outlined_poly(rect_points(Vector2.ZERO, Vector2(26, 15)), body)
	draw_rect(Rect2(Vector2(-6, -6), Vector2(8, 12)), team_dark())
	draw_set_transform(Vector2.ZERO, turret_angle, Vector2.ONE)
	draw_line(Vector2.ZERO, Vector2(16, 0), INK, 4.0)


func _draw_harvester(body):
	draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
	draw_rect(Rect2(Vector2(-20, -16), Vector2(40, 6)), INK)
	draw_rect(Rect2(Vector2(-20, 10), Vector2(40, 6)), INK)
	draw_outlined_poly(rect_points(Vector2.ZERO, Vector2(36, 24)), Color("#c8b28a"))
	draw_outlined_poly([Vector2(18, -12), Vector2(28, -15), Vector2(28, 15), Vector2(18, 12)], Color("#7d7d7d"))
	# Uralium hopper shows the load.
	draw_rect(Rect2(Vector2(-14, -8), Vector2(20, 16)), INK)
	var fill = clamp(cargo / max(1.0, def.get("capacity", 500)), 0, 1)
	draw_rect(Rect2(Vector2(-13, -7), Vector2(18 * fill, 14)), Color("#c0392b"))
	draw_rect(Rect2(Vector2(8, -6), Vector2(8, 12)), body)
	if moving and int(anim * 10) % 2 == 0:
		draw_circle(Vector2(-22, 0), 4, Color(0.95, 0.85, 0.6, 0.6))


func _draw_tank(shape, body):
	var size = Vector2(34, 24) if shape == "tank_tesla" else Vector2(42, 28)
	draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
	draw_rect(Rect2(Vector2(-size.x / 2 - 2, -size.y / 2 - 3), Vector2(size.x + 4, 7)), INK)
	draw_rect(Rect2(Vector2(-size.x / 2 - 2, size.y / 2 - 4), Vector2(size.x + 4, 7)), INK)
	draw_outlined_poly(rect_points(Vector2.ZERO, size), body)
	draw_set_transform(Vector2.ZERO, turret_angle, Vector2.ONE)
	if shape == "tank_tesla":
		draw_outlined_circle(Vector2.ZERO, 9, team_dark())
		var glow = Color(0.5, 0.85, 1.0) if reload_left <= 0 else Color(0.3, 0.4, 0.5)
		draw_line(Vector2(0, 0), Vector2(14, 0), INK, 5.0)
		draw_outlined_circle(Vector2(15, 0), 5, glow, 2.0)
	else:
		draw_line(Vector2(0, 0), Vector2(30, 0), INK, 7.0)
		draw_line(Vector2(0, 0), Vector2(29, 0), Color("#5a5a5a"), 3.0)
		draw_outlined_circle(Vector2.ZERO, 11, team_dark())


func _draw_drone(body, lift):
	draw_set_transform(lift, facing, Vector2.ONE)
	for a in [PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4]:
		var tip = Vector2.RIGHT.rotated(a) * 11
		draw_line(Vector2.ZERO, tip, INK, 3.0)
		draw_arc(tip, 5, anim * 30.0, anim * 30.0 + PI, 6, Color(0.9, 0.9, 0.9, 0.7), 2.0)
	draw_outlined_circle(Vector2.ZERO, 6, body, 2.5)


func _draw_heli(body, lift):
	draw_set_transform(lift, facing, Vector2.ONE)
	draw_line(Vector2(-6, 0), Vector2(-28, 0), INK, 5.0)
	draw_line(Vector2(-6, 0), Vector2(-27, 0), body, 2.0)
	draw_line(Vector2(-28, -6), Vector2(-28, 6), INK, 3.0)
	draw_outlined_poly([Vector2(16, 0), Vector2(8, -9), Vector2(-10, -8), Vector2(-12, 0), Vector2(-10, 8), Vector2(8, 9)], body)
	draw_outlined_poly([Vector2(14, 0), Vector2(8, -5), Vector2(4, 0), Vector2(8, 5)], Color(0.6, 0.85, 1.0), 2.0)
	var a = anim * 25.0
	for k in range(3):
		var dir = Vector2.RIGHT.rotated(a + k * TAU / 3)
		draw_line(-dir * 4, dir * 26, Color(0.1, 0.1, 0.1, 0.6), 3.0)
