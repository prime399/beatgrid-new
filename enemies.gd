extends Node2D

const MAP_W = 3200.0
const MAP_H = 2400.0
const ARENA_INSET = 52.0
const CORNER_R = 95.0
const CONTACT_COOLDOWN = 0.8
const PLAYER_RADIUS = 12.0

const TRI_COLORS = [
	Color(0.85, 0.75, 0.55),
	Color(0.6, 0.3, 0.8),
	Color(1.0, 0.95, 0.3),
	Color(0.6, 0.9, 0.4),
]
const SQR_COLORS = [
	Color(0.85, 0.75, 0.55),
	Color(0.6, 0.3, 0.8),
	Color(1.0, 0.95, 0.3),
	Color(0.6, 0.9, 0.4),
]
const HEX_COLORS = [
	Color(0.95, 0.95, 0.95),
	Color(0.85, 0.75, 0.55),
]

const PROJ_SPEED = 130.0
const PROJ_TURN = 1.2
const PROJ_RADIUS = 5.0
const PROJ_LIFETIME = 7.0
const TRI_SHOOT_CD = 2.5
const TRI_SIGHT_RANGE = 500.0

const HEX_SPAWN_CD = 20.0
const HEX_MAX_MINIONS = 3
const CHAIN_RANGE = 350.0

var enemies: Array = []
var projectiles: Array = []
var particles: Array = []
var level_active: bool = false

func _ready() -> void:
	pass

func clear_all():
	enemies.clear()
	projectiles.clear()
	particles.clear()
	level_active = false
	queue_redraw()

func setup_level(level: int):
	clear_all()
	level_active = true
	match level:
		0: _spawn_level_0()
		1: _spawn_level_1()
		2: _spawn_level_2()

func _spawn_level_0():
	var points = _get_scattered_positions(12, 180.0)
	for p in points:
		enemies.append(_make_triangle(p))

func _spawn_level_1():
	var points = _get_scattered_positions(16, 180.0)
	for i in range(points.size()):
		if i < 10:
			enemies.append(_make_triangle(points[i]))
		else:
			enemies.append(_make_square(points[i]))

func _spawn_level_2():
	var points = _get_scattered_positions(18, 200.0)
	enemies.append(_make_hexagon(points[0]))
	enemies.append(_make_hexagon(points[1]))
	for i in range(2, min(9, points.size())):
		enemies.append(_make_triangle(points[i]))
	for i in range(9, min(18, points.size())):
		enemies.append(_make_square(points[i]))

func _get_scattered_positions(count: int, min_dist: float) -> Array:
	var positions: Array = []
	var player_pos = Vector2(MAP_W / 2.0, MAP_H / 2.0)
	var x_min = ARENA_INSET + CORNER_R
	var x_max = MAP_W - ARENA_INSET - CORNER_R
	var y_min = ARENA_INSET + CORNER_R
	var y_max = MAP_H - ARENA_INSET - CORNER_R
	var attempts = 0
	while positions.size() < count and attempts < 500:
		attempts += 1
		var pos = Vector2(randf_range(x_min, x_max), randf_range(y_min, y_max))
		if pos.distance_to(player_pos) < 300.0:
			continue
		var too_close = false
		for p in positions:
			if pos.distance_to(p) < min_dist:
				too_close = true
				break
		if not too_close:
			positions.append(pos)
	return positions

func _make_triangle(pos: Vector2) -> Dictionary:
	var c = TRI_COLORS[randi() % TRI_COLORS.size()]
	return {
		"type": "triangle", "pos": pos,
		"vel": Vector2.from_angle(randf() * TAU) * randf_range(27, 47),
		"color": c, "size": 10.0, "hp": 1, "max_hp": 1,
		"flash": 0.0, "damage": 1, "chase": 0.5,
		"contact_cd": 0.0, "base_speed": randf_range(27, 47),
		"shoot_cd": randf_range(0.5, TRI_SHOOT_CD),
		"angle": randf() * TAU, "owner_id": -1,
	}

func _make_square(pos: Vector2) -> Dictionary:
	var c = SQR_COLORS[randi() % SQR_COLORS.size()]
	return {
		"type": "square", "pos": pos,
		"vel": Vector2.from_angle(randf() * TAU) * randf_range(17, 30),
		"color": c, "size": 12.0, "hp": 2, "max_hp": 2,
		"flash": 0.0, "damage": 2, "chase": 0.3,
		"contact_cd": 0.0, "base_speed": randf_range(17, 30),
		"shoot_cd": 0.0, "angle": randf() * TAU, "owner_id": -1,
	}

func _make_hexagon(pos: Vector2) -> Dictionary:
	var c = HEX_COLORS[randi() % HEX_COLORS.size()]
	return {
		"type": "hexagon", "pos": pos,
		"vel": Vector2.ZERO, "color": c, "size": 28.0,
		"hp": 8, "max_hp": 8, "flash": 0.0, "damage": 3,
		"chase": 0.0, "contact_cd": 0.0, "base_speed": 0.0,
		"shoot_cd": 0.0, "angle": randf() * TAU,
		"spawn_cd": randf_range(1.0, HEX_SPAWN_CD),
		"minion_count": 0, "hex_id": randi(), "owner_id": -1,
	}

func chain_laser(start: Vector2, end: Vector2, hit_radius: float, damage: int) -> Array:
	var segments: Array = []
	var hit_list: Array = []

	var first = _find_first_hit(start, end, hit_radius, hit_list)
	if first == null:
		segments.append({"from": start, "to": end})
		return segments

	segments.append({"from": start, "to": first.pos})
	first.hp -= damage
	first.flash = 0.15
	hit_list.append(first)

	var current = first
	for _i in range(20):
		var next = _find_nearest_enemy(current.pos, CHAIN_RANGE, hit_list)
		if next == null:
			break
		segments.append({"from": current.pos, "to": next.pos})
		next.hp -= damage
		next.flash = 0.15
		hit_list.append(next)
		current = next

	var to_remove: Array = []
	for e in hit_list:
		if e.hp <= 0:
			to_remove.append(e)
	for e in to_remove:
		_on_enemy_death(e)

	return segments

func _find_first_hit(start: Vector2, end: Vector2, hit_radius: float, exclude: Array):
	var best = null
	var best_dist = INF
	var dir = (end - start)
	var line_len = dir.length()
	if line_len < 1.0:
		return null
	dir = dir / line_len
	for e in enemies:
		if e in exclude:
			continue
		var seg_dist = _point_to_segment_dist(e.pos, start, end)
		if seg_dist <= hit_radius + e.size:
			var proj = (e.pos - start).dot(dir)
			if proj >= 0 and proj < best_dist:
				best_dist = proj
				best = e
	return best

func _find_nearest_enemy(from_pos: Vector2, max_range: float, exclude: Array):
	var best = null
	var best_dist = INF
	for e in enemies:
		if e in exclude:
			continue
		var d = from_pos.distance_to(e.pos)
		if d < max_range and d < best_dist:
			best_dist = d
			best = e
	return best

func repel_from_line(a: Vector2, b: Vector2, thickness: float, push_dir: Vector2, _push_force: float, delta: float):
	var push_dist = 48.0 * 2.5
	for e in enemies:
		var dist = _point_to_segment_dist(e.pos, a, b)
		if dist < thickness + e.size:
			e.pos += push_dir.normalized() * push_dist * delta / 0.35

func _on_enemy_death(e: Dictionary):
	_spawn_death_particles(e)
	if e.type == "hexagon":
		for other in enemies:
			if other.get("owner_id", -1) == e.get("hex_id", -1):
				other.owner_id = -1
	enemies.erase(e)

func _spawn_death_particles(e: Dictionary):
	var count = int(e.size * 1.2) + 8
	for i in range(count):
		var a = randf() * TAU
		var speed = randf_range(120, 350)
		particles.append({
			"pos": e.pos + Vector2.from_angle(a) * randf_range(0, e.size * 0.5),
			"vel": Vector2.from_angle(a) * speed,
			"rot_speed": randf_range(-12.0, 12.0),
			"angle": randf() * TAU,
			"size": randf_range(2.0, e.size * 0.5),
			"color": e.color.lightened(randf_range(-0.1, 0.3)),
			"life": randf_range(0.4, 0.7), "max_life": 0.7,
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
	var player_node = get_node("../Player")

	for e in enemies:
		e.angle += delta * 0.5

		if e.type == "hexagon":
			_process_hexagon(e, player_pos, delta)
		else:
			var to_player = (player_pos - e.pos).normalized()
			var chase_vel = to_player * e.base_speed * 1.5
			e.vel = e.vel.lerp(chase_vel, e.chase * delta * 3.0)
			e.pos += e.vel * delta
			e.pos = _clamp_rounded_rect(e.pos, e.size)

		if e.type == "triangle":
			_process_triangle_shoot(e, player_pos, delta)

		if e.flash > 0.0:
			e.flash -= delta
		if e.contact_cd > 0.0:
			e.contact_cd -= delta
		elif e.pos.distance_to(player_pos) < e.size + PLAYER_RADIUS:
			player_node.take_damage(e.damage)
			e.contact_cd = CONTACT_COOLDOWN
			if e.base_speed > 0:
				e.vel = (e.pos - player_pos).normalized() * e.base_speed * 2.0

	_process_projectiles(delta, player_pos, player_node)
	_process_particles(delta)

	if level_active and enemies.size() == 0 and particles.size() == 0:
		level_active = false
		get_node("..").on_level_cleared()

	queue_redraw()

func _process_hexagon(e: Dictionary, _player_pos: Vector2, delta: float):
	e.spawn_cd -= delta
	if e.spawn_cd <= 0.0:
		e.spawn_cd = HEX_SPAWN_CD + randf_range(-1.0, 1.0)
		if e.minion_count < HEX_MAX_MINIONS:
			var offset = Vector2.from_angle(randf() * TAU) * (e.size + 20.0)
			var minion: Dictionary
			if randf() < 0.6:
				minion = _make_triangle(e.pos + offset)
			else:
				minion = _make_square(e.pos + offset)
			minion.owner_id = e.hex_id
			enemies.append(minion)
			e.minion_count += 1

func _process_triangle_shoot(e: Dictionary, player_pos: Vector2, delta: float):
	e.shoot_cd -= delta
	if e.shoot_cd <= 0.0:
		e.shoot_cd = TRI_SHOOT_CD + randf_range(-0.5, 0.5)
		var dist = e.pos.distance_to(player_pos)
		if dist < TRI_SIGHT_RANGE:
			var dir = (player_pos - e.pos).normalized()
			projectiles.append({
				"pos": e.pos + dir * (e.size + PROJ_RADIUS + 2.0),
				"vel": dir * PROJ_SPEED,
				"life": PROJ_LIFETIME, "color": e.color.lightened(0.3),
			})

func _process_projectiles(delta: float, player_pos: Vector2, player_node):
	var dead = []
	for p in projectiles:
		var to_player = (player_pos - p.pos).normalized()
		p.vel = p.vel.normalized().lerp(to_player, PROJ_TURN * delta).normalized() * PROJ_SPEED
		p.pos += p.vel * delta
		p.life -= delta

		if p.life <= 0.0:
			dead.append(p)
			continue

		var clamped = _clamp_rounded_rect(p.pos, PROJ_RADIUS)
		if clamped != p.pos:
			dead.append(p)
			continue

		if p.pos.distance_to(player_pos) < PROJ_RADIUS + PLAYER_RADIUS:
			player_node.take_damage(1)
			dead.append(p)

	for p in dead:
		projectiles.erase(p)

func _process_particles(delta: float):
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

func _clamp_rounded_rect(pos: Vector2, margin: float) -> Vector2:
	var x0 = ARENA_INSET + margin
	var y0 = ARENA_INSET + margin
	var x1 = MAP_W - ARENA_INSET - margin
	var y1 = MAP_H - ARENA_INSET - margin
	var r = CORNER_R - margin

	pos.x = clamp(pos.x, x0, x1)
	pos.y = clamp(pos.y, y0, y1)

	var corners = [
		Vector2(x0 + r, y0 + r), Vector2(x1 - r, y0 + r),
		Vector2(x1 - r, y1 - r), Vector2(x0 + r, y1 - r),
	]
	for idx in range(4):
		var c = corners[idx]
		var in_corner = false
		if idx == 0 and pos.x < c.x and pos.y < c.y: in_corner = true
		elif idx == 1 and pos.x > c.x and pos.y < c.y: in_corner = true
		elif idx == 2 and pos.x > c.x and pos.y > c.y: in_corner = true
		elif idx == 3 and pos.x < c.x and pos.y > c.y: in_corner = true
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
		var pts = PackedVector2Array()
		for i in range(3):
			var a = p.angle + float(i) * TAU / 3.0
			pts.append(p.pos + Vector2.from_angle(a) * s)
		draw_colored_polygon(pts, c)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(c, c.a * 0.5), 1.0)

	for p in projectiles:
		var alpha = clamp(p.life / PROJ_LIFETIME, 0.0, 1.0)
		draw_circle(p.pos, PROJ_RADIUS, Color(p.color, alpha * 0.4))
		draw_circle(p.pos, PROJ_RADIUS * 0.5, Color(p.color, alpha))
		draw_arc(p.pos, PROJ_RADIUS, 0, TAU, 12, Color(1, 1, 1, alpha * 0.3), 1.0)

	for e in enemies:
		var c = e.color
		if e.flash > 0.0:
			c = Color.WHITE
		match e.type:
			"triangle": _draw_triangle(e, c)
			"square": _draw_square(e, c)
			"hexagon": _draw_hexagon(e, c)

		if e.max_hp > 1:
			var bar_w = e.size * 2.0
			var bar_h = 3.0
			var bar_x = e.pos.x - bar_w / 2.0
			var bar_y = e.pos.y - e.size - 8.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
			var fill = float(e.hp) / e.max_hp
			draw_rect(Rect2(bar_x, bar_y, bar_w * fill, bar_h), Color(0.0, 1.0, 0.4))

func _draw_triangle(e: Dictionary, c: Color):
	var pts = PackedVector2Array()
	for i in range(3):
		var a = e.angle + float(i) * TAU / 3.0 - PI / 2.0
		pts.append(e.pos + Vector2.from_angle(a) * e.size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.5)

func _draw_square(e: Dictionary, c: Color):
	var pts = PackedVector2Array()
	for i in range(4):
		var a = e.angle + float(i) * TAU / 4.0 + PI / 4.0
		pts.append(e.pos + Vector2.from_angle(a) * e.size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.5)

func _draw_hexagon(e: Dictionary, c: Color):
	var pts = PackedVector2Array()
	for i in range(6):
		var a = e.angle + float(i) * TAU / 6.0
		pts.append(e.pos + Vector2.from_angle(a) * e.size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 2.0)
	draw_arc(e.pos, e.size * 0.5, 0, TAU, 12, Color(1, 1, 1, 0.3), 1.5)
