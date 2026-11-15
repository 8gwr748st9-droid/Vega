extends Node2D
# Draws red Uralium ore speckles with metallic glints. Redrawn at most twice per second when uralium changes.

const COLORS = [Color("#8e1b10"), Color("#c0392b"), Color("#e2553f")]

var map
var dirty = false
var timer = 0.0


func mark_dirty():
	dirty = true


func _process(delta):
	timer -= delta
	if dirty and timer <= 0.0:
		dirty = false
		timer = 0.5
		update()


func _draw():
	var cell = map.CELL
	for c in map.uralium.keys():
		var amount = map.uralium[c]
		var dots = int(clamp(amount / 60.0, 1, 12))
		var o = c * cell
		draw_rect(Rect2(o, Vector2(cell, cell)), Color(0.7, 0.15, 0.1, clamp(amount / 2500.0, 0.05, 0.25)))
		for k in range(dots):
			var hx = map._cell_hash(c.x, c.y, 10 + k)
			var hy = map._cell_hash(c.x, c.y, 40 + k)
			var p = o + Vector2(4 + hx * (cell - 8), 4 + hy * (cell - 8))
			var r = 3.0 + map._cell_hash(c.x, c.y, 70 + k) * 3.0
			draw_circle(p, r, COLORS[k % 3])
			if k % 3 == 0:
				# Metallic glint.
				draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.35, Color(1, 0.85, 0.8, 0.85))
