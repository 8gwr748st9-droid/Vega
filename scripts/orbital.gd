extends Node2D
# Arthem orbital vaporiser (experimental, test phase).
# Unstable: the beam lands somewhat off target. It vaporises vehicles and structures,
# hurts infantry less, and terrifies every enemy unit nearby into fleeing.

const WARMUP = 2.2
const RADIUS = 130.0
const MAX_DRIFT = 170.0
const FEAR_RADIUS = 550.0
const FEAR_TIME = 8.0

var game
var team = 0
var aim = Vector2()
var impact = Vector2()
var t = 0.0
var fired = false


func setup(g, owner_team, target):
	game = g
	team = owner_team
	aim = target
	# Test-phase instability: random drift, usually noticeable, never exactly on target.
	impact = game.map.clamp_to_map(target + Vector2.RIGHT.rotated(randf() * TAU) * rand_range(50, MAX_DRIFT))
	z_index = 15


func _process(delta):
	t += delta
	# The beam wanders while it locks on.
	if not fired and t >= WARMUP:
		fired = true
		_strike()
	if t >= WARMUP + 1.2:
		queue_free()
	update()


func _strike():
	var attacker_faction = game.team_faction[team]
	for e in get_tree().get_nodes_in_group("entities"):
		if e.dead or e.team == team or not Data.factions_hostile(attacker_faction, e.faction):
			continue
		var d = e.global_position.distance_to(impact)
		if d > RADIUS + e.radius:
			continue
		var infantry = (not e.is_building) and e.def["shape"].begins_with("infantry")
		e.take_damage(300.0 if infantry else 1500.0)
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead or u.team == team or not Data.factions_hostile(attacker_faction, u.faction):
			continue
		if u.position.distance_to(impact) < FEAR_RADIUS:
			u.panic(impact, FEAR_TIME)
	game.fx_explosion(impact, 3.0)
	game.fx_text(impact + Vector2(0, -80), "FZZZOOOM!", Color(0.6, 0.95, 1.0))
	game.loud_noise(impact, 1200)


func _draw():
	var ink = Color("#1d130c")
	if not fired:
		var k = t / WARMUP
		# Wobbling targeting beam drifting from the aim point to the real impact point.
		var p = aim.linear_interpolate(impact, k) + Vector2(sin(t * 23) * 12, cos(t * 17) * 12) * (1 - k)
		draw_arc(aim - position, RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.25), 2.0)
		draw_line(p - position + Vector2(0, -900), p - position, Color(0.5, 0.9, 1.0, 0.25 + 0.5 * k), 4 + 10 * k)
		draw_arc(p - position, RADIUS * (1.2 - 0.4 * k), 0, TAU, 32, Color(0.5, 0.9, 1.0, 0.8), 3.0)
		draw_circle(p - position, 5, Color(1.5, 2.0, 2.4, 0.9))
	else:
		var f = clamp((t - WARMUP) / 1.2, 0, 1)
		var c = impact - position
		draw_line(c + Vector2(0, -1200), c, Color(0.5, 0.9, 1.6, 0.6 * (1 - f)), 90 * (1 - f) + 8)
		draw_line(c + Vector2(0, -1200), c, Color(1.6, 2.0, 2.4, 1 - f), 40 * (1 - f) + 3)
		draw_circle(c, RADIUS * (0.6 + f * 0.6), Color(0.6, 0.9, 1.0, 0.6 * (1 - f)))
		draw_arc(c, RADIUS * (0.5 + f), 0, TAU, 40, Color(1, 1, 1, 1 - f), 6.0)
