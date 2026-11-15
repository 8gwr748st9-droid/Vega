extends Node2D
# Draws the selection box, building placement preview and order markers on top of the world.

var game


func _process(_delta):
	update()


func _draw():
	if game.drag_start != null and game.drag_start.distance_to(game.drag_now) >= 8:
		var r = Rect2(game.drag_start, Vector2.ZERO).expand(game.drag_now)
		draw_rect(r, Color(0.4, 1, 0.4, 0.12))
		draw_rect(r, Color(0.4, 1, 0.4, 0.9), false, 2.0)
	if game.placing != "":
		var d = Data.get_def(game.placing)
		var cell = game.placement_cell(get_global_mouse_position())
		var ok = game.can_place(game.player_team, game.placing, cell)
		var col = Color(0.3, 1, 0.4, 0.35) if ok else Color(1, 0.25, 0.2, 0.35)
		for y in range(int(d["size"].y)):
			for x in range(int(d["size"].x)):
				var c = cell + Vector2(x, y)
				var r2 = Rect2(c * Data.CELL, Vector2(Data.CELL, Data.CELL))
				draw_rect(r2, col)
				draw_rect(r2, Color(0, 0, 0, 0.6), false, 2.0)
	if game.targeting == "orbital":
		var m = get_global_mouse_position()
		var t = OS.get_ticks_msec() / 1000.0
		draw_arc(m, 130, 0, TAU, 32, Color(0.55, 0.9, 1.0, 0.9), 3.0)
		draw_arc(m, 300, 0, TAU, 48, Color(0.55, 0.9, 1.0, 0.3 + 0.2 * sin(t * 6)), 2.0)
		draw_line(m - Vector2(20, 0), m + Vector2(20, 0), Color(0.55, 0.9, 1.0), 2.0)
		draw_line(m - Vector2(0, 20), m + Vector2(0, 20), Color(0.55, 0.9, 1.0), 2.0)
	if game.order_marker != null:
		var p = game.order_marker[0]
		var t = game.order_marker[1] / 0.6
		draw_arc(p, 6 + 18 * t, 0, TAU, 16, game.order_marker[2] * Color(1, 1, 1, 1 - t), 3.0)
