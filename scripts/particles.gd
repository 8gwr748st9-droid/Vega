extends Node2D
# Lightweight particle layer. One node draws every particle of one blend type in a single _draw,
# which is far cheaper on old integrated graphics than hundreds of separate nodes.
# Two instances are used: additive (fire, sparks, glow) and normal (smoke, dust).

const MAX = 900

var tex
var parts = []   # [pos, vel, age, life, size0, size1, col0, col1, drag, gravity_y, rot, spin]


static func make_soft_texture(size = 64, hardness = 1.6):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	img.lock()
	var c = (size - 1) / 2.0
	for y in range(size):
		for x in range(size):
			var d = Vector2(x - c, y - c).length() / c
			var a = pow(clamp(1.0 - d, 0.0, 1.0), hardness)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.unlock()
	var t = ImageTexture.new()
	t.create_from_image(img, Texture.FLAG_FILTER)
	return t


func setup(additive):
	tex = make_soft_texture()
	if additive:
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m


func emit(pos, vel, life, size0, size1, col0, col1, drag = 1.5, gravity_y = 0.0):
	if parts.size() >= MAX:
		parts.pop_front()
	parts.append([pos, vel, 0.0, life, size0, size1, col0, col1, drag, gravity_y])


func _process(delta):
	if parts.empty():
		return
	var alive = []
	for p in parts:
		p[2] += delta
		if p[2] >= p[3]:
			continue
		p[1] = p[1] * max(0.0, 1.0 - p[8] * delta) + Vector2(0, p[9] * delta)
		p[0] += p[1] * delta
		alive.append(p)
	parts = alive
	update()


func _draw():
	for p in parts:
		var t = p[2] / p[3]
		var s = lerp(p[4], p[5], t)
		var c = p[6].linear_interpolate(p[7], t)
		draw_texture_rect(tex, Rect2(p[0] - Vector2(s, s), Vector2(s, s) * 2.0), false, c)
