extends Node2D

const LEVEL_NAMES = ["SECTOR A", "SECTOR B", "SECTOR C"]
const LEVEL_DESCS = [
	"Triangles only - clear the swarm",
	"Triangles & Squares - mixed threat",
	"All enemies + Hexagon boss",
]

var hovered_level: int = -1
var hovered_back: bool = false
var card_rects: Array = []
var back_rect: Rect2 = Rect2()

func _ready():
	mouse_filter_pass()

func mouse_filter_pass():
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var gm = get_node("/root/Node2D")
		if gm.state == gm.State.MENU:
			if hovered_level >= 0:
				gm.start_level(hovered_level)
		elif gm.state == gm.State.PLAYING:
			if hovered_back:
				gm.go_to_menu()

func _update_hover(mpos: Vector2):
	var gm = get_node("/root/Node2D")
	hovered_level = -1
	hovered_back = false
	if gm.state == gm.State.MENU:
		for i in range(card_rects.size()):
			if card_rects[i].has_point(mpos):
				hovered_level = i
				break
	elif gm.state == gm.State.PLAYING:
		if back_rect.has_point(mpos):
			hovered_back = true

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var gm = get_node("/root/Node2D")
	var vp = get_viewport_rect().size

	if gm.state == gm.State.MENU:
		_draw_menu(vp, gm)
	elif gm.state == gm.State.PLAYING:
		_draw_back_button(vp)
	elif gm.state == gm.State.LEVEL_CLEAR:
		_draw_clear_screen(vp, gm)

func _draw_menu(vp: Vector2, gm) -> void:
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.95))

	var title_x = vp.x / 2.0
	var title_y = vp.y * 0.12
	_draw_text_centered("B E A T G R I D", Vector2(title_x, title_y), 32, Color(0.0, 0.85, 0.9))
	_draw_text_centered("SELECT SECTOR", Vector2(title_x, title_y + 40), 16, Color(0.5, 0.5, 0.6))

	card_rects.clear()
	var card_w = 280.0
	var card_h = 180.0
	var gap = 40.0
	var total_w = 3 * card_w + 2 * gap
	var start_x = (vp.x - total_w) / 2.0
	var card_y = vp.y * 0.35

	for i in range(3):
		var x = start_x + i * (card_w + gap)
		var rect = Rect2(x, card_y, card_w, card_h)
		card_rects.append(rect)

		var is_hovered = (hovered_level == i)
		var is_cleared = gm.levels_cleared[i]

		var bg = Color(0.08, 0.08, 0.12)
		if is_hovered:
			bg = Color(0.12, 0.15, 0.22)
		draw_rect(rect, bg)

		var border_color = Color(0.0, 0.55, 0.65)
		if is_cleared:
			border_color = Color(0.2, 1.0, 0.4)
		if is_hovered:
			border_color = border_color.lightened(0.3)
		_draw_rect_border(rect, border_color, 2.0)

		var cx = x + card_w / 2.0
		var level_num = "LEVEL " + str(i + 1)
		_draw_text_centered(level_num, Vector2(cx, card_y + 30), 14, Color(0.4, 0.4, 0.5))
		_draw_text_centered(LEVEL_NAMES[i], Vector2(cx, card_y + 60), 20, Color(0.0, 0.85, 0.9) if not is_cleared else Color(0.2, 1.0, 0.4))

		_draw_level_preview(i, Vector2(cx, card_y + 100))

		var desc_color = Color(0.45, 0.45, 0.55)
		_draw_text_centered(LEVEL_DESCS[i], Vector2(cx, card_y + 140), 11, desc_color)

		if is_cleared:
			_draw_text_centered("CLEARED", Vector2(cx, card_y + 165), 12, Color(0.2, 1.0, 0.4))

func _draw_level_preview(level: int, center: Vector2):
	var spacing = 22.0
	match level:
		0:
			for j in range(3):
				var px = center.x + (j - 1) * spacing
				_draw_mini_triangle(Vector2(px, center.y), 8.0, TRI_PREVIEW_COLOR)
		1:
			_draw_mini_triangle(Vector2(center.x - spacing, center.y), 7.0, TRI_PREVIEW_COLOR)
			_draw_mini_square(Vector2(center.x, center.y), 7.0, SQR_PREVIEW_COLOR)
			_draw_mini_triangle(Vector2(center.x + spacing, center.y), 7.0, TRI_PREVIEW_COLOR)
		2:
			_draw_mini_triangle(Vector2(center.x - spacing * 1.5, center.y), 6.0, TRI_PREVIEW_COLOR)
			_draw_mini_square(Vector2(center.x - spacing * 0.5, center.y), 6.0, SQR_PREVIEW_COLOR)
			_draw_mini_hexagon(Vector2(center.x + spacing * 0.5, center.y), 10.0, Color(0.95, 0.95, 0.95))
			_draw_mini_square(Vector2(center.x + spacing * 1.5, center.y), 6.0, SQR_PREVIEW_COLOR)

const TRI_PREVIEW_COLOR = Color(0.85, 0.75, 0.55)
const SQR_PREVIEW_COLOR = Color(0.6, 0.3, 0.8)

func _draw_mini_triangle(pos: Vector2, size: float, c: Color):
	var pts = PackedVector2Array()
	for i in range(3):
		var a = float(i) * TAU / 3.0 - PI / 2.0
		pts.append(pos + Vector2.from_angle(a) * size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.0)

func _draw_mini_square(pos: Vector2, size: float, c: Color):
	var pts = PackedVector2Array()
	for i in range(4):
		var a = float(i) * TAU / 4.0 + PI / 4.0
		pts.append(pos + Vector2.from_angle(a) * size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.0)

func _draw_mini_hexagon(pos: Vector2, size: float, c: Color):
	var pts = PackedVector2Array()
	for i in range(6):
		var a = float(i) * TAU / 6.0
		pts.append(pos + Vector2.from_angle(a) * size)
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.0)

func _draw_back_button(vp: Vector2):
	var bw = 80.0
	var bh = 30.0
	var margin = 12.0
	back_rect = Rect2(margin, margin, bw, bh)
	var bg = Color(0.1, 0.1, 0.15, 0.8)
	if hovered_back:
		bg = Color(0.15, 0.18, 0.25, 0.9)
	draw_rect(back_rect, bg)
	_draw_rect_border(back_rect, Color(0.0, 0.55, 0.65), 1.0)
	_draw_text_centered("MENU", Vector2(margin + bw / 2.0, margin + bh / 2.0 + 4), 12, Color(0.0, 0.85, 0.9))

func _draw_clear_screen(vp: Vector2, gm):
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.7))
	var name = LEVEL_NAMES[gm.current_level] if gm.current_level >= 0 else ""
	_draw_text_centered(name + " CLEARED", Vector2(vp.x / 2.0, vp.y / 2.0 - 20), 28, Color(0.2, 1.0, 0.4))
	_draw_text_centered("Returning to menu...", Vector2(vp.x / 2.0, vp.y / 2.0 + 20), 14, Color(0.5, 0.5, 0.6))

func _draw_rect_border(rect: Rect2, color: Color, width: float):
	var tl = rect.position
	var tr = Vector2(rect.end.x, rect.position.y)
	var br = rect.end
	var bl = Vector2(rect.position.x, rect.end.y)
	draw_line(tl, tr, color, width)
	draw_line(tr, br, color, width)
	draw_line(br, bl, color, width)
	draw_line(bl, tl, color, width)

func _draw_text_centered(text: String, pos: Vector2, size: int, color: Color):
	var font = ThemeDB.fallback_font
	var text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(pos.x - text_w / 2.0, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
