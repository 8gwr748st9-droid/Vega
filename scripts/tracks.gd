extends Node2D
# Vehicle tracks and footprints that fade from the sand. Freedom fighters never leave any.

const LIFE = 10.0
const MAX_MARKS = 1200

var scorches = []   # [position, radius, born_time]
var soft
var marks = []   # [position, angle, born_time, infantry]
var time = 0.0


const SCORCH_LIFE = 60.0


func _ready():
	soft = preload("res://scripts/particles.gd").make_soft_texture(64, 1.2)


func add_scorch(p, r):
	scorches.append([p, r, time])
	if scorches.size() > 60:
		scorches.pop_front()


func add_mark(p, angle, infantry):
	marks.append([p, angle, time, infantry])
	if marks.size() > MAX_MARKS:
		marks.pop_front()


func _process(delta):
	time += delta
	while marks.size() > 0 and time - marks[0][2] > LIFE:
		marks.pop_front()
	update()


func _draw():
	for sc in scorches:
		var a = 0.55 * clamp(1.0 - (time - sc[2]) / SCORCH_LIFE, 0.0, 1.0)
		draw_texture_rect(soft, Rect2(sc[0] - Vector2(sc[1], sc[1] * 0.8), Vector2(sc[1], sc[1] * 0.8) * 2.0), false, Color(0.06, 0.04, 0.03, a))
	for m in marks:
		var alpha = 0.28 * (1.0 - (time - m[2]) / LIFE)
		var col = Color(0.45, 0.28, 0.12, alpha)
		var side = Vector2(0, 1).rotated(m[1])
		var fwd = Vector2(1, 0).rotated(m[1])
		if m[3]:
			draw_circle(m[0] + side * 3, 1.8, col)
		else:
			for s in [-9, 9]:
				var c = m[0] + side * s
				draw_line(c - fwd * 6, c + fwd * 6, col, 4.0)
