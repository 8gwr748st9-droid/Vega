extends SceneTree
# Renders every pre-rendered part on a sand background and saves gallery PNGs.
# Usage: godot -s res://tests/gallery.gd -- <out_dir>

var out_dir = "user://gallery"
var board
var frames = 0
var built = false


class Board:
	extends Node2D
	var ids = []
	var page = 0
	var zoom = 3.0
	func _draw():
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.80, 0.64, 0.44))
		var art = get_node("/root/Art")
		var x = 50.0
		var y = 60.0
		var row_h = 0.0
		for id in ids:
			var p = art.parts[id]
			var cell = p["cell"] * zoom
			if x + cell.x > 1260:
				x = 50.0
				y += row_h + 26
				row_h = 0.0
			var c = Vector2(x + cell.x / 2, y + cell.y / 2)
			var ang = -0.5 if p["frames"] > 1 else 0.0
			art.draw_shadow(self, id, ang, c, Vector2(5, 6) * zoom, 0.3, Vector2(zoom, zoom))
			art.draw_part(self, id, ang, c, Color(1, 1, 1, 1), Vector2(zoom, zoom))
			x += cell.x + 14
			row_h = max(row_h, cell.y)


func _initialize():
	var args = OS.get_cmdline_args()
	var i = args.find("--")
	if i >= 0 and i + 1 < args.size():
		out_dir = args[i + 1]
	var art = root.get_node("Art")
	art.use_cache = false
	art.connect("finished", self, "_on_built")
	art.build()


func _on_built():
	built = true
	var art = root.get_node("Art")
	print("parts built: %d" % art.parts.size())
	var units = []
	var blds = []
	for id in art.parts.keys():
		if id.find("/hull") >= 0 or id.find("/turret") >= 0 or id.find("/dish") >= 0:
			units.append(id)
		else:
			blds.append(id)
	board = Board.new()
	board.ids = units
	root.add_child(board)
	board.set_meta("blds", blds)


func _idle(_d):
	if not built:
		return false
	frames += 1
	if frames == 5:
		_save("units")
		board.ids = board.get_meta("blds").slice(0, 7)
		board.zoom = 1.0
		board.update()
	if frames == 10:
		_save("buildings1")
		var b = board.get_meta("blds")
		board.ids = b.slice(8, b.size() - 1)
		board.zoom = 1.0
		board.update()
	if frames == 15:
		_save("buildings2")
		quit()
	return false


func _save(n):
	var img = root.get_texture().get_data()
	img.flip_y()
	Directory.new().make_dir_recursive(out_dir)
	img.save_png(out_dir + "/" + n + ".png")
	print("saved " + n)
