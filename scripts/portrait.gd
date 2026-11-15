extends Control
# Comm-link portrait: a rim-lit silhouette in faction colours with scan lines and a voice meter.
# Stands in until painted character portraits exist (drop them in and draw a texture here).

var faction = "arthem"
var talking = false
var t = 0.0


func _process(delta):
	t += delta
	update()


func _draw():
	var s = rect_size
	var col = Data.faction_color(faction)
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.05, 0.06, 0.95))
	# backdrop glow
	for i in range(8):
		var k = i / 8.0
		draw_circle(Vector2(s.x * 0.5, s.y * 0.45), s.x * 0.55 * (1.0 - k), Color(col.r, col.g, col.b, 0.045))
	var c = Vector2(s.x * 0.5, s.y * 0.40)
	var r = s.x * 0.20
	var dark = Color(0.07, 0.08, 0.10)
	# shoulders and neck
	var sh = PoolVector2Array([Vector2(s.x * 0.08, s.y), Vector2(s.x * 0.16, s.y * 0.74), Vector2(s.x * 0.38, s.y * 0.64), Vector2(s.x * 0.62, s.y * 0.64), Vector2(s.x * 0.84, s.y * 0.74), Vector2(s.x * 0.92, s.y)])
	draw_colored_polygon(sh, dark)
	draw_polyline(PoolVector2Array([sh[1], sh[2]]), col.lightened(0.2), 2.0, true)
	draw_polyline(PoolVector2Array([sh[0], sh[1]]), col, 2.0, true)
	draw_rect(Rect2(c + Vector2(-r * 0.45, r * 0.7), Vector2(r * 0.9, r * 0.9)), dark)
	# head with a rim light on the sun side
	draw_circle(c, r, col.lightened(0.25))
	draw_circle(c + Vector2(r * 0.12, r * 0.06), r * 0.97, dark)
	match faction:
		"klingos":
			draw_colored_polygon(PoolVector2Array([c + Vector2(-r * 1.1, -r * 0.1), c + Vector2(0, -r * 1.45), c + Vector2(r * 1.1, -r * 0.1)]), dark)
			draw_line(c + Vector2(-r * 1.1, -r * 0.1), c + Vector2(0, -r * 1.45), col, 2.0, true)
			draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.05), Vector2(r * 1.4, 4)), Color(col.r, col.g, col.b, 0.9))
		"freedom":
			draw_arc(c, r * 1.15, PI * 0.9, PI * 2.1, 20, dark, r * 0.5, true)
			draw_arc(c, r * 1.38, PI * 1.0, PI * 1.5, 12, col, 2.0, true)
			draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.2), Vector2(r * 1.5, 6)), Color(col.r, col.g, col.b, 0.8))
		"khan":
			for k in range(5):
				var x = -r * 0.8 + k * r * 0.4
				draw_colored_polygon(PoolVector2Array([c + Vector2(x - 6, -r * 0.85), c + Vector2(x, -r * 1.5), c + Vector2(x + 6, -r * 0.85)]), col.lightened(0.2))
		_:
			draw_rect(Rect2(c + Vector2(-r * 1.0, -r * 0.55), Vector2(r * 2.0, 5)), Color(col.r, col.g, col.b, 0.9))
	# scan lines
	var y = 0.0
	while y < s.y:
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(0, 0, 0, 0.22), 1.0)
		y += 3.0
	var sweep = fmod(t * 40.0, s.y + 40.0) - 20.0
	draw_rect(Rect2(0, sweep, s.x, 14), Color(col.r, col.g, col.b, 0.06))
	# voice meter
	for i in range(9):
		var h = 3.0
		if talking:
			h = 4.0 + abs(sin(t * (9.0 + i * 1.7) + i)) * 14.0
		draw_rect(Rect2(s.x * 0.5 - 40 + i * 9, s.y - 8 - h, 5, h), Color(col.r, col.g, col.b, 0.85))
	draw_rect(Rect2(Vector2.ZERO, s), Color(col.r, col.g, col.b, 0.55), false, 1.5)
