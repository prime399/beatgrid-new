extends Node2D

const SPEED = 200.0
const RADIUS = 12.0
const ARENA_INSET = 52.0
const MAP_W = 3200.0
const MAP_H = 2400.0

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

	position.x = clamp(position.x, ARENA_INSET + RADIUS, MAP_W - ARENA_INSET - RADIUS)
	position.y = clamp(position.y, ARENA_INSET + RADIUS, MAP_H - ARENA_INSET - RADIUS)

	get_node("../Grid").update_player_pos(position)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, Color(0.7, 0.7, 1.0), 1.5)
