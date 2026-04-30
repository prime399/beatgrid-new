extends Node2D

const SPEED = 200.0
const SIZE = 16.0
const ARENA_INSET = 52.0

var color := Color(1.0, 0.902, 0.314)

func _ready() -> void:
	var screen = get_viewport_rect().size
	position = screen / 2.0

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

	var screen = get_viewport_rect().size
	position.x = clamp(position.x, ARENA_INSET + SIZE, screen.x - ARENA_INSET - SIZE)
	position.y = clamp(position.y, ARENA_INSET + SIZE, screen.y - ARENA_INSET - SIZE)

	get_node("../Grid").update_player_pos(position)
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0, -SIZE),
		Vector2(SIZE, 0),
		Vector2(0, SIZE),
		Vector2(-SIZE, 0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)
