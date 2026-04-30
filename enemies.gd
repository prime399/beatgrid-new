extends Node2D

const ENEMY_COUNT = 5
const SIZE = 10.0
const ARENA_INSET = 52.0

var enemies: Array = []

func _ready() -> void:
	var screen = get_viewport_rect().size
	var min_pos = Vector2(ARENA_INSET + SIZE * 2, ARENA_INSET + SIZE * 2)
	var max_pos = screen - min_pos
	for i in range(ENEMY_COUNT):
		enemies.append({
			"pos": Vector2(
				randf_range(min_pos.x, max_pos.x),
				randf_range(min_pos.y, max_pos.y)
			),
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(60.0, 140.0),
			"color": Color.from_hsv(float(i) / ENEMY_COUNT, 0.9, 1.0),
		})

func _process(delta: float) -> void:
	var screen = get_viewport_rect().size
	var lo = Vector2(ARENA_INSET + SIZE, ARENA_INSET + SIZE)
	var hi = screen - lo

	for e in enemies:
		e.pos += e.vel * delta
		if e.pos.x < lo.x or e.pos.x > hi.x:
			e.vel.x *= -1
			e.pos.x = clamp(e.pos.x, lo.x, hi.x)
		if e.pos.y < lo.y or e.pos.y > hi.y:
			e.vel.y *= -1
			e.pos.y = clamp(e.pos.y, lo.y, hi.y)

	queue_redraw()

func _draw() -> void:
	for e in enemies:
		draw_circle(e.pos, SIZE, e.color)
		draw_arc(e.pos, SIZE, 0, TAU, 24, Color.WHITE, 1.0)
