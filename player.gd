extends Node2D

const SPEED = 200.0
const RADIUS = 12.0
const MAP_W = 3200.0
const MAP_H = 2400.0
const ARENA_INSET = 52.0
const CORNER_R = 95.0

func _ready() -> void:
	position = Vector2(MAP_W / 2.0, MAP_H / 2.0)

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1

	if dir != Vector2.ZERO:
		position += dir.normalized() * SPEED * delta

	position = _clamp_rounded_rect(position, RADIUS)
	get_node("../Grid").update_player_pos(position)
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
		var dx = pos.x - c.x
		var dy = pos.y - c.y
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
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, Color(0.7, 0.7, 1.0), 1.5)
