extends CanvasLayer
# In-game interface: RA2-style sidebar (minimap, credits, power, build buttons), messages, objectives.

const UIStyle = preload("res://scripts/ui_style.gd")
const MinimapScript = preload("res://scripts/minimap.gd")

const SIDEBAR_W = 240

var game
var root
var credits_label
var power_label
var message_label
var message_time = 0.0
var objectives_label
var info_label
var struct_grid
var unit_grid
var struct_buttons = {}
var unit_buttons = {}
var orbital_button
var refresh = 0.0
var paused_label
var game_over_panel


func _ready():
	layer = 10
	pause_mode = Node.PAUSE_MODE_PROCESS
	root = Control.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.make_theme()
	add_child(root)

	var side = Panel.new()
	side.anchor_left = 1
	side.anchor_right = 1
	side.anchor_bottom = 1
	side.margin_left = -SIDEBAR_W
	root.add_child(side)

	var vb = VBoxContainer.new()
	vb.anchor_right = 1
	vb.anchor_bottom = 1
	vb.margin_left = 10
	vb.margin_right = -10
	vb.margin_top = 10
	vb.margin_bottom = -10
	vb.add_constant_override("separation", 6)
	side.add_child(vb)

	var f = game.team_faction[game.player_team]
	var title = Label.new()
	title.text = Data.FACTIONS[f]["name"].to_upper()
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Data.faction_color(f).lightened(0.3))
	vb.add_child(title)

	var mm = MinimapScript.new()
	mm.game = game
	mm.rect_min_size = Vector2(SIDEBAR_W - 20, SIDEBAR_W - 20)
	vb.add_child(mm)

	credits_label = Label.new()
	credits_label.add_color_override("font_color", UIStyle.ACCENT)
	vb.add_child(credits_label)
	power_label = Label.new()
	vb.add_child(power_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	vb.add_child(scroll)
	var lists = VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lists)

	var l1 = Label.new()
	l1.text = "STRUCTURES"
	lists.add_child(l1)
	struct_grid = GridContainer.new()
	struct_grid.columns = 2
	lists.add_child(struct_grid)
	for k in Data.buildings_for(f, game.tech):
		if k == "hq":
			continue
		var b = _make_button()
		b.connect("pressed", self, "_on_struct_pressed", [k])
		struct_grid.add_child(b)
		struct_buttons[k] = b

	var l2 = Label.new()
	l2.text = "UNITS"
	lists.add_child(l2)
	unit_grid = GridContainer.new()
	unit_grid.columns = 2
	lists.add_child(unit_grid)
	for k in Data.units_for(f, game.tech):
		var b2 = _make_button()
		b2.connect("pressed", self, "_on_unit_pressed", [k])
		unit_grid.add_child(b2)
		unit_buttons[k] = b2

	orbital_button = _make_button()
	orbital_button.rect_min_size = Vector2(SIDEBAR_W - 34, 44)
	orbital_button.visible = false
	orbital_button.connect("pressed", self, "_on_orbital_pressed")
	lists.add_child(orbital_button)

	message_label = Label.new()
	message_label.margin_left = 16
	message_label.margin_top = 12
	message_label.add_color_override("font_color", Color(1, 0.92, 0.6))
	message_label.rect_scale = Vector2(1.4, 1.4)
	root.add_child(message_label)

	objectives_label = Label.new()
	objectives_label.margin_left = 16
	objectives_label.margin_top = 50
	root.add_child(objectives_label)

	info_label = Label.new()
	info_label.anchor_top = 1
	info_label.anchor_bottom = 1
	info_label.margin_left = 16
	info_label.margin_top = -60
	root.add_child(info_label)

	paused_label = Label.new()
	paused_label.text = "PAUSED  (press P)"
	paused_label.anchor_left = 0.5
	paused_label.anchor_top = 0.4
	paused_label.rect_scale = Vector2(3, 3)
	paused_label.margin_left = -150
	paused_label.visible = false
	root.add_child(paused_label)

	_refresh()


func _make_button():
	var b = Button.new()
	b.rect_min_size = Vector2((SIDEBAR_W - 34) / 2, 54)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _on_struct_pressed(kind):
	var sb = game.struct_build[game.player_team]
	if sb["kind"] == kind:
		if sb["ready"]:
			game.begin_placement(kind)
		else:
			game.cancel_structure(game.player_team)
	elif sb["kind"] == "":
		game.start_structure(game.player_team, kind)
	_refresh()


func _on_orbital_pressed():
	if game.orbital_ready(game.player_team):
		game.targeting = "orbital"
		game.placing = ""
		show_message("Pick a target. Test-phase beam: it WILL drift off target.")


func _on_unit_pressed(kind):
	game.queue_unit(game.player_team, kind)
	_refresh()


func show_message(text):
	if message_label:
		message_label.text = text
		message_time = 5.0


func set_objectives(text):
	objectives_label.text = text


func _process(delta):
	message_time -= delta
	if message_time <= 0 and message_label:
		message_label.text = ""
	refresh -= delta
	if refresh <= 0:
		refresh = 0.2
		_refresh()


func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.scancode == KEY_P and not game.game_over:
		if game.cutscene and game.cutscene.active:
			return
		get_tree().paused = not get_tree().paused
		paused_label.visible = get_tree().paused


func _refresh():
	var t = game.player_team
	credits_label.text = "URALIUM  %d" % int(game.credits[t])
	var ok = game.has_power(t)
	power_label.text = "POWER  %d / %d%s" % [game.power_used[t], game.power_made[t], "" if ok else "   LOW!"]
	power_label.add_color_override("font_color", Color(0.5, 1, 0.5) if ok else Color(1, 0.4, 0.3))

	var sb = game.struct_build[t]
	for k in struct_buttons.keys():
		var b = struct_buttons[k]
		var d = Data.get_def(k)
		var status = "$%d" % d["cost"]
		if sb["kind"] == k:
			status = "READY - place" if sb["ready"] else "%d%%" % int(100 * sb["progress"] / d["build_time"])
		b.text = "%s\n%s" % [d["name"], status]
		b.disabled = not game.requirements_met(t, k) or (sb["kind"] != "" and sb["kind"] != k)
		b.hint_tooltip = "Needs: %s" % PoolStringArray(d.get("requires", [])).join(", ")
	for k in unit_buttons.keys():
		var b2 = unit_buttons[k]
		var d2 = Data.get_def(k)
		var q = game.queued_count(t, k)
		b2.text = "%s\n$%d%s" % [d2["name"], d2["cost"], ("   x%d" % q) if q > 0 else ""]
		b2.disabled = game.producers_for(t, k).empty()
		b2.hint_tooltip = "Built at: %s" % Data.get_def(d2["built_at"])["name"]

	var has_uplink = game.has_building(t, "orbital_uplink")
	orbital_button.visible = has_uplink
	if has_uplink:
		var pct = int(100 * game.orbital_charge[t] / game.orbital_time())
		if game.targeting == "orbital":
			orbital_button.text = "ORBITAL STRIKE\nchoose target..."
		elif pct >= 100:
			orbital_button.text = "ORBITAL STRIKE\nREADY"
		else:
			orbital_button.text = "ORBITAL STRIKE\ncharging %d%%" % pct
		orbital_button.disabled = pct < 100

	var sel = []
	for s in game.selected:
		if is_instance_valid(s) and not s.dead:
			sel.append(s)
	if sel.size() == 1:
		var e = sel[0]
		info_label.text = "%s   %d / %d" % [e.def["name"], int(e.hp), int(e.max_hp)]
		if e.def.get("harvester", false):
			info_label.text += "   cargo %d" % int(e.cargo)
	elif sel.size() > 1:
		info_label.text = "%d units selected" % sel.size()
	else:
		info_label.text = "Drag: select   Right-click: move/attack   Ctrl/Option+right-click: attack-move\nQ: select army   X: stop   H: home   P: pause   WASD/edges/trackpad: scroll"


func show_game_over(won):
	get_tree().paused = false
	game_over_panel = PanelContainer.new()
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.margin_left = -220
	game_over_panel.margin_top = -90
	game_over_panel.margin_right = 220 - SIDEBAR_W
	root.add_child(game_over_panel)
	var vb = VBoxContainer.new()
	vb.add_constant_override("separation", 14)
	game_over_panel.add_child(vb)
	var l = Label.new()
	l.text = "VICTORY!" if won else "DEFEAT"
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", UIStyle.ACCENT if won else Color(1, 0.4, 0.3))
	vb.add_child(l)
	var sub = Label.new()
	sub.text = "Vega remembers your name." if won else "The sands swallow another army."
	sub.align = Label.ALIGN_CENTER
	vb.add_child(sub)
	var b = Button.new()
	b.text = "Back to menu"
	b.rect_min_size = Vector2(200, 44)
	b.connect("pressed", self, "_to_menu")
	vb.add_child(b)


func _to_menu():
	get_tree().paused = false
	get_tree().change_scene("res://scenes/Menu.tscn")
