extends Node2D
# Pressurised uralium blooms. Anything on the ground that touches one starts a short fuse;
# the bloom then bursts in a deadly cloud and scatters fresh uralium around it.

const TRIGGER_RADIUS = 42.0
const BLAST_RADIUS = 170.0
const BLAST_DAMAGE = 320.0
const FUSE = 1.4

var game
var blooms = []   # each: {"cell", "pos", "fuse" (-1 = idle), "phase"}
var time = 0.0
var scan = 0.0


func setup(g):
	game = g
	for c in game.map.bloom_cells:
		blooms.append({"cell": c, "pos": game.map.center_of(c), "fuse": -1.0, "phase": randf() * TAU})


func _process(delta):
	time += delta
	scan -= delta
	for b in blooms:
		if b["fuse"] >= 0:
			b["fuse"] += delta
			game.smoke.emit(b["pos"], Vector2(rand_range(-50, 50), rand_range(-70, -20)), 0.8, 5, 20, Color(0.7, 0.12, 0.08, 0.6), Color(0.6, 0.15, 0.1, 0.0))
		elif randf() < delta * 0.5:
			# an idle bloom vents a wisp of red gas now and then
			game.smoke.emit(b["pos"], Vector2(rand_range(4, 12), rand_range(-22, -12)), 1.8, 4, 16, Color(0.62, 0.12, 0.08, 0.35), Color(0.6, 0.15, 0.1, 0.0), 0.3)
	if scan <= 0:
		scan = 0.2
		for b in blooms:
			if b["fuse"] >= 0:
				continue
			for u in get_tree().get_nodes_in_group("ground_units"):
				if not u.dead and u.position.distance_to(b["pos"]) < TRIGGER_RADIUS + u.radius:
					b["fuse"] = 0.0
					game.fx_text(b["pos"] + Vector2(0, -30), "HSSSS!", Color(1, 0.6, 0.4))
					break
	var still = []
	for b in blooms:
		if b["fuse"] >= FUSE:
			_burst(b)
		else:
			still.append(b)
	blooms = still
	update()


func _burst(b):
	var p = b["pos"]
	game.fx_uralium_cloud(p)
	game.fx_text(p + Vector2(0, -50), "KA-BOOM!", Color(1, 0.35, 0.25))
	for e in get_tree().get_nodes_in_group("entities"):
		if e.dead or e.is_air:
			continue
		var d = e.global_position.distance_to(p)
		if d < BLAST_RADIUS:
			e.take_damage(BLAST_DAMAGE * (1.0 - 0.6 * d / BLAST_RADIUS))
	game.loud_noise(p, 600)
	# Fresh uralium scattered around the crater.
	var c0 = b["cell"]
	for y in range(-3, 4):
		for x in range(-3, 4):
			var c = c0 + Vector2(x, y)
			if c.distance_to(c0) <= 3.2:
				game.map.add_uralium(c, 400 + randi() % 300)


func _draw():
	for b in blooms:
		var p = b["pos"]
		var armed = b["fuse"] >= 0
		var speed = 14.0 if armed else 1.6
		var pulse = 0.5 + 0.5 * sin(time * speed + b["phase"])
		var r = 24 + pulse * (5 if armed else 1.5)
		# soft shadow, then a swollen dome built from layered tones (dark rim to lit crown)
		draw_circle(p + Vector2(6, 7), r * 1.05, Color(0.10, 0.06, 0.03, 0.30))
		for i in range(7):
			var k = i / 6.0
			var col = Color(0.30, 0.07, 0.05).linear_interpolate(Color(0.66, 0.20, 0.13), k)
			draw_circle(p + Vector2(-r, -r) * 0.22 * k, r * (1.0 - k * 0.72), col)
		draw_circle(p + Vector2(-r, -r) * 0.36, r * 0.12, Color(1, 0.75, 0.65, 0.5))
		# glowing fissures
		var heat = 0.45 + 0.55 * pulse
		# Irregular cracks: uneven angles, lengths and bends so they never form a regular figure.
		var angles = [0.3, 1.9, 2.7, 4.4, 5.3]
		var bends = [5.0, -7.0, 3.0, 6.0, -4.0]
		var lens = [0.95, 0.7, 0.85, 0.6, 0.9]
		for k2 in range(5):
			var a = angles[k2] + b["phase"]
			var d = Vector2.RIGHT.rotated(a)
			var tip = p + d * (r - 3) * lens[k2]
			var mid = p + d * r * 0.42 * lens[k2] + d.tangent() * bends[k2]
			var pts = PoolVector2Array([p + d * 3, mid, tip])
			draw_polyline(pts, Color(0.12, 0.02, 0.02), 3.0, true)
			draw_polyline(pts, Color(1.0, 0.45, 0.15, heat), 1.2, true)
		if armed:
			draw_arc(p, TRIGGER_RADIUS + 30 * pulse, 0, TAU, 32, Color(1, 0.3, 0.2, 0.7), 2.0, true)
