# grid.gd
extends Node2D

const CELL_SIZE        = 48
const BASE_COLOR       = Color(0.0, 0.0, 0.0, 1.0)
const GLOW_COLOR       = Color(1.0, 0.902, 0.314, 1.0)
const LASER_GLOW_COLOR = Color(0.3, 0.6, 1.0)
const INFLUENCE_RADIUS = 10.0
const LASER_GLOW_RADIUS = 4.0
const MAP_W            = 3200.0
const MAP_H            = 2400.0

var player_pos: Vector2 = Vector2(-9999, -9999)
var laser_segments: Array = []
var laser_alpha: float = 0.0
var laser_fade_total: float = 0.0

func _process(delta: float) -> void:
	if laser_alpha > 0.0:
		laser_alpha -= delta / laser_fade_total if laser_fade_total > 0 else 1.0
		if laser_alpha <= 0.0:
			laser_alpha = 0.0
		queue_redraw()

func set_chain_laser(segments: Array, fade_time: float):
	laser_segments = segments
	laser_alpha = 1.0
	laser_fade_total = fade_time
	queue_redraw()

func _draw():
	var cols = int(MAP_W / CELL_SIZE) + 1
	var rows = int(MAP_H / CELL_SIZE) + 1

	for c in range(cols):
		var x = c * CELL_SIZE
		for r in range(rows - 1):
			var y_start = r * CELL_SIZE
			var y_end   = y_start + CELL_SIZE
			var mid     = Vector2(x, (y_start + y_end) / 2.0)
			draw_line(Vector2(x, y_start), Vector2(x, y_end),
					  _get_line_color(mid), 1.0)

	for r in range(rows):
		var y = r * CELL_SIZE
		for c in range(cols - 1):
			var x_start = c * CELL_SIZE
			var x_end   = x_start + CELL_SIZE
			var mid     = Vector2((x_start + x_end) / 2.0, y)
			draw_line(Vector2(x_start, y), Vector2(x_end, y),
					  _get_line_color(mid), 1.0)

func _get_line_color(segment_mid: Vector2) -> Color:
	var color = BASE_COLOR

	var dist = segment_mid.distance_to(player_pos) / CELL_SIZE
	if dist < INFLUENCE_RADIUS:
		var t = 1.0 - (dist / INFLUENCE_RADIUS)
		t = t * t * t
		color = color.lerp(GLOW_COLOR, t)

	if laser_alpha > 0.0:
		var best_lt = 0.0
		for seg in laser_segments:
			var laser_dist = _point_to_segment_dist(segment_mid, seg.from, seg.to) / CELL_SIZE
			if laser_dist < LASER_GLOW_RADIUS:
				var lt = (1.0 - laser_dist / LASER_GLOW_RADIUS) * laser_alpha
				lt = lt * lt
				if lt > best_lt:
					best_lt = lt
		if best_lt > 0.0:
			color = color.lerp(LASER_GLOW_COLOR, best_lt)

	return color

func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var len_sq = ab.length_squared()
	if len_sq < 0.001:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var proj = a + ab * t
	return p.distance_to(proj)

func update_player_pos(pos: Vector2):
	player_pos = pos
	queue_redraw()
