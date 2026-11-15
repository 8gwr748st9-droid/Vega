extends Node
# Settings carried from the menu into a match, plus campaign progress.

const SAVE_PATH = "user://progress.cfg"

var mode = "skirmish"          # "skirmish" or "campaign"
var mission = 1
var player_faction = "arthem"
var enemy_faction = "klingos"
var difficulty = 1             # 0 easy, 1 normal, 2 hard
var unlocked_missions = 1
var map_seed = 0


func _ready():
	load_progress()


func difficulty_name():
	return ["Easy", "Normal", "Hard"][difficulty]


func load_progress():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_missions = int(cfg.get_value("campaign", "unlocked", 1))
		difficulty = int(cfg.get_value("settings", "difficulty", 1))


func save_progress():
	var cfg = ConfigFile.new()
	cfg.set_value("campaign", "unlocked", unlocked_missions)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save(SAVE_PATH)
