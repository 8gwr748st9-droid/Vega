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
	var infantry = shape.begins_with("infantry")
	var lift = Vector2.ZERO
	var shadow_off = Vector2(3, 4)
	if is_air:
		lift = Vector2(0, -26 + sin(anim * 3.0) * 2.5)
		shadow_off = Vector2(16, 12)
	elif infantry and moving:
		lift = Vector2(0, -abs(sin(anim * 11.0)) * 1.5)
	draw_selection(radius + 5)

	var hull = kind + "/hull"
	var mod = Color(1.7, 1.7, 1.7) if flash > 0 else Color(1, 1, 1)
	var body_angle = facing
	if infantry and is_instance_valid(target):
		body_angle = turret_angle
	if Art.has(hull):
		Art.draw_shadow(self, hull, body_angle, Vector2.ZERO, shadow_off, 0.22 if is_air else 0.34)
		Art.draw_part(self, hull, body_angle, lift, mod)
		if def.get("harvester", false) and cargo > 0:
			var fill = clamp(cargo / max(1.0, def.get("capacity", 500)), 0, 1)
			draw_set_transform(lift, facing, Vector2.ONE)
			draw_rect(Rect2(Vector2(-15, -6), Vector2(16 * fill, 12)), Color(0.62, 0.10, 0.07))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if Art.has(kind + "/turret"):
			Art.draw_part(self, kind + "/turret", turret_angle, lift, mod)
	else:
		draw_circle(Vector2(3, 4), radius, Color(0, 0, 0, 0.22))
		draw_circle(lift, radius * 0.8, team_color())

	if shape == "heli":
		_draw_rotor(lift, 27.0, 3)
	elif shape == "drone":
		for d in [Vector2(9, 9), Vector2(9, -9), Vector2(-9, 9), Vector2(-9, -9)]:
			draw_circle(lift + d.rotated(facing), 5.0, Color(0.85, 0.87, 0.9, 0.28))
	elif shape == "tank_tesla" and reload_left <= 0:
		var tip = lift + Vector2(16, 0).rotated(turret_angle) * radius / 18.0
		draw_circle(tip, 5.0 + sin(anim * 9.0), Color(0.5, 0.8, 1.0, 0.35))

	draw_health(max(22.0, radius * 2.2), -radius - 12 + lift.y)
	if panic_time > 0 and int(anim * 6) % 2 == 0:
		draw_string(game.font, Vector2(-3, -radius - 16 + lift.y), "!", Color(1, 0.9, 0.2))


func _draw_rotor(center, r, blades):
	# Spinning rotor: a faint blur disc plus fast blades.
	draw_circle(center, r, Color(0.8, 0.82, 0.85, 0.10))
	for k in range(blades):
		var a = anim * 38.0 + k * TAU / blades
		var d = Vector2.RIGHT.rotated(a)
		draw_line(center - d * 3, center + d * r, Color(0.08, 0.08, 0.09, 0.45), 2.5, true)
		var d2 = Vector2.RIGHT.rotated(a - 0.25)
		draw_line(center, center + d2 * r, Color(0.08, 0.08, 0.09, 0.15), 4.0, true)
