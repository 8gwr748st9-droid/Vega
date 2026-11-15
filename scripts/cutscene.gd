extends CanvasLayer
# In-engine cutscenes: letterbox bars, speaking portrait, typed dialogue and camera pans.
# The game is paused while a cutscene plays.

signal finished

const UIStyle = preload("res://scripts/ui_style.gd")
const PortraitScript = preload("res://scripts/portrait.gd")
const Missions = preload("res://scripts/missions.gd")

var game
var active = false
var lines = []
var index = 0
var chars = 0.0
var root
var top_bar
var bottom_bar
var name_label
var text_label
var hint_label
var portrait
var tween


func _ready():
	layer = 50
	pause_mode = Node.PAUSE_MODE_PROCESS
	root = Control.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.theme = UIStyle.make_theme()
	root.visible = false
	add_child(root)

	top_bar = ColorRect.new()
	top_bar.color = Color(0, 0, 0)
	top_bar.anchor_right = 1
	top_bar.margin_bottom = 80
	root.add_child(top_bar)

	bottom_bar = ColorRect.new()
	bottom_bar.color = Color(0, 0, 0, 0.92)
	bottom_bar.anchor_top = 1
	bottom_bar.anchor_right = 1
	bottom_bar.anchor_bottom = 1
	bottom_bar.margin_top = -170
	root.add_child(bottom_bar)

	portrait = PortraitScript.new()
	portrait.rect_position = Vector2(30, -155)
	portrait.anchor_top = 1
	portrait.anchor_bottom = 1
	portrait.margin_left = 30
	portrait.margin_top = -160
	portrait.margin_right = 170
	portrait.margin_bottom = -20
	root.add_child(portrait)

	name_label = Label.new()
	name_label.anchor_top = 1
	name_label.anchor_bottom = 1
	name_label.margin_left = 200
	name_label.margin_top = -155
	name_label.rect_scale = Vector2(1.4, 1.4)
	name_label.add_color_override("font_color", UIStyle.ACCENT)
	root.add_child(name_label)

	text_label = Label.new()
	text_label.anchor_top = 1
	text_label.anchor_bottom = 1
	text_label.anchor_right = 1
	text_label.margin_left = 200
	text_label.margin_right = -60
	text_label.margin_top = -118
	text_label.margin_bottom = -30
	text_label.autowrap = true
	text_label.rect_scale = Vector2(1.15, 1.15)
	root.add_child(text_label)

	hint_label = Label.new()
	hint_label.text = "Click / Space: continue     Esc: skip"
	hint_label.anchor_left = 1
	hint_label.anchor_top = 1
	hint_label.anchor_right = 1
	hint_label.anchor_bottom = 1
	hint_label.margin_left = -300
	hint_label.margin_top = -26
	hint_label.add_color_override("font_color", Color(0.7, 0.65, 0.55))
	root.add_child(hint_label)

	tween = Tween.new()
	add_child(tween)


func play(new_lines):
	lines = new_lines
	index = 0
	active = true
	root.visible = true
	get_tree().paused = true
	_show_line()


func _show_line():
	var line = lines[index]
	name_label.text = line["who"].to_upper()
	text_label.text = line["text"]
	text_label.visible_characters = 0
	chars = 0.0
	portrait.faction = Missions.faction_of(line["who"])
	portrait.talking = true
	var focus = line.get("focus", null)
	if focus != null and game != null:
		var to = game.focus_point(focus) + Vector2(120, 60)
		tween.stop_all()
		tween.interpolate_property(game.camera, "position", game.camera.position, to, 1.6, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()


func _process(delta):
	if not active:
		return
	chars += delta * 45.0
	text_label.visible_characters = int(chars)
	if chars >= text_label.text.length():
		portrait.talking = false


func _input(event):
	if not active:
		return
	var advance = false
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		advance = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_ESCAPE:
			_finish()
			get_tree().set_input_as_handled()
			return
		if event.scancode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			advance = true
	if advance:
		get_tree().set_input_as_handled()
		if chars < text_label.text.length():
			chars = text_label.text.length()
		else:
			index += 1
			if index >= lines.size():
				_finish()
			else:
				_show_line()


func _finish():
	active = false
	root.visible = false
	get_tree().paused = false
	emit_signal("finished")
