extends Control
# Placeholder comic portrait drawn in code. Replace with painted art later.

var faction = "arthem"
var talking = false
var t = 0.0


func _process(delta):
	t += delta
	update()


func _draw():
	var ink = Color("#1d130c")
	var c = rect_size / 2
	var r = min(rect_size.x, rect_size.y) / 2 - 4
	var col = Data.faction_color(faction)
	draw_circle(c, r + 3, ink)
	draw_circle(c, r, col.darkened(0.35))
	# Halftone dots for a printed-comic feel.
	for y in range(6):
		for x in range(6):
			var p = c + Vector2(x - 2.5, y - 2.5) * r * 0.32
			if p.distance_to(c) < r - 6:
				draw_circle(p, 2.0, col.darkened(0.5))
	var skin = Color("#e2b48a")
	var head = c + Vector2(0, 6)
	draw_circle(c + Vector2(0, r * 0.9), r * 0.55, ink)
	draw_circle(c + Vector2(0, r * 0.9), r * 0.52, col)
	draw_circle(head, r * 0.42, ink)
	draw_circle(head, r * 0.39, skin)
	match faction:
		"arthem":
			draw_rect(Rect2(head + Vector2(-r * 0.4, -r * 0.3), Vector2(r * 0.8, 6)), col)
			draw_circle(head + Vector2(0, -r * 0.28), 4, Color("#f0b54a"))
		"klingos":
			draw_colored_polygon(PoolVector2Array([head + Vector2(-r * 0.42, -r * 0.05), head + Vector2(0, -r * 0.62), head + Vector2(r * 0.42, -r * 0.05)]), col.darkened(0.2))
			for k in [-1, 0, 1]:
				draw_line(head + Vector2(k * r * 0.2, -r * 0.4), head + Vector2(k * r * 0.3, -r * 0.75), ink, 3.0)
		"freedom":
			draw_arc(head, r * 0.45, PI, TAU, 12, Color("#c9a46a"), 10.0)
			draw_rect(Rect2(head + Vector2(-r * 0.32, -r * 0.12), Vector2(r * 0.64, 9)), ink)
			draw_rect(Rect2(head + Vector2(-r * 0.4, r * 0.12), Vector2(r * 0.8, r * 0.25)), Color("#c9a46a"))
		"khan":
			for k in range(5):
				var x = -r * 0.36 + k * r * 0.18
				draw_colored_polygon(PoolVector2Array([head + Vector2(x - 5, -r * 0.32), head + Vector2(x, -r * 0.6), head + Vector2(x + 5, -r * 0.32)]), Color("#f0c43a"))
	if faction != "freedom":
		draw_circle(head + Vector2(-r * 0.15, -r * 0.03), 3, ink)
		draw_circle(head + Vector2(r * 0.15, -r * 0.03), 3, ink)
	var open = abs(sin(t * 14.0)) * 6 if talking else 1.0
	if faction != "freedom":
		draw_rect(Rect2(head + Vector2(-6, r * 0.18), Vector2(12, 2 + open)), ink)
