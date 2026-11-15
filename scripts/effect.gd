extends Node2D
# Short-lived visual effects: explosions, tracers, tesla arcs, smoke puffs, comic text.

var kind = "explosion"
var life = 0.5
var age = 0.0
var size = 1.0
var a = Vector2()
var b = Vector2()
var text = ""
var color = Color(1, 1, 1)
var font = null
var points = []


func _process(delta):
	age += delta
	if age >= life:
		queue_free()
		return
	if kind == "text":
		position.y -= delta * 30.0
	update()


func _draw():
	var t = age / life
	match kind:
		"explosion":
			var r = (14 + 36 * t) * size
			draw_circle(Vector2.ZERO, r, Color(0.15, 0.1, 0.07, 0.5 * (1 - t)))
			draw_circle(Vector2.ZERO, r * 0.8, Color(1.0, 0.55, 0.12, 1 - t))
			draw_circle(Vector2.ZERO, r * 0.45, Color(1.0, 0.95, 0.5, 1 - t))
			# Comic starburst.
			var pts = PoolVector2Array()
			for k in range(16):
				var rr = r * (1.25 if k % 2 == 0 else 0.75)
				pts.append(Vector2.RIGHT.rotated(k * TAU / 16 + size) * rr)
			pts.append(pts[0])
			draw_polyline(pts, Color(0.12, 0.08, 0.05, 1 - t), 3.0)
		"tracer":
			draw_line(a - position, b - position, Color(1, 0.95, 0.6, 1 - t), 2.0)
			draw_circle(b - position, 3, Color(1, 0.9, 0.5, 1 - t))
		"tesla":
			var pts2 = PoolVector2Array()
			for p in points:
				pts2.append(p - position)
			draw_polyline(pts2, Color(0.35, 0.7, 1.0, 1 - t), 6.0)
			draw_polyline(pts2, Color(0.9, 0.98, 1.0, 1 - t), 2.5)
			draw_circle(b - position, 10 * (1 - t), Color(0.7, 0.9, 1.0, 0.8))
		"puff":
			draw_circle(Vector2.ZERO, 3 + 6 * t, Color(0.85, 0.8, 0.7, 0.5 * (1 - t)))
		"spice_cloud":
			for k in range(9):
				var dir = Vector2.RIGHT.rotated(k * TAU / 9 + k)
				draw_circle(dir * 70 * size * (0.4 + t), 50 * size * (0.6 + t * 0.6), Color(0.78, 0.16, 0.1, 0.45 * (1 - t)))
		"text":
			if font:
				var s = 2.0
				draw_set_transform(Vector2.ZERO, -0.12, Vector2(s, s))
				var w = font.get_string_size(text).x
				var p = Vector2(-w / 2, 0)
				for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)]:
					draw_string(font, p + o, text, Color(0.08, 0.05, 0.03, 1 - t * t))
				var c = color
				c.a = 1 - t * t
				draw_string(font, p, text, c)
