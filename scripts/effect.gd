extends Node2D
# Short-lived line effects drawn with additive blending: tracers, tesla bolts, shockwaves.

var kind = "tracer"
var life = 0.3
var age = 0.0
var size = 1.0
var a = Vector2()
var b = Vector2()
var jag = 0.0
var pts = PoolVector2Array()


func _process(delta):
	age += delta
	if age >= life:
		queue_free()
		return
	update()


func _bolt(from, to, spread):
	var out = PoolVector2Array([from])
	var n = max(3, int(from.distance_to(to) / 22.0))
	var side = (to - from).normalized().tangent()
	for i in range(1, n):
		out.append(from.linear_interpolate(to, float(i) / n) + side * rand_range(-spread, spread))
	out.append(to)
	return out


func _draw():
	var t = age / life
	var fade = 1.0 - t
	match kind:
		"tracer":
			var head = a.linear_interpolate(b, min(1.0, t * 1.4 + 0.3)) - position
			var tail = a.linear_interpolate(b, max(0.0, t * 1.4 - 0.2)) - position
			draw_line(tail, head, Color(1.1, 0.95, 0.6, fade * 0.8), 1.2, true)
		"tesla":
			# The bolt re-forms every few frames, like a real arc.
			jag -= 1
			if jag <= 0:
				jag = 2
				pts = _bolt(a - position, b - position, 12.0)
			draw_polyline(pts, Color(0.25, 0.5, 1.6, fade * 0.6), 7.0, true)
			draw_polyline(pts, Color(0.8, 1.2, 2.2, fade), 2.5, true)
			var branch = _bolt(pts[int(pts.size() / 2)], pts[int(pts.size() / 2)] + Vector2(rand_range(-40, 40), rand_range(-40, 40)), 6.0)
			draw_polyline(branch, Color(0.6, 0.9, 1.8, fade * 0.7), 1.5, true)
		"shock":
			draw_arc(Vector2.ZERO, (16 + 90 * t) * size, 0, TAU, 40, Color(1.2, 1.0, 0.8, 0.35 * fade), 3.0 * fade + 1.0, true)
