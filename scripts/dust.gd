extends Node2D
# Drifting dust cloud. Cosmetic only. (It never rains on Vega.)

var vel = Vector2(45, 12)
var life = 26.0
var age = 0.0
var puffs = []


func setup(p, wind):
	position = p
	vel = wind
	for i in range(12):
		puffs.append([Vector2(rand_range(-160, 160), rand_range(-60, 60)), rand_range(40, 90), randf() * TAU])


func _process(delta):
	age += delta
	position += vel * delta
	if age >= life:
		queue_free()
		return
	update()


func _draw():
	var fade = min(1.0, min(age / 4.0, (life - age) / 4.0))
	for p in puffs:
		var wob = Vector2(sin(age * 0.7 + p[2]), cos(age * 0.5 + p[2])) * 10
		draw_circle(p[0] + wob, p[1], Color(0.93, 0.78, 0.55, 0.12 * fade))
