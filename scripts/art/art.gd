extends Node
# Autoload "Art": pre-renders every unit and building with the 2.5D painter into texture atlases.
#  - Units: 32 rotations each (hull and turret separately) so sunlight stays correct when they turn.
#  - Rendered at 2x then shrunk, which gives smooth anti-aliased edges.
#  - Results are cached in user:// so later launches start quickly.
# Later, real painted sprites can be dropped into res://art/sprites/<id>.png to replace any part.

signal progress(fraction)
signal finished

const PainterScript = preload("res://scripts/art/painter.gd")
const DesignsScript = preload("res://scripts/art/designs.gd")

const VERSION = "5"
const FRAMES = 32
const COLS = 8
const SS = 2

var parts = {}           # id -> {"tex": Texture, "cell": Vector2, "frames": int}
var is_ready = false
var building = false
var use_cache = true
var designs = DesignsScript.new()


func headless():
	return OS.get_name() == "Server" or OS.has_feature("Server")


func build():
	if is_ready or building:
		return
	building = true
	if headless():
		is_ready = true
		building = false
		call_deferred("emit_signal", "finished")
		return
	call_deferred("_build")


func _jobs():
	var jobs = []
	for kind in Data.UNITS.keys():
		var d = Data.UNITS[kind]
		var pal = designs.PALETTES[d["faction"]]
		var spec = designs.unit_parts(kind, d["shape"], d.get("radius", 10))
		var cell = Vector2(spec[2], spec[2])
		jobs.append({"id": kind + "/hull", "fn": spec[0], "args": [pal], "frames": FRAMES, "cell": cell, "scale": spec[3]})
		if spec[1] != "":
			jobs.append({"id": kind + "/turret", "fn": spec[1], "args": [pal], "frames": FRAMES, "cell": cell, "scale": spec[3]})
	for kind in Data.BUILDINGS.keys():
		var b = Data.BUILDINGS[kind]
		var factions = ["arthem", "klingos", "khan"] if b["faction"] == "any" else [b["faction"]]
		var size = b["size"] * Data.CELL
		for f in factions:
			var pal2 = designs.PALETTES[f]
			# Extra room around the footprint for height (up) and cast shadow (down-right).
			jobs.append({"id": kind + "/" + f, "fn": designs.building_func(kind), "args": [pal2, size], "frames": 1, "cell": size + Vector2(110, 150), "scale": 1.0, "offset": Vector2(-18, 42)})
			if kind == "gun_tower":
				jobs.append({"id": "gun_tower/turret/" + f, "fn": "gun_turret", "args": [pal2], "frames": FRAMES, "cell": Vector2(64, 64), "scale": 1.0})
			if kind == "orbital_uplink":
				jobs.append({"id": "orbital_uplink/dish/" + f, "fn": "uplink_dish", "args": [pal2], "frames": FRAMES, "cell": Vector2(80, 80), "scale": 1.0})
	return jobs


func _cache_path(id):
	return "user://art_cache_v%s/%s.png" % [VERSION, id.replace("/", "_")]


func _build():
	var vp = Viewport.new()
	vp.transparent_bg = true
	vp.hdr = false
	vp.usage = Viewport.USAGE_2D
	vp.render_target_v_flip = true
	vp.render_target_update_mode = Viewport.UPDATE_ALWAYS
	vp.size = Vector2(64, 64)
	add_child(vp)
	var painter = PainterScript.new()
	vp.add_child(painter)
	var dir = Directory.new()
	dir.make_dir_recursive("user://art_cache_v%s" % VERSION)

	var jobs = _jobs()
	for i in range(jobs.size()):
		var job = jobs[i]
		var img = null
		var override = "res://art/sprites/%s.png" % job["id"].replace("/", "_")
		if ResourceLoader.exists(override):
			img = load(override).get_data()
		elif use_cache and File.new().file_exists(_cache_path(job["id"])):
			img = Image.new()
			if img.load(_cache_path(job["id"])) != OK:
				img = null
		if img == null:
			var frames = job["frames"]
			var cols = COLS if frames > 1 else 1
			var rows = int(ceil(frames / float(cols)))
			var cell2 = job["cell"] * SS
			vp.size = Vector2(cols * cell2.x, rows * cell2.y)
			var cells = []
			for f in range(frames):
				var centre = Vector2((f % cols + 0.5) * cell2.x, (f / cols + 0.5) * cell2.y)
				cells.append([centre, f * TAU / frames])
			painter.sc = SS * job["scale"]
			painter.offset = job.get("offset", Vector2.ZERO)
			painter.job = {"cells": cells, "draw": funcref(designs, job["fn"]), "args": job["args"]}
			painter.update()
			yield(VisualServer, "frame_post_draw")
			yield(VisualServer, "frame_post_draw")
			img = vp.get_texture().get_data()
			if img == null or img.is_empty():
				continue
			img.convert(Image.FORMAT_RGBA8)
			img.shrink_x2()
			if use_cache:
				img.save_png(_cache_path(job["id"]))
		var tex = ImageTexture.new()
		tex.create_from_image(img, Texture.FLAG_FILTER | Texture.FLAG_MIPMAPS)
		parts[job["id"]] = {"tex": tex, "cell": job["cell"], "frames": job["frames"], "offset": job.get("offset", Vector2.ZERO)}
		emit_signal("progress", float(i + 1) / jobs.size())
	vp.queue_free()
	is_ready = true
	building = false
	emit_signal("finished")


# ---------------------------------------------------------------- drawing API

func has(id):
	return parts.has(id)


func draw_part(ci, id, angle, pos = Vector2.ZERO, modulate = Color(1, 1, 1, 1), scale = Vector2.ONE):
	var p = parts.get(id)
	if p == null:
		return false
	var frames = p["frames"]
	var cell = p["cell"]
	var idx = 0
	var resid = angle
	if frames > 1:
		var a = fposmod(angle, TAU)
		idx = int(round(a / TAU * frames)) % frames
		resid = a - idx * TAU / frames
	var cols = COLS if frames > 1 else 1
	var region = Rect2((idx % cols) * cell.x, (idx / cols) * cell.y, cell.x, cell.y)
	ci.draw_set_transform(pos - p["offset"] * scale, resid, scale)
	ci.draw_texture_rect_region(p["tex"], Rect2(-cell / 2, cell), region, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	return true


func draw_shadow(ci, id, angle, pos, offset, alpha = 0.3, scale = Vector2.ONE):
	# Soft shadow: the silhouette drawn dark a few times with small offsets.
	for o in [Vector2(0, 0), Vector2(1.5, 1.0), Vector2(-1.0, 1.5)]:
		draw_part(ci, id, angle, pos + offset + o, Color(0.05, 0.03, 0.02, alpha * 0.45), scale)


func icon_texture(id):
	# Single frame (facing up-right) used for sidebar buttons.
	var p = parts.get(id)
	if p == null:
		return null
	var at = AtlasTexture.new()
	at.atlas = p["tex"]
	var frames = p["frames"]
	var idx = int(frames * 7 / 8) % frames if frames > 1 else 0
	var cols = COLS if frames > 1 else 1
	at.region = Rect2((idx % cols) * p["cell"].x, (idx / cols) * p["cell"].y, p["cell"].x, p["cell"].y)
	return at
