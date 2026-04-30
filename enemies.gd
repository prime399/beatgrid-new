extends Node2D

const ENEMY_COUNT = 5
const SIZE = 10.0
const MAP_W = 3200.0
const MAP_H = 2400.0
const ARENA_INSET = 52.0
const CORNER_R = 95.0

var enemies: Array = []

func _ready() -> void:
	var center = Vector2(MAP_W / 2.0, MAP_H / 2.0)
	for i in range(ENEMY_COUNT):
		var offset = Vector2(randf_range(-400, 400), randf_range(-300, 300))
		enemies.append({
			"pos": center + offset,
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(60.0, 140.0),
			"color": Color.from_hsv(float(i) / ENEMY_COUNT, 0.9, 1.0),
		})

func _process(delta: float) -> void:
	for e in enemies:
		var old_pos = e.pos
		e.pos += e.vel * delta
		e.pos = _clamp_rounded_rect(e.pos, SIZE)
		if e.pos != old_pos + e.vel * delta:
			var diff = e.pos - old_pos
			if abs(diff.x) < 0.01:
				e.vel.x *= -1
			if abs(diff.y) < 0.01:
				e.vel.y *= -1

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
	for e in enemies:
		draw_circle(e.pos, SIZE, e.color)
		draw_arc(e.pos, SIZE, 0, TAU, 24, Color.WHITE, 1.0)
