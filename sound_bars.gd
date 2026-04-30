# sound_bars.gd
extends Node2D

const STRIP_SIZE    = 52
const MAP_W         = 3200.0
const MAP_H         = 2400.0
const LERP_SPEED    = 0.18

const CELL          = 5
const GAP           = 1
const STEP          = CELL + GAP
const DEPTH         = int(STRIP_SIZE / STEP)

const BAR_COLOR     = Color(0.0, 0.75, 0.85)
const BAR_DIM       = Color(0.02, 0.06, 0.08)
const BORDER_COLOR  = Color(0.0, 0.55, 0.65)
const STRIP_BG      = Color(0.0, 0.0, 0.0)

var h_count: int
var v_count: int
var current_levels: Array = []
var target_levels: Array = []
var time_elapsed: float = 0.0

func _ready():
	h_count = int(MAP_W / STEP)
	v_count = int(MAP_H / STEP)
	var total = 2 * h_count + 2 * v_count
	for _i in range(total):
		current_levels.append(0.0)
		target_levels.append(0.0)

func on_beat():
	for i in range(h_count):
		var bias = 1.0 - abs(float(i) - h_count / 2.0) / (h_count / 2.0)
		target_levels[i] = clamp(randf() + bias * 0.3, 0.0, 1.0)
		target_levels[h_count + i] = clamp(randf() + bias * 0.3, 0.0, 1.0)
	for i in range(v_count):
		var bias = 1.0 - abs(float(i) - v_count / 2.0) / (v_count / 2.0)
		target_levels[2 * h_count + i] = clamp(randf() + bias * 0.3, 0.0, 1.0)
		target_levels[2 * h_count + v_count + i] = clamp(randf() + bias * 0.3, 0.0, 1.0)
	queue_redraw()

func _process(delta):
	time_elapsed += delta
	var changed = false
	for i in range(current_levels.size()):
		var new_v = lerpf(current_levels[i], target_levels[i], LERP_SPEED) \
					+ sin(time_elapsed * 6.0 + i * 0.3) * 0.03
		new_v = clamp(new_v, 0.0, 1.0)
		if abs(new_v - current_levels[i]) > 0.005:
			changed = true
		current_levels[i] = new_v
	if changed:
		queue_redraw()

func _draw():
	var W = MAP_W
	var H = MAP_H

	draw_rect(Rect2(0, H - STRIP_SIZE, W, STRIP_SIZE), STRIP_BG)
	draw_rect(Rect2(0, 0, W, STRIP_SIZE), STRIP_BG)
	draw_rect(Rect2(0, 0, STRIP_SIZE, H), STRIP_BG)
	draw_rect(Rect2(W - STRIP_SIZE, 0, STRIP_SIZE, H), STRIP_BG)

	# bottom - lit cells near the arena border
	for i in range(h_count):
		var lit = int(current_levels[i] * DEPTH)
		var x = i * STEP
		for s in range(DEPTH):
			var sy = H - (s + 1) * STEP
			var c = BAR_COLOR if s >= (DEPTH - lit) else BAR_DIM
			draw_rect(Rect2(x, sy, CELL, CELL), c)

	# top - lit cells near the arena border
	for i in range(h_count):
		var lit = int(current_levels[h_count + i] * DEPTH)
		var x = i * STEP
		for s in range(DEPTH):
			var sy = s * STEP
			var c = BAR_COLOR if s >= (DEPTH - lit) else BAR_DIM
			draw_rect(Rect2(x, sy, CELL, CELL), c)

	# left - lit cells near the arena border
	for i in range(v_count):
		var lit = int(current_levels[2 * h_count + i] * DEPTH)
		var y = i * STEP
		for s in range(DEPTH):
			var sx = s * STEP
			var c = BAR_COLOR if s >= (DEPTH - lit) else BAR_DIM
			draw_rect(Rect2(sx, y, CELL, CELL), c)

	# right - lit cells near the arena border
	for i in range(v_count):
		var lit = int(current_levels[2 * h_count + v_count + i] * DEPTH)
		var y = i * STEP
		for s in range(DEPTH):
			var sx = W - (s + 1) * STEP
			var c = BAR_COLOR if s >= (DEPTH - lit) else BAR_DIM
			draw_rect(Rect2(sx, y, CELL, CELL), c)

	_draw_rounded_border(W, H)

func _draw_rounded_border(W, H):
	var r = 95.0
	var x0 = STRIP_SIZE
	var y0 = STRIP_SIZE
	var x1 = W - STRIP_SIZE
	var y1 = H - STRIP_SIZE
	var segs = 16

	draw_line(Vector2(x0 + r, y0), Vector2(x1 - r, y0), BORDER_COLOR, 1.0)
	draw_line(Vector2(x0 + r, y1), Vector2(x1 - r, y1), BORDER_COLOR, 1.0)
	draw_line(Vector2(x0, y0 + r), Vector2(x0, y1 - r), BORDER_COLOR, 1.0)
	draw_line(Vector2(x1, y0 + r), Vector2(x1, y1 - r), BORDER_COLOR, 1.0)

	draw_arc(Vector2(x0 + r, y0 + r), r, PI, 1.5 * PI, segs, BORDER_COLOR, 1.0)
	draw_arc(Vector2(x1 - r, y0 + r), r, 1.5 * PI, TAU, segs, BORDER_COLOR, 1.0)
	draw_arc(Vector2(x1 - r, y1 - r), r, 0, 0.5 * PI, segs, BORDER_COLOR, 1.0)
	draw_arc(Vector2(x0 + r, y1 - r), r, 0.5 * PI, PI, segs, BORDER_COLOR, 1.0)
