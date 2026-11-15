extends Control
# Minimap: terrain thumbnail, unit/building dots, camera frame. Click or drag to move the camera.

var game
var tex
var redraw = 0.0
var spice_refresh = 0.0


func _ready():
	_rebuild_texture()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _rebuild_texture():
	tex = ImageTexture.new()
	tex.create_from_image(game.map.make_minimap_image(128), 0)


func _process(delta):
	redraw -= delta
	spice_refresh -= delta
	if spice_refresh <= 0:
		spice_refresh = 10.0
		_rebuild_texture()
	if redraw <= 0:
		redraw = 0.25
		update()


func _to_mini(p):
	return p / game.map.world_size() * rect_size


func _draw():
	draw_texture_rect(tex, Rect2(Vector2.ZERO, rect_size), false)
	for b in get_tree().get_nodes_in_group("buildings"):
		var r = Rect2(_to_mini(b.position) - Vector2(3, 3), Vector2(6, 6))
		draw_rect(r, b.team_color())
	for u in get_tree().get_nodes_in_group("units"):
		draw_rect(Rect2(_to_mini(u.position) - Vector2(1.5, 1.5), Vector2(3, 3)), u.team_color().lightened(0.3))
	var vp = game.get_viewport().get_visible_rect().size * game.camera.zoom
	var cam = Rect2(_to_mini(game.camera.position - vp / 2), _to_mini(vp))
	draw_rect(cam, Color(1, 1, 1, 0.9), false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color("#1d130c"), false, 3.0)


func _gui_input(event):
	var go = false
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		go = true
	elif event is InputEventMouseMotion and event.button_mask & BUTTON_MASK_LEFT:
		go = true
	if go:
		game.camera.position = event.position / rect_size * game.map.world_size()
		accept_event()
