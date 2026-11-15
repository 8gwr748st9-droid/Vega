extends Node2D
# Desert wildlife. Purely cosmetic: wanders, reacts to units, explosions and worms.
#   lizard   – scurries away fast
#   hopper   – jumps away and burrows into the sand when frightened
#   bird     – circles above and scatters at loud noises

var game
var kind = "lizard"
var vel = Vector2()
var fear = 0.0
var hidden = 0.0
var anim = 0.0
var think = 0.0
var orbit_centre = Vector2()
var orbit_angle = 0.0


func setup(g, k, p):
	game = g
	kind = k
	position = p
	orbit_centre = p
	anim = randf() * 10.0
	if kind == "bird":
		z_index = 12


func scare(from_pos, strength = 1.0):
	var away = (position - from_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	fear = 2.0 * strength
	match kind:
		"lizard":
			vel = away * 140
		"hopper":
			vel = away * 90
			hidden = 4.0 + randf() * 3.0
		"bird":
			orbit_centre += away * 300


func _process(delta):
	anim += delta
	think -= delta
	if fear > 0:
		fear -= delta
	if hidden > 0:
		hidden -= delta
	if kind == "bird":
		orbit_angle += delta * (0.5 if fear <= 0 else 1.6)
		var target = orbit_centre + Vector2(cos(orbit_angle), sin(orbit_angle) * 0.6) * 120
		position = position.linear_interpolate(target, min(1.0, delta * 2.0))
		orbit_centre = game.map.clamp_to_map(orbit_centre)
	else:
		if think <= 0:
			think = 0.4
			_look_around()
		if fear <= 0 and randf() < delta * 0.5:
			vel = Vector2.RIGHT.rotated(randf() * TAU) * rand_range(5, 20)
		var next = game.map.clamp_to_map(position + vel * delta)
		position = next
		vel *= 1.0 - min(1.0, delta * (0.8 if fear > 0 else 0.3))
	update()


func _look_around():
	for u in get_tree().get_nodes_in_group("ground_units"):
		if not u.dead and u.position.distance_to(position) < 110:
			scare(u.position)
			return


func _draw():
	var ink = Color("#1d130c")
	match kind:
		"lizard":
			var dir = vel.normalized() if vel.length() > 1 else Vector2.RIGHT.rotated(anim * 0.1)
			var side = Vector2(-dir.y, dir.x)
			var wig = sin(anim * 20.0) * 2.0 if vel.length() > 10 else 0.0
			draw_line(-dir * 9, -dir * 3 + side * wig, ink, 2.0)
			draw_circle(Vector2.ZERO, 3.5, Color("#7c8a4a"))
			draw_circle(dir * 4, 2.5, Color("#7c8a4a"))
			draw_line(side * 4 - dir * 1, -side * 4 + dir * 1, ink, 1.5)
		"hopper":
			if hidden > 0:
				draw_circle(Vector2.ZERO, 4, Color(0.6, 0.42, 0.22, 0.6))
				return
			var hop = abs(sin(anim * (12.0 if fear > 0 else 3.0))) * (8 if fear > 0 else 2)
			draw_circle(Vector2(0, 2), 4, Color(0, 0, 0, 0.2))
			draw_circle(Vector2(0, -hop), 4.5, Color("#c9a273"))
			draw_line(Vector2(-2, -hop - 3), Vector2(-4, -hop - 11), ink, 2.0)
			draw_line(Vector2(2, -hop - 3), Vector2(4, -hop - 11), ink, 2.0)
		"bird":
			var flap = sin(anim * (10.0 if fear > 0 else 4.0)) * 5
			draw_polyline(PoolVector2Array([Vector2(-10, flap), Vector2(-4, 0), Vector2(0, 2), Vector2(4, 0), Vector2(10, flap)]), ink, 2.5)
