extends Node2D
# Sandworm. Roams under the sand, hunts vibrations (moving ground units, especially harvesters)
# and swallows anything on the sand where it surfaces. It cannot cross rock and cannot be killed.
# Freedom fighters move without rhythm and are never hunted.

const ROAM_SPEED = 60.0
const HUNT_SPEED = 115.0
const SENSE_RANGE = 650.0
const BITE_RADIUS = 70.0

var game
var state = "roam"
var heading = 0.0
var prey = null
var cooldown = 20.0
var t = 0.0
var anim = 0.0
var warned = false


func setup(g, p):
	game = g
	position = p
	heading = randf() * TAU


func _process(delta):
	anim += delta
	cooldown -= delta
	match state:
		"roam":
			if randf() < delta * 0.4:
				heading += rand_range(-1.2, 1.2)
			_move(ROAM_SPEED, delta)
			if cooldown <= 0 and int(anim * 4) % 4 == 0:
				prey = _find_prey()
				if prey:
					state = "hunt"
					warned = false
		"hunt":
			if prey == null or not is_instance_valid(prey) or prey.dead or not game.map.is_sand_at(prey.position):
				prey = null
				state = "roam"
				cooldown = 4.0
			else:
				var to = prey.position - position
				heading = to.angle()
				_move(HUNT_SPEED, delta)
				if not warned and to.length() < 320:
					warned = true
					game.on_wormsign(prey)
				if to.length() < 26:
					state = "strike"
					t = 0.0
					z_index = 4
		"strike":
			t += delta
			if t >= 0.55 and t - delta < 0.55:
				_bite()
			if t >= 1.8:
				state = "roam"
				z_index = 0
				cooldown = rand_range(25, 40)
	update()


func _move(speed, delta):
	var next = position + Vector2.RIGHT.rotated(heading) * speed * delta
	if game.map.is_sand_at(next) and game.map.in_bounds(game.map.cell_of(next)):
		position = next
	else:
		heading += PI * rand_range(0.5, 1.0)


func _find_prey():
	var best = null
	var best_d = SENSE_RANGE
	for u in get_tree().get_nodes_in_group("ground_units"):
		if u.dead or Data.FACTIONS[u.faction].get("worm_safe", false):
			continue
		if not game.map.is_sand_at(u.position):
			continue
		var is_harv = u.def.get("harvester", false)
		if not u.moving and not is_harv:
			continue
		var d = position.distance_to(u.position) * (0.6 if is_harv else 1.0)
		if d < best_d:
			best_d = d
			best = u
	return best


func _bite():
	game.fx_text(position + Vector2(0, -60), "GULP!", Color(1, 0.85, 0.3))
	game.loud_noise(position, 500)
	for u in get_tree().get_nodes_in_group("ground_units"):
		if u.dead or Data.FACTIONS[u.faction].get("worm_safe", false):
			continue
		if u.position.distance_to(position) < BITE_RADIUS and game.map.is_sand_at(u.position):
			u.take_damage(99999)


func _draw():
	if state == "strike":
		var k = clamp(t / 0.5, 0, 1) if t < 1.2 else clamp((1.8 - t) / 0.6, 0, 1)
		var r = 18 + 52 * k
		draw_circle(Vector2(0, 8), r * 1.3, Color(0.85, 0.65, 0.4, 0.6))
		draw_circle(Vector2.ZERO, r + 4, Color("#1d130c"))
		draw_circle(Vector2.ZERO, r, Color("#9c7a55"))
		draw_circle(Vector2.ZERO, r * 0.72, Color("#3a0f0a"))
		# Rings of teeth.
		for ring in [0.7, 0.5]:
			for i in range(14):
				var a = i * TAU / 14 + ring
				var base = Vector2.RIGHT.rotated(a) * r * ring
				var tip = Vector2.RIGHT.rotated(a) * r * (ring - 0.18)
				draw_line(base, tip, Color("#f3e6c8"), 3.0)
		return
	# Underground: a travelling sand ripple.
	var dir = Vector2.RIGHT.rotated(heading)
	var side = Vector2(-dir.y, dir.x)
	for i in range(6):
		var p = -dir * i * 16
		var w = 14 - i * 1.5 + sin(anim * 6 + i) * 2
		draw_line(p - side * w, p + side * w, Color(0.55, 0.38, 0.2, 0.55 - i * 0.07), 5.0)
	if state == "hunt":
		draw_arc(Vector2.ZERO, 18 + sin(anim * 10) * 4, 0, TAU, 16, Color(0.6, 0.35, 0.15, 0.6), 3.0)
