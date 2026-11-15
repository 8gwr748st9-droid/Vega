extends Control
# Main menu with a drawn desert backdrop: campaign, skirmish, difficulty, controls.

const UIStyle = preload("res://scripts/ui_style.gd")
const Missions = preload("res://scripts/missions.gd")

var t = 0.0
var main_box
var campaign_box
var diff_button
var help_panel
var font


func _ready():
	anchor_right = 1
	anchor_bottom = 1
	theme = UIStyle.make_theme()
	get_tree().paused = false
	var tmp = Label.new()
	font = tmp.get_font("font")
	tmp.free()

	main_box = VBoxContainer.new()
	main_box.anchor_left = 0.5
	main_box.anchor_top = 0.5
	main_box.margin_left = -160
	main_box.margin_top = -40
	main_box.margin_right = 160
	main_box.add_constant_override("separation", 10)
	add_child(main_box)

	_btn(main_box, "Campaign", "_show_campaign")
	_btn(main_box, "Skirmish - play as Arthems", "_skirmish", ["arthem", "klingos"])
	_btn(main_box, "Skirmish - play as Klingos", "_skirmish", ["klingos", "arthem"])
	diff_button = _btn(main_box, "", "_cycle_difficulty")
	_btn(main_box, "Controls", "_toggle_help")
	_btn(main_box, "Quit", "_quit")
	_update_diff()

	campaign_box = PanelContainer.new()
	campaign_box.anchor_left = 0.5
	campaign_box.anchor_top = 0.5
	campaign_box.margin_left = -330
	campaign_box.margin_top = -200
	campaign_box.margin_right = 330
	campaign_box.margin_bottom = 260
	campaign_box.visible = false
	add_child(campaign_box)
	var cv = VBoxContainer.new()
	cv.add_constant_override("separation", 6)
	campaign_box.add_child(cv)
	var head = Label.new()
	head.text = "THE LIBERATION OF VEGA"
	head.align = Label.ALIGN_CENTER
	head.add_color_override("font_color", UIStyle.ACCENT)
	cv.add_child(head)
	for m in Missions.MISSIONS:
		var b = Button.new()
		var unlocked = m["id"] <= GameState.unlocked_missions
		var label = "%d.  %s" % [m["id"], m["title"]]
		if not m["playable"]:
			label += "   (in development)"
		elif not unlocked:
			label += "   (locked)"
		b.text = label
		b.align = Button.ALIGN_LEFT
		b.hint_tooltip = m["briefing"]
		b.disabled = not (m["playable"] and unlocked)
		b.connect("pressed", self, "_start_mission", [m["id"]])
		cv.add_child(b)
	_btn(cv, "Back", "_show_main")

	help_panel = PanelContainer.new()
	help_panel.anchor_left = 0.5
	help_panel.anchor_top = 0.5
	help_panel.margin_left = -300
	help_panel.margin_top = -170
	help_panel.margin_right = 300
	help_panel.visible = false
	add_child(help_panel)
	var hv = VBoxContainer.new()
	help_panel.add_child(hv)
	var hl = Label.new()
	hl.text = """CONTROLS
Left-click / drag ........ select units
Right-click .............. move / attack / harvest Uralium
Ctrl or Option + right-click .. attack-move
Q ........ select whole army      X ........ stop
H ........ jump to base           P ........ pause
WASD / arrows / screen edges / two-finger swipe .. scroll
Mouse wheel / pinch ...... zoom
Sidebar: build structures, then click READY to place on rock.

TIPS
Sandeaters guard their Uralium fields and swallow anything
moving on the sand. Rock is safe. They vanish after feeding
but always come back.
Red mounds are pressurised Uralium - touching one sets it off."""
	hv.add_child(hl)
	_btn(hv, "Close", "_toggle_help")


func _btn(parent, text, method, args = []):
	var b = Button.new()
	b.text = text
	b.rect_min_size = Vector2(320, 42)
	b.connect("pressed", self, method, args)
	parent.add_child(b)
	return b


func _update_diff():
	diff_button.text = "Difficulty: %s" % GameState.difficulty_name()


func _cycle_difficulty():
	GameState.difficulty = (GameState.difficulty + 1) % 3
	GameState.save_progress()
	_update_diff()


func _toggle_help():
	help_panel.visible = not help_panel.visible
	main_box.visible = not help_panel.visible


func _show_campaign():
	main_box.visible = false
	campaign_box.visible = true


func _show_main():
	main_box.visible = true
	campaign_box.visible = false


func _skirmish(player, enemy):
	GameState.mode = "skirmish"
	GameState.player_faction = player
	GameState.enemy_faction = enemy
	get_tree().change_scene("res://scenes/Game.tscn")


func _start_mission(n):
	GameState.mode = "campaign"
	GameState.mission = n
	GameState.player_faction = "arthem"
	GameState.enemy_faction = "klingos"
	get_tree().change_scene("res://scenes/Game.tscn")


func _quit():
	get_tree().quit()


func _process(delta):
	t += delta
	update()


func _draw():
	var s = rect_size
	# Sky bands (posterised, comic style).
	var sky = [Color("#2b1b3a"), Color("#5a2d47"), Color("#a3474a"), Color("#e07a4a"), Color("#f2b35c")]
	for i in range(sky.size()):
		draw_rect(Rect2(0, s.y * 0.11 * i, s.x, s.y * 0.11 + 1), sky[i])
	# Two suns.
	draw_circle(Vector2(s.x * 0.75, s.y * 0.36), 70, Color("#ffe7a3"))
	draw_circle(Vector2(s.x * 0.86, s.y * 0.30), 30, Color("#fff5d6"))
	# Dunes.
	var layers = [[0.58, Color("#c9823f")], [0.68, Color("#dc9a52")], [0.80, Color("#eab46a")]]
	for li in range(layers.size()):
		var y0 = s.y * layers[li][0]
		var pts = PoolVector2Array()
		pts.append(Vector2(0, s.y))
		for k in range(41):
			var x = s.x * k / 40.0
			pts.append(Vector2(x, y0 + sin(k * 0.45 + li * 1.7 + t * 0.05) * 22 + sin(k * 0.17 + li) * 30))
		pts.append(Vector2(s.x, s.y))
		draw_colored_polygon(pts, layers[li][1])
		var outline = PoolVector2Array()
		for k in range(1, pts.size() - 1):
			outline.append(pts[k])
		draw_polyline(outline, Color("#1d130c"), 3.0)
	# A sandeater breaching in the distance.
	var wx = s.x * 0.18
	var wy = s.y * 0.6
	var rise = 30 + sin(t * 0.8) * 10
	draw_arc(Vector2(wx, wy + 40), 60, PI * 1.05, PI * 1.95, 18, Color("#1d130c"), 26.0)
	draw_arc(Vector2(wx, wy + 40), 60, PI * 1.08, PI * 1.92, 18, Color("#8e6a48"), 18.0)
	draw_circle(Vector2(wx + 58, wy + 40 - rise * 0.2), 16, Color("#3a0f0a"))
	# Title.
	if font:
		var title = "V E G A"
		draw_set_transform(Vector2(s.x / 2, s.y * 0.2), -0.04, Vector2(5, 5))
		var w = font.get_string_size(title).x
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, -1)]:
			draw_string(font, Vector2(-w / 2, 0) + o, title, Color("#1d130c"))
		draw_string(font, Vector2(-w / 2, 0), title, Color("#f0b54a"))
		draw_set_transform(Vector2(s.x / 2, s.y * 0.2 + 40), 0, Vector2(1.6, 1.6))
		var sub = "The Uralium Wars"
		var w2 = font.get_string_size(sub).x
		draw_string(font, Vector2(-w2 / 2, 0), sub, Color("#fbeed5"))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
