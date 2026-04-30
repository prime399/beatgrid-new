extends Node2D

const SPEED = 200.0
const RADIUS = 12.0
const MAP_W = 3200.0
const MAP_H = 2400.0
const ARENA_INSET = 52.0
const CORNER_R = 95.0

const LASER_DAMAGE = 1
const LASER_HIT_RADIUS = 20.0
const LASER_FADE_TIME = 0.7

const SHIELD_MIN_W = 40.0
const SHIELD_MAX_W = 180.0
const SHIELD_TRAVEL = 500.0
const SHIELD_DURATION = 1.25
const SHIELD_PUSH = 500.0
const SHIELD_HIT_THICKNESS = 25.0

const MAX_BARS = 4
const HP_PER_BAR = 3
const MAX_HP = MAX_BARS * HP_PER_BAR
const INVULN_TIME = 0.8

var laser_active: bool = false
var laser_segments: Array = []
var laser_timer: float = 0.0

var shield_active: bool = false
var shield_timer: float = 0.0
var shield_dir: Vector2
var shield_origin: Vector2

var hp: int = MAX_HP
var invuln_timer: float = 0.0

func _ready() -> void:
	position = Vector2(MAP_W / 2.0, MAP_H / 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			_fire_laser()
		elif event.keycode == KEY_S and not shield_active:
			_fire_shield()

func take_damage(amount: int):
	if invuln_timer > 0.0:
		return
	hp = max(hp - amount, 0)
	invuln_timer = INVULN_TIME

func _fire_laser():
	var mouse_world = get_global_mouse_position()
	var dir = (mouse_world - position)
	var dist = dir.length()
	if dist < 1.0:
		return
	dir = dir.normalized()
	var start = position + dir * 15.0
	var end = position + dir * dist
	laser_active = true
	laser_timer = LASER_FADE_TIME

	var enemies_node = get_node("../Enemies")
	laser_segments = enemies_node.chain_laser(start, end, LASER_HIT_RADIUS, LASER_DAMAGE)

	get_node("../Grid").set_chain_laser(laser_segments, LASER_FADE_TIME)

func _fire_shield():
	var mouse_world = get_global_mouse_position()
	var dir = (mouse_world - position)
	if dir.length() < 1.0:
		return
	shield_dir = dir.normalized()
	shield_origin = position + shield_dir * 20.0
	shield_active = true
	shield_timer = 0.0

func _get_shield_state(t: float) -> Dictionary:
	var travel_pos = shield_origin + shield_dir * SHIELD_TRAVEL * t
	var half_w = lerp(SHIELD_MIN_W, SHIELD_MAX_W, t) * 0.5
	var perp = Vector2(-shield_dir.y, shield_dir.x)
	return {
		"center": travel_pos,
		"a": travel_pos + perp * half_w,
		"b": travel_pos - perp * half_w,
	}

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

	if laser_active:
		laser_timer -= delta
		if laser_timer <= 0.0:
			laser_active = false

	if shield_active:
		shield_timer += delta
		var t = shield_timer / SHIELD_DURATION
		if t >= 1.0:
			shield_active = false
		else:
			var state = _get_shield_state(t)
			get_node("../Enemies").repel_from_line(
				state.a, state.b, SHIELD_HIT_THICKNESS, shield_dir, SHIELD_PUSH, delta)

	if invuln_timer > 0.0:
		invuln_timer -= delta

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
	var blink = invuln_timer > 0.0 and int(invuln_timer * 10) % 2 == 0
	if not blink:
		draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
		draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, Color(0.7, 0.7, 1.0), 1.5)

	if laser_active:
		var alpha = laser_timer / LASER_FADE_TIME
		for seg in laser_segments:
			var ls = seg.from - position
			var le = seg.to - position
			draw_line(ls, le, Color(0.2, 0.5, 1.0, alpha * 0.3), 12.0)
			draw_line(ls, le, Color(0.4, 0.7, 1.0, alpha * 0.6), 4.0)
			draw_line(ls, le, Color(0.8, 0.9, 1.0, alpha), 1.5)
		for i in range(1, laser_segments.size()):
			var hit_pos = laser_segments[i].from - position
			var ring_alpha = alpha * 0.8
			draw_arc(hit_pos, 15.0 * (1.0 + (1.0 - alpha) * 0.5), 0, TAU, 16, Color(0.5, 0.8, 1.0, ring_alpha * 0.4), 3.0)
			draw_arc(hit_pos, 8.0, 0, TAU, 12, Color(0.8, 0.95, 1.0, ring_alpha), 2.0)

	if shield_active:
		var t = shield_timer / SHIELD_DURATION
		var state = _get_shield_state(t)
		var alpha = 1.0 - t
		var la = state.a - position
		var lb = state.b - position
		draw_line(la, lb, Color(0.3, 0.8, 1.0, alpha * 0.15), 20.0)
		draw_line(la, lb, Color(0.4, 0.85, 1.0, alpha * 0.5), 6.0)
		draw_line(la, lb, Color(0.7, 0.95, 1.0, alpha), 2.0)

	_draw_hp_bars()

func _draw_hp_bars():
	var bar_w = 10.0
	var bar_h = 4.0
	var gap = 2.0
	var total_w = MAX_BARS * bar_w + (MAX_BARS - 1) * gap
	var start_x = -total_w / 2.0
	var y = RADIUS + 8.0

	for i in range(MAX_BARS):
		var x = start_x + i * (bar_w + gap)
		var bar_hp = clamp(hp - i * HP_PER_BAR, 0, HP_PER_BAR)
		var fill = float(bar_hp) / HP_PER_BAR

		draw_rect(Rect2(x, y, bar_w, bar_h), Color(0.15, 0.15, 0.15))
		if fill > 0:
			var c = Color(0.2, 1.0, 0.4) if fill > 0.33 else Color(1.0, 0.3, 0.2)
			draw_rect(Rect2(x, y, bar_w * fill, bar_h), c)
		draw_rect(Rect2(x, y, bar_w, bar_h), Color(0.5, 0.5, 0.5), false, 1.0)
