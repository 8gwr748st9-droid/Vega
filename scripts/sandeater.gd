extends Node2D
# Sandeater. Lives under the sand, feeds on Uralium and guards its feeding ground.
#  - Territorial: hunts ground units on sand inside its territory (harvesters first).
#  - Whatever it swallows (people, vehicles, harvesters) is gone for good.
#  - After feeding, the sandeater itself disappears into the deep sand and comes back later.
#  - Cannot cross rock and cannot be killed.
#  - Freedom Fighters are ignored. They can ride a sandeater by tricking it into thinking it is
#    mating; a ridden sandeater leaves lines of Uralium on the sand that can be harvested.

const GRAZE_SPEED = 45.0
const HUNT_SPEED = 115.0
const RIDE_SPEED = 175.0
const TERRITORY = 700.0
const BITE_RADIUS = 70.0
const EAT_RATE = 6.0

var game
var state = "graze"      # graze | hunt | strike | gone | ridden | dive
var home = Vector2()
var heading = 0.0
var prey = null
var cooldown = 20.0
var t = 0.0
var anim = 0.0
var warned = false
var away_time = 0.0      # how long it stays gone after feeding
var ride_to = Vector2()
var ride_target = Vector2()
var riders = 0
var trail_acc = 0.0
var temporary = false


func setup(g, p):
	game = g
	position = p
	home = p
	heading = randf() * TAU


func setup_ridden(g, from, to, rider_count, attack_pos):
	setup(g, from)
	state = "ridden"
	ride_to = to
	ride_target = attack_pos
	riders = rider_count
	temporary = true
	z_index = 3


func _process(delta):
	anim += delta
	cooldown -= delta
	match state:
		"graze":
			_graze(delta)
		"hunt":
			_hunt(delta)
		"strike":
			t += delta
			if t >= 0.55 and t - delta < 0.55:
				_bite()
			if t >= 1.8:
				# Sinks into the deep sand and stays away for a while.
				state = "gone"
				z_index = 0
				away_time = rand_range(90, 150)
				visible = false
		"gone":
			away_time -= delta
			if away_time <= 0:
				_return_home()
		"ridden":
			_ride(delta)
		"dive":
			t += delta
			if t >= 1.4:
				queue_free()
	update()


func _graze(delta):
	# Wander, drift back home, nibble Uralium.
	if randf() < delta * 0.4:
		heading += rand_range(-1.2, 1.2)
	if position.distance_to(home) > TERRITORY * 0.6:
		heading = lerp_angle(heading, (home - position).angle(), min(1.0, delta * 2.0))
	_move(GRAZE_SPEED, delta)
	var c = game.map.cell_of(position)
	if game.map.uralium_at(c) > 0:
		game.map.take_uralium(c, EAT_RATE * delta)
	if cooldown <= 0 and int(anim * 4) % 4 == 0:
		prey = _find_intruder()
		if prey:
			state = "hunt"
			warned = false


func _hunt(delta):
	if not _valid_prey(prey) or prey.position.distance_to(home) > TERRITORY * 1.2:
		prey = null
		state = "graze"
		cooldown = 4.0
		return
	var to = prey.position - position
	heading = to.angle()
	_move(HUNT_SPEED, delta)
	if not warned and to.length() < 320:
		warned = true
		game.on_sandeater_alert(prey)
	if to.length() < 26:
		state = "strike"
		t = 0.0
		z_index = 4


func _valid_prey(u):
	return u != null and is_instance_valid(u) and not u.dead and game.map.is_sand_at(u.position)


func _move(speed, delta):
	var next = position + Vector2.RIGHT.rotated(heading) * speed * delta
	if game.map.is_sand_at(next) and game.map.in_bounds(game.map.cell_of(next)):
		position = next
	else:
		heading += PI * rand_range(0.5, 1.0)


func _find_intruder():
	var best = null
	var best_d = TERRITORY
	for u in get_tree().get_nodes_in_group("ground_units"):
		if u.dead or Data.FACTIONS[u.faction].get("eater_safe", false):
			continue
		if not game.map.is_sand_at(u.position) or u.position.distance_to(home) > TERRITORY:
			continue
		var is_harv = u.def.get("harvester", false)
		if not u.moving and not is_harv:
			continue
		var d = position.distance_to(u.position) * (0.5 if is_harv else 1.0)
		if d < best_d:
			best_d = d
			best = u
	return best


func _bite():
	game.fx_text(position + Vector2(0, -60), "GULP!", Color(1, 0.85, 0.3))
	game.loud_noise(position, 500)
	for u in get_tree().get_nodes_in_group("ground_units"):
		if u.dead or Data.FACTIONS[u.faction].get("eater_safe", false):
			continue
		if u.position.distance_to(position) < BITE_RADIUS and game.map.is_sand_at(u.position):
			game.swallow_unit(u)


func _return_home():
	# Resurfaces somewhere on the sand in its own territory.
	var p = home
	for i in range(40):
		var cand = home + Vector2.RIGHT.rotated(randf() * TAU) * rand_range(0, TERRITORY * 0.5)
		if game.map.is_sand_at(cand) and game.map.in_bounds(game.map.cell_of(cand)):
			p = cand
			break
	position = p
	state = "graze"
	visible = true
	cooldown = rand_range(10, 20)
	game.on_sandeater_returned(self)


func _ride(delta):
	var to = ride_to - position
	if to.length() < 20:
		for i in range(riders):
			var u = game.spawn_unit("freedom_warrior", game.freedom_team, position + Vector2(rand_range(-50, 50), rand_range(-50, 50)))
			u.order_attack_move(ride_target)
		game.fx_text(position + Vector2(0, -60), "SANDEATER RIDERS!", Color(1, 0.85, 0.3))
		state = "dive"
		t = 0.0
		return
	heading = to.angle()
	var step = Vector2.RIGHT.rotated(heading) * min(to.length(), RIDE_SPEED * delta)
	position += step
	trail_acc += step.length()
	if trail_acc >= 40.0:
		trail_acc = 0.0
		var c = game.map.cell_of(position)
		if game.map.get_type(c) == game.map.SAND:
			game.map.add_uralium(c, 90)


func _draw():
	var ink = Color("#1d130c")
	if state == "strike" or state == "dive":
		var k
		if state == "dive":
			k = clamp(1.0 - t / 1.4, 0, 1)
		elif t < 1.2:
			k = clamp(t / 0.5, 0, 1)
		else:
			k = clamp((1.8 - t) / 0.6, 0, 1)
		var r = 18 + 52 * k
		draw_circle(Vector2(0, 8), r * 1.3, Color(0.85, 0.65, 0.4, 0.6))
		draw_circle(Vector2.ZERO, r + 4, ink)
		draw_circle(Vector2.ZERO, r, Color("#7f8a6a"))
		draw_circle(Vector2.ZERO, r * 0.72, Color("#3a0f0a"))
		for ring in [0.7, 0.5]:
			for i in range(12):
				var a = i * TAU / 12 + ring
				draw_line(Vector2.RIGHT.rotated(a) * r * ring, Vector2.RIGHT.rotated(a) * r * (ring - 0.18), Color("#f3e6c8"), 3.0)
		return
	var dir = Vector2.RIGHT.rotated(heading)
	var side = Vector2(-dir.y, dir.x)
	if state == "ridden":
		# Back of the sandeater above the sand, riders holding on.
		for i in range(7):
			var p = -dir * i * 15
			draw_circle(p, 13 - i, ink)
			draw_circle(p, 11 - i, Color("#7f8a6a"))
		for i in range(min(riders, 4)):
			var rp = -dir * (8 + i * 12) + side * (4 if i % 2 == 0 else -4)
			draw_circle(rp, 5, ink)
			draw_circle(rp, 4, Color("#c9a46a"))
		return
	# Under the sand: a travelling ripple with a red glint from the Uralium it eats.
	for i in range(6):
		var p2 = -dir * i * 16
		var w = 14 - i * 1.5 + sin(anim * 6 + i) * 2
		draw_line(p2 - side * w, p2 + side * w, Color(0.55, 0.38, 0.2, 0.55 - i * 0.07), 5.0)
	if int(anim * 3) % 3 == 0:
		draw_circle(-dir * 20, 3, Color(0.85, 0.2, 0.15, 0.7))
	if state == "hunt":
		draw_arc(Vector2.ZERO, 18 + sin(anim * 10) * 4, 0, TAU, 16, Color(0.6, 0.35, 0.15, 0.6), 3.0)
