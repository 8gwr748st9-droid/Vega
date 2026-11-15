extends Node2D
# Procedural desert map: sand, rock plateaus, uralium fields and pressurised uralium blooms.
# Terrain is drawn once (cached by the renderer); uralium is a separate layer redrawn when it changes.

const TerrainScript = preload("res://scripts/terrain.gd")

const CELL = 64
const W = 64
const H = 64

enum { SAND, ROCK }

const SAND_COLORS = [Color("#d99c55"), Color("#e6ae66"), Color("#efc07a"), Color("#f6d08f")]
const ROCK_COLORS = [Color("#6f4630"), Color("#835539"), Color("#946446")]
const OUTLINE = Color("#2b1a10")

var terrain = PoolIntArray()
var shade = PoolRealArray()
var uralium = {}          # Vector2 cell -> amount
var bloom_cells = []    # Vector2 cells holding pressurised uralium
var occupied = {}       # Vector2 cell -> building
var bases = []          # base centre cells (index = start slot)
var ground
var rng = RandomNumberGenerator.new()


func generate(seed_value):
	rng.seed = seed_value
	terrain.resize(W * H)
	shade.resize(W * H)

	var n_rock = OpenSimplexNoise.new()
	n_rock.seed = seed_value
	n_rock.octaves = 3
	n_rock.period = 14.0
	n_rock.persistence = 0.5

	var n_uralium = OpenSimplexNoise.new()
	n_uralium.seed = seed_value + 17
	n_uralium.octaves = 2
	n_uralium.period = 8.0

	var n_dune = OpenSimplexNoise.new()
	n_dune.seed = seed_value + 99
	n_dune.octaves = 2
	n_dune.period = 6.0

	bases = [Vector2(9, 9), Vector2(W - 10, H - 10)]

	for y in range(H):
		for x in range(W):
			var i = y * W + x
			var v = n_rock.get_noise_2d(x, y)
			terrain[i] = ROCK if v > 0.30 else SAND
			shade[i] = n_dune.get_noise_2d(x, y)

	# Guaranteed rock plateaus for both bases.
	for b in bases:
		for y in range(int(b.y) - 9, int(b.y) + 10):
			for x in range(int(b.x) - 9, int(b.x) + 10):
				if not in_bounds(Vector2(x, y)):
					continue
				var d = Vector2(x, y).distance_to(b)
				var jitter = n_rock.get_noise_2d(x * 3.0, y * 3.0) * 2.0
				if d < 7.0 + jitter:
					terrain[y * W + x] = ROCK

	# Uralium fields on open sand.
	for y in range(H):
		for x in range(W):
			var c = Vector2(x, y)
			if terrain[y * W + x] != SAND or _near_base(c, 8.0):
				continue
			var s = n_uralium.get_noise_2d(x, y)
			if s > 0.22:
				uralium[c] = int(200 + s * 900)

	# A guaranteed field near each base, towards the map centre.
	var centre = Vector2(W / 2, H / 2)
	for b in bases:
		var field = b + (centre - b).normalized() * 12.0
		_paint_field(field.round(), 4.0, 550)

	# Pressurised uralium blooms.
	var tries = 0
	while bloom_cells.size() < 12 and tries < 2000:
		tries += 1
		var c = Vector2(rng.randi_range(3, W - 4), rng.randi_range(3, H - 4))
		if get_type(c) != SAND or _near_base(c, 16.0) or uralium.has(c):
			continue
		var too_close = false
		for o in bloom_cells:
			if o.distance_to(c) < 7:
				too_close = true
				break
		if not too_close:
			bloom_cells.append(c)

	ground = TerrainScript.new()
	add_child(ground)
	ground.setup(self)


func _near_base(c, r):
	for b in bases:
		if c.distance_to(b) < r:
			return true
	return false


func _paint_field(centre, r, amount):
	for y in range(int(centre.y - r), int(centre.y + r) + 1):
		for x in range(int(centre.x - r), int(centre.x + r) + 1):
			var c = Vector2(x, y)
			if not in_bounds(c) or c.distance_to(centre) > r + rng.randf() * 0.8:
				continue
			if _near_base(c, 7.5):
				continue
			terrain[y * W + x] = SAND
			uralium[c] = amount + rng.randi_range(-80, 120)


# ---------------------------------------------------------------- queries

func world_size():
	return Vector2(W * CELL, H * CELL)


func cell_of(p):
	return Vector2(floor(p.x / CELL), floor(p.y / CELL))


func center_of(c):
	return c * CELL + Vector2(CELL / 2, CELL / 2)


func in_bounds(c):
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func get_type(c):
	if not in_bounds(c):
		return ROCK
	return terrain[int(c.y) * W + int(c.x)]


func is_sand_at(p):
	return get_type(cell_of(p)) == SAND


func is_rock_at(p):
	return get_type(cell_of(p)) == ROCK


func uralium_at(c):
	return uralium.get(c, 0)


func take_uralium(c, amount):
	if not uralium.has(c):
		return 0
	var taken = min(amount, uralium[c])
	uralium[c] -= taken
	if uralium[c] <= 0.5:
		uralium.erase(c)
	ground.mark_dirty(c)
	return taken


func add_uralium(c, amount):
	if get_type(c) != SAND:
		return
	uralium[c] = uralium.get(c, 0) + amount
	ground.mark_dirty(c)


func find_uralium(near_pos, exclude = []):
	var best = null
	var best_d = INF
	for c in uralium.keys():
		if c in exclude:
			continue
		var d = center_of(c).distance_squared_to(near_pos)
		if d < best_d:
			best_d = d
			best = c
	return best


func clamp_to_map(p):
	return Vector2(clamp(p.x, 8, W * CELL - 8), clamp(p.y, 8, H * CELL - 8))


# ---------------------------------------------------------------- drawing

func _cell_hash(x, y, k = 0):
	var h = int(x) * 73856093 ^ int(y) * 19349663 ^ k * 83492791
	return abs(h % 1000) / 1000.0


func make_minimap_image(size):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	img.lock()
	for py in range(size):
		for px in range(size):
			var c = Vector2(floor(px * W / float(size)), floor(py * H / float(size)))
			var col = SAND_COLORS[1] if get_type(c) == SAND else ROCK_COLORS[0]
			if uralium.has(c):
				col = Color("#b8382c")
			img.set_pixel(px, py, col)
	img.unlock()
	return img
