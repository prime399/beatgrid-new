# sound_bars.gd
extends Node2D

const BAR_COUNT     = 28
const STRIP_SIZE    = 52
const MAX_H         = 44
const MIN_H         = 4
const BAR_GAP       = 2
const LERP_SPEED    = 0.18

# Colors per side [from_color, to_color]
const SIDE_COLORS = [
	[Color(0.31, 0.0, 1.0), Color(1.0, 0.0, 0.71)],   # bottom
	[Color(0.31, 0.0, 1.0), Color(1.0, 0.0, 0.71)],   # top
	[Color(0.31, 0.0, 1.0), Color(1.0, 0.0, 0.71)],   # left
	[Color(1.0, 0.0, 0.71), Color(0.31, 0.0, 1.0)],   # right (mirrored)
]

var current_heights : Array = []
var target_heights  : Array = []
var time_elapsed    : float = 0.0

func _ready():
	# 4 sides × BAR_COUNT bars each
	for _i in range(4 * BAR_COUNT):
		current_heights.append(MIN_H)
		target_heights.append(MIN_H)

func on_beat():
	# Called externally by your beat/rhythm manager on each beat
	for i in range(4 * BAR_COUNT):
		# gaussian-ish weighting — center bars taller
		var center_bias = 1.0 - abs((i % BAR_COUNT) - BAR_COUNT / 2.0) / (BAR_COUNT / 2.0)
		var base_h      = randf_range(MIN_H, MAX_H)
		target_heights[i] = clamp(base_h + center_bias * 12.0, MIN_H, MAX_H)
	queue_redraw()

func _process(delta):
	time_elapsed += delta
	var changed = false
	for i in range(4 * BAR_COUNT):
		var new_h = lerpf(current_heights[i], target_heights[i], LERP_SPEED) \
					+ sin(time_elapsed * 6.0 + i * 0.4) * 1.5
		new_h = clamp(new_h, MIN_H, MAX_H)
		if abs(new_h - current_heights[i]) > 0.1:
			changed = true
		current_heights[i] = new_h
	if changed:
		queue_redraw()

func _draw():
	var W  = get_viewport_rect().size.x
	var H  = get_viewport_rect().size.y
	var bar_w = (W - BAR_GAP * (BAR_COUNT - 1)) / BAR_COUNT

	# Dark strip backgrounds
	draw_rect(Rect2(0, H - STRIP_SIZE, W, STRIP_SIZE), Color(0.008, 0.008, 0.04))
	draw_rect(Rect2(0, 0, W, STRIP_SIZE),              Color(0.008, 0.008, 0.04))
	draw_rect(Rect2(0, 0, STRIP_SIZE, H),              Color(0.008, 0.008, 0.04))
	draw_rect(Rect2(W - STRIP_SIZE, 0, STRIP_SIZE, H), Color(0.008, 0.008, 0.04))

	# BOTTOM bars (grow upward)
	_draw_bars_horizontal(0, W, H, bar_w, false, 0)
	# TOP bars (grow downward)
	_draw_bars_horizontal(BAR_COUNT, W, H, bar_w, true, 1)
	# LEFT bars (grow rightward) 
	_draw_bars_vertical(2 * BAR_COUNT, W, H, bar_w, false, 2)
	# RIGHT bars (grow leftward)
	_draw_bars_vertical(3 * BAR_COUNT, W, H, bar_w, true, 3)

	# Arena border lines (drawn last, on top)
	var lc = Color(0.157, 0.157, 0.392)
	draw_line(Vector2(STRIP_SIZE, STRIP_SIZE),
			  Vector2(W - STRIP_SIZE, STRIP_SIZE), lc, 1.0)
	draw_line(Vector2(STRIP_SIZE, H - STRIP_SIZE),
			  Vector2(W - STRIP_SIZE, H - STRIP_SIZE), lc, 1.0)
	draw_line(Vector2(STRIP_SIZE, STRIP_SIZE),
			  Vector2(STRIP_SIZE, H - STRIP_SIZE), lc, 1.0)
	draw_line(Vector2(W - STRIP_SIZE, STRIP_SIZE),
			  Vector2(W - STRIP_SIZE, H - STRIP_SIZE), lc, 1.0)

func _draw_bars_horizontal(offset, W, H, bar_w, flip, side_idx):
	for i in range(BAR_COUNT):
		var h   = current_heights[offset + i]
		var x   = i * (bar_w + BAR_GAP)
		var y   = H - STRIP_SIZE if not flip else 0.0
		var rect = Rect2(x, y if flip else y + STRIP_SIZE - h, bar_w, h)
		var c   = SIDE_COLORS[side_idx][0].lerp(
					  SIDE_COLORS[side_idx][1], float(i) / BAR_COUNT)
		draw_rect(rect, c)

func _draw_bars_vertical(offset, W, H, bar_w, flip, side_idx):
	var bar_h_each = (H - BAR_GAP * (BAR_COUNT - 1)) / BAR_COUNT
	for i in range(BAR_COUNT):
		var w   = current_heights[offset + i]
		var y   = i * (bar_h_each + BAR_GAP)
		var x   = 0.0 if not flip else W - STRIP_SIZE
		var rect = Rect2(x if not flip else W - w, y, w, bar_h_each)
		var c   = SIDE_COLORS[side_idx][0].lerp(
					  SIDE_COLORS[side_idx][1], float(i) / BAR_COUNT)
		draw_rect(rect, c)
