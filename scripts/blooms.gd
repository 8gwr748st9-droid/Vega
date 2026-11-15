extends Node2D
# Pressurised spice blooms. Anything on the ground that touches one starts a short fuse;
# the bloom then bursts in a deadly cloud and scatters fresh spice around it.

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
	game.fx_spice_cloud(p)
	game.fx_text(p + Vector2(0, -50), "KA-BOOM!", Color(1, 0.35, 0.25))
	for e in get_tree().get_nodes_in_group("entities"):
		if e.dead or e.is_air:
			continue
		var d = e.global_position.distance_to(p)
		if d < BLAST_RADIUS:
			e.take_damage(BLAST_DAMAGE * (1.0 - 0.6 * d / BLAST_RADIUS))
	game.loud_noise(p, 600)
	# Fresh spice scattered around the crater.
	var c0 = b["cell"]
	for y in range(-3, 4):
		for x in range(-3, 4):
			var c = c0 + Vector2(x, y)
			if c.distance_to(c0) <= 3.2:
				game.map.add_spice(c, 400 + randi() % 300)


func _draw():
	for b in blooms:
		var p = b["pos"]
		var armed = b["fuse"] >= 0
		var speed = 14.0 if armed else 2.0
		var pulse = 0.5 + 0.5 * sin(time * speed + b["phase"])
		var r = 22 + pulse * (6 if armed else 3)
		draw_circle(p + Vector2(3, 5), r, Color(0, 0, 0, 0.2))
		draw_circle(p, r + 2, Color("#1d130c"))
		draw_circle(p, r - 1, Color("#a3271c"))
		draw_circle(p + Vector2(-5, -6), r * 0.45, Color(0.95, 0.45, 0.3, 0.7))
		# Cracks venting red gas.
		for k in range(3):
			var dir = Vector2.RIGHT.rotated(k * TAU / 3 + b["phase"])
			draw_line(p + dir * 6, p + dir * (r - 2), Color("#1d130c"), 2.0)
		if armed:
			draw_arc(p, TRIGGER_RADIUS + 30 * pulse, 0, TAU, 24, Color(1, 0.3, 0.2, 0.8), 3.0)
