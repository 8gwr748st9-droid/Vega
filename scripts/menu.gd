extends Control
# Main menu: live desert backdrop (the real terrain shader), title, campaign, skirmish and settings.

const UIStyle = preload("res://scripts/ui_style.gd")
const Missions = preload("res://scripts/missions.gd")
const MapScript = preload("res://scripts/map.gd")

var t = 0.0
var backdrop
var main_box
var campaign_box
var help_panel
var diff_button
var gfx_button
var loading_label
var start_buttons = []


func _ready():
	anchor_right = 1
	anchor_bottom = 1
	theme = UIStyle.make_theme()
	get_tree().paused = false

	# Backdrop: a slowly drifting piece of real map.
	backdrop = MapScript.new()
	add_child(backdrop)
	backdrop.generate(4242)

	var shade = ColorRect.new()
	shade.anchor_right = 1
	shade.anchor_bottom = 1
	shade.color = Color(0.03, 0.02, 0.02, 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var band = ColorRect.new()
	band.anchor_bottom = 1
	band.margin_right = 470
	band.color = Color(0.03, 0.035, 0.045, 0.80)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)

	var title_font = UIStyle.font(120, "Bold")
	title_font.extra_spacing_char = 14
	var title = Label.new()
	title.text = "VEGA"
	title.add_font_override("font", title_font)
	title.add_color_override("font_color", UIStyle.ACCENT)
	title.margin_left = 56
	title.margin_top = 40
	add_child(title)
	var sub_font = UIStyle.font(24, "Medium")
	sub_font.extra_spacing_char = 6
	var sub = Label.new()
	sub.text = "THE URALIUM WARS"
	sub.add_font_override("font", sub_font)
	sub.add_color_override("font_color", UIStyle.TEXT)
	sub.margin_left = 62
	sub.margin_top = 170
	add_child(sub)

	main_box = VBoxContainer.new()
	main_box.margin_left = 60
	main_box.margin_top = 250
	main_box.margin_right = 410
	main_box.add_constant_override("separation", 8)
	add_child(main_box)
	start_buttons.append(_btn(main_box, "CAMPAIGN", "_show_campaign"))
	start_buttons.append(_btn(main_box, "SKIRMISH  -  ARTHEMS", "_skirmish", ["arthem", "klingos"]))
	start_buttons.append(_btn(main_box, "SKIRMISH  -  KLINGOS", "_skirmish", ["klingos", "arthem"]))
	diff_button = _btn(main_box, "", "_cycle_difficulty")
	gfx_button = _btn(main_box, "", "_toggle_graphics")
	_btn(main_box, "CONTROLS", "_toggle_help")
	_btn(main_box, "QUIT", "_quit")
	_update_settings()

	loading_label = UIStyle.label("", 16, UIStyle.TEXT_DIM)
	loading_label.anchor_top = 1
	loading_label.anchor_bottom = 1
	loading_label.margin_left = 62
	loading_label.margin_top = -40
	add_child(loading_label)

	campaign_box = PanelContainer.new()
	campaign_box.margin_left = 500
	campaign_box.margin_top = 60
	campaign_box.margin_right = 1160
	campaign_box.visible = false
	add_child(campaign_box)
	var cv = VBoxContainer.new()
	cv.add_constant_override("separation", 5)
	campaign_box.add_child(cv)
	cv.add_child(UIStyle.label("THE LIBERATION OF VEGA", 28, UIStyle.ACCENT, "Bold"))
	for m in Missions.MISSIONS:
		var b = Button.new()
		var unlocked = m["id"] <= GameState.unlocked_missions
		var label = "%02d    %s" % [m["id"], m["title"].to_upper()]
		if not m["playable"]:
			label += "        in development"
		elif not unlocked:
			label += "        locked"
		b.text = label
		b.align = Button.ALIGN_LEFT
		b.rect_min_size = Vector2(0, 40)
		b.hint_tooltip = m["briefing"]
		b.disabled = not (m["playable"] and unlocked)
		b.connect("pressed", self, "_start_mission", [m["id"]])
		cv.add_child(b)
		if not b.disabled:
			start_buttons.append(b)
	_btn(cv, "BACK", "_show_main")

	help_panel = PanelContainer.new()
	help_panel.margin_left = 500
	help_panel.margin_top = 60
	help_panel.margin_right = 1160
	help_panel.visible = false
	add_child(help_panel)
	var hv = VBoxContainer.new()
	hv.add_constant_override("separation", 10)
	help_panel.add_child(hv)
	hv.add_child(UIStyle.label("CONTROLS", 28, UIStyle.ACCENT, "Bold"))
	hv.add_child(UIStyle.label("""Select units                       left-click or drag a box
Move / attack / harvest      right-click (two-finger click)
Attack-move                       Ctrl or Option + right-click
Select whole army              Q
Stop                                    X
Jump to base                     H
Pause                                  P
Scroll                                  WASD, arrows, screen edges, two-finger swipe
Zoom                                  mouse wheel or pinch

Build: click a structure, wait for READY, click it again and place it on rock.""", 18))
	hv.add_child(UIStyle.label("TIPS", 22, UIStyle.ACCENT, "Bold"))
	hv.add_child(UIStyle.label("""Sandeaters guard their Uralium fields and swallow anything moving on the sand.
Rock is safe. They vanish after feeding, but they always come back.
Red mounds are Uralium under pressure: touching one sets it off.""", 18))
	_btn(hv, "CLOSE", "_toggle_help")

	if not Art.is_ready:
		for b in start_buttons:
			b.disabled = true
		Art.connect("progress", self, "_on_art_progress")
		Art.connect("finished", self, "_on_art_ready")
		Art.build()


func _on_art_progress(f):
	loading_label.text = "Preparing graphics...  %d%%   (first launch only)" % int(f * 100)


func _on_art_ready():
	loading_label.text = ""
	for b in start_buttons:
		b.disabled = false


func _btn(parent, text, method, args = []):
	var b = Button.new()
	b.text = text
	b.align = Button.ALIGN_LEFT
	b.rect_min_size = Vector2(340, 44)
	b.connect("pressed", self, method, args)
	parent.add_child(b)
	return b


func _update_settings():
	diff_button.text = "DIFFICULTY  -  %s" % GameState.difficulty_name().to_upper()
	gfx_button.text = "GRAPHICS  -  %s" % ("HIGH" if GameState.graphics_high else "FAST")
	gfx_button.hint_tooltip = "FAST turns off glow and halves the particles. Use it if the game stutters."


func _cycle_difficulty():
	GameState.difficulty = (GameState.difficulty + 1) % 3
	GameState.save_progress()
	_update_settings()


func _toggle_graphics():
	GameState.graphics_high = not GameState.graphics_high
	GameState.save_progress()
	_update_settings()


func _toggle_help():
	help_panel.visible = not help_panel.visible
	campaign_box.visible = false


func _show_campaign():
	campaign_box.visible = not campaign_box.visible
	help_panel.visible = false


func _show_main():
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
	# Slow drift across the map.
	backdrop.position = Vector2(-900 - t * 9.0, -700 - t * 5.0)
	if backdrop.position.x < -2600:
		t = 0.0
