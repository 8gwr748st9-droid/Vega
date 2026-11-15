extends Sprite
# GPU terrain. A 64x64 data texture (rock + Uralium per cell) is stretched over the map and
# shaded by shaders/terrain.shader. Uralium changes are written back into the texture.

const TerrainShader = preload("res://shaders/terrain.shader")

var map
var img
var tex
var dirty_cells = {}
var timer = 0.0


func setup(m):
	map = m
	centered = false
	img = Image.new()
	img.create(map.W, map.H, false, Image.FORMAT_RGBA8)
	img.lock()
	for y in range(map.H):
		for x in range(map.W):
			img.set_pixel(x, y, _cell_color(Vector2(x, y)))
	img.unlock()
	tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_FILTER)
	texture = tex
	scale = Vector2(map.CELL, map.CELL)

	var mat = ShaderMaterial.new()
	mat.shader = TerrainShader
	mat.set_shader_param("noise_big", _noise_tex(512, 7, 128.0, 5))
	mat.set_shader_param("noise_fine", _noise_tex(256, 11, 24.0, 3))
	mat.set_shader_param("map_px", map.world_size())
	mat.set_shader_param("data_tex", tex)
	material = mat


func _noise_tex(size, seed_value, period, octaves):
	var n = OpenSimplexNoise.new()
	n.seed = seed_value
	n.period = period
	n.octaves = octaves
	n.persistence = 0.5
	# Build the image ourselves (NoiseTexture generates in a thread, which can leave it blank at start).
	var im = n.get_seamless_image(size)
	var t = ImageTexture.new()
	t.create_from_image(im, Texture.FLAG_FILTER | Texture.FLAG_REPEAT | Texture.FLAG_MIPMAPS)
	return t


func _cell_color(c):
	var rock = 1.0 if map.get_type(c) == map.ROCK else 0.0
	var ur = clamp(map.uralium_at(c) / 700.0, 0.0, 1.0)
	return Color(rock, ur, 0, 1)


func mark_dirty(c):
	dirty_cells[c] = true


func _process(delta):
	timer -= delta
	if timer > 0 or dirty_cells.empty():
		return
	timer = 0.4
	img.lock()
	for c in dirty_cells.keys():
		img.set_pixel(int(c.x), int(c.y), _cell_color(c))
	img.unlock()
	dirty_cells.clear()
	tex.set_data(img)
