extends Node2D
# Missiles and shells. Travel to the target position, then deal (splash) damage.

var game
var shooter_team = 0
var shooter = null
var target = null
var target_pos = Vector2()
var damage = 10.0
var splash = 0.0
var speed = 420.0
var kind = "missile"
var age = 0.0
var start = Vector2()


func launch(g, from_entity, to_entity):
	game = g
	shooter = from_entity
	shooter_team = from_entity.team
	target = to_entity
	target_pos = to_entity.global_position
	damage = from_entity.def["damage"]
	splash = from_entity.def.get("splash", 0)
	kind = from_entity.def.get("weapon", "missile")
	speed = 300.0 if kind == "shell" else 430.0
	position = from_entity.global_position
	start = position


func _process(delta):
	age += delta
	if target != null and is_instance_valid(target) and not target.dead and kind == "missile":
		target_pos = target.global_position
	var to = target_pos - position
	var d = to.length()
	var step = speed * delta
	if d <= step:
		_impact()
		return
	position += to / d * step
	rotation = to.angle()
	if kind == "missile" and int(age * 30) % 2 == 0:
		game.fx_puff(position - to / d * 8)
	update()


func _impact():
	if splash > 0:
		for e in get_tree().get_nodes_in_group("entities"):
			if e.dead or e.team == shooter_team:
				continue
			var dist = e.global_position.distance_to(target_pos)
			if dist <= splash + e.radius:
				var shooter_ok = shooter != null and is_instance_valid(shooter)
				if shooter_ok and not shooter.is_enemy_of(e):
					continue
				e.take_damage(damage * (1.0 - 0.5 * clamp(dist / (splash + e.radius), 0, 1)), shooter if shooter_ok else null)
	elif target != null and is_instance_valid(target) and not target.dead:
		target.take_damage(damage, shooter if is_instance_valid(shooter) else null)
	game.fx_explosion(target_pos, 0.6 if splash < 40 else 1.1)
	queue_free()


func _draw():
	if kind == "shell":
		draw_circle(Vector2.ZERO, 3.0, Color(0.12, 0.11, 0.10))
		draw_circle(Vector2(-1, -1), 1.3, Color(0.8, 0.7, 0.5))
	else:
		draw_rect(Rect2(Vector2(-6, -1.5), Vector2(11, 3)), Color(0.78, 0.80, 0.82))
		draw_rect(Rect2(Vector2(3, -1.5), Vector2(3, 3)), Color(0.75, 0.15, 0.1))
		draw_circle(Vector2(-8, 0), 3.5, Color(1.6, 0.9, 0.3, 0.9))
		draw_circle(Vector2(-11, 0), 2.2, Color(1.4, 0.5, 0.1, 0.6))
