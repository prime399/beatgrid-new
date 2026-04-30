extends Node2D

const MAP_W = 3200.0
const MAP_H = 2400.0
const ARENA_INSET = 52.0
const CORNER_R = 95.0
const CONTACT_COOLDOWN = 0.8
const PLAYER_RADIUS = 12.0

const ENEMY_TYPES = [
	{"hp": 1, "size": 8.0,  "speed_min": 80.0,  "speed_max": 150.0, "hue": 0.0,  "damage": 1, "chase": 0.5},
	{"hp": 2, "size": 12.0, "speed_min": 60.0,  "speed_max": 120.0, "hue": 0.08, "damage": 2, "chase": 0.35},
	{"hp": 3, "size": 16.0, "speed_min": 50.0,  "speed_max": 100.0, "hue": 0.45, "damage": 3, "chase": 0.25},
	{"hp": 5, "size": 22.0, "speed_min": 30.0,  "speed_max": 70.0,  "hue": 0.75, "damage": 5, "chase": 0.15},
]

var enemies: Array = []
var particles: Array = []

func _ready() -> void:
	var center = Vector2(MAP_W / 2.0, MAP_H / 2.0)
	for i in range(10):
		var etype = ENEMY_TYPES[i % ENEMY_TYPES.size()]
		var offset = Vector2(randf_range(-500, 500), randf_range(-400, 400))
		var e = {
			"pos": center + offset,
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(etype.speed_min, etype.speed_max),
			"color": Color.from_hsv(etype.hue, 0.85, 1.0),
			"size": etype.size,
			"hp": etype.hp,
			"max_hp": etype.hp,
			"flash": 0.0,
			"damage": etype.damage,
			"chase": etype.chase,
			"contact_cd": 0.0,
			"base_speed": randf_range(etype.speed_min, etype.speed_max),
		}
		enemies.append(e)

func damage_in_line(start: Vector2, end: Vector2, hit_radius: float, damage: int):
	var to_remove = []
	for e in enemies:
		var dist = _point_to_segment_dist(e.pos, start, end)
		if dist <= hit_radius + e.size:
			e.hp -= damage
			e.flash = 0.15
			if e.hp <= 0:
				to_remove.append(e)
	for e in to_remove:
		_spawn_death_particles(e)
		enemies.erase(e)

func repel_from_line(a: Vector2, b: Vector2, thickness: float, push_dir: Vector2, _push_force: float, delta: float):
	var push_dist = 48.0 * 2.5
	for e in enemies:
		var dist = _point_to_segment_dist(e.pos, a, b)
		if dist < thickness + e.size:
			e.pos += push_dir.normalized() * push_dist * delta / 0.35

func _spawn_death_particles(e):
	var count = int(e.size * 1.2) + 8
	for i in range(count):
		var angle = randf() * TAU
		var speed = randf_range(120, 350)
		particles.append({
			"pos": e.pos + Vector2.from_angle(angle) * randf_range(0, e.size * 0.5),
			"vel": Vector2.from_angle(angle) * speed,
			"rot_speed": randf_range(-12.0, 12.0),
			"angle": randf() * TAU,
			"size": randf_range(2.0, e.size * 0.5),
			"color": e.color.lightened(randf_range(-0.1, 0.3)),
			"life": randf_range(0.4, 0.7),
			"max_life": 0.7,
		})

func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var len_sq = ab.length_squared()
	if len_sq < 0.001:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _process(delta: float) -> void:
	var player_pos = get_node("../Player").position

	for e in enemies:
		var to_player = (player_pos - e.pos).normalized()
		var chase_vel = to_player * e.base_speed * 1.5
		e.vel = e.vel.lerp(chase_vel, e.chase * delta * 3.0)

		var old_pos = e.pos
		e.pos += e.vel * delta
		e.pos = _clamp_rounded_rect(e.pos, e.size)
		if e.pos != old_pos + e.vel * delta:
			var diff = e.pos - old_pos
			if abs(diff.x) < 0.01:
				e.vel.x *= -1
			if abs(diff.y) < 0.01:
				e.vel.y *= -1

		if e.flash > 0.0:
			e.flash -= delta

		if e.contact_cd > 0.0:
			e.contact_cd -= delta
		elif e.pos.distance_to(player_pos) < e.size + PLAYER_RADIUS:
			get_node("../Player").take_damage(e.damage)
			e.contact_cd = CONTACT_COOLDOWN
			var knockback = (e.pos - player_pos).normalized()
			e.vel = knockback * e.base_speed * 2.0

	var dead = []
	for p in particles:
		p.life -= delta
		if p.life <= 0:
			dead.append(p)
			continue
		p.pos += p.vel * delta
		p.vel *= 0.93
		p.angle += p.rot_speed * delta
	for p in dead:
		particles.erase(p)

	queue_redraw()

func _clamp_rounded_rect(pos: Vector2, margin: float) -> Vector2:
	var x0 = ARENA_INSET + margin
	var y0 = ARENA_INSET + margin
	var x1 = MAP_W - ARENA_INSET - margin
	var y1 = MAP_H - ARENA_INSET - margin
	var r = CORNER_R - margin

	pos.x = clamp(pos.x, x0, x1)
	pos.y = clamp(pos.y, y0, y1)

	var corners = [
		Vector2(x0 + r, y0 + r),
		Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r),
		Vector2(x0 + r, y1 - r),
	]
	for c in corners:
		var in_corner = false
		if c == corners[0] and pos.x < c.x and pos.y < c.y:
			in_corner = true
		elif c == corners[1] and pos.x > c.x and pos.y < c.y:
			in_corner = true
		elif c == corners[2] and pos.x > c.x and pos.y > c.y:
			in_corner = true
		elif c == corners[3] and pos.x < c.x and pos.y > c.y:
			in_corner = true
		if in_corner:
			var offset = pos - c
			if offset.length() > r:
				pos = c + offset.normalized() * r
	return pos

func _draw() -> void:
	for p in particles:
		var t = p.life / p.max_life
		var c = p.color
		c.a = t
		var s = p.size * (0.3 + 0.7 * t)
		var points = PackedVector2Array()
		for i in range(3):
			var a = p.angle + float(i) * TAU / 3.0
			points.append(p.pos + Vector2.from_angle(a) * s)
		draw_colored_polygon(points, c)
		draw_polyline(points + PackedVector2Array([points[0]]), Color(c, c.a * 0.5), 1.0)

	for e in enemies:
		var c = e.color
		if e.flash > 0.0:
			c = Color.WHITE
		draw_circle(e.pos, e.size, c)
		draw_arc(e.pos, e.size, 0, TAU, 24, Color.WHITE, 1.0)

		if e.max_hp > 1:
			var bar_w = e.size * 2.0
			var bar_h = 3.0
			var bar_x = e.pos.x - bar_w / 2.0
			var bar_y = e.pos.y - e.size - 6.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
			var fill = float(e.hp) / e.max_hp
			draw_rect(Rect2(bar_x, bar_y, bar_w * fill, bar_h), Color(0.0, 1.0, 0.4))
