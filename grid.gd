# grid.gd
extends Node2D

const CELL_SIZE      = 48
const BASE_COLOR     = Color(0.055, 0.055, 0.157, 1.0)
const GLOW_COLOR     = Color(1.0, 0.902, 0.314, 1.0)
const INFLUENCE_CELLS = 6
const MAP_W          = 3200.0
const MAP_H          = 2400.0

var player_pos : Vector2 = Vector2(-9999, -9999)

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
	var player_cell = (player_pos / CELL_SIZE).floor()
	var seg_cell    = (segment_mid / CELL_SIZE).floor()
	var dist        = max(abs(seg_cell.x - player_cell.x),
						  abs(seg_cell.y - player_cell.y))
	if dist >= INFLUENCE_CELLS:
		return BASE_COLOR
	var t = 1.0 - (float(dist) / INFLUENCE_CELLS)
	t     = pow(t, 1.6)
	return BASE_COLOR.lerp(GLOW_COLOR, t)

func update_player_pos(pos: Vector2):
	player_pos = pos
	queue_redraw()
