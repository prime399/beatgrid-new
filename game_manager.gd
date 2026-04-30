extends Node2D

enum State { MENU, PLAYING, LEVEL_CLEAR }

var state = State.MENU
var current_level: int = -1
var levels_cleared: Array = [false, false, false]
var clear_timer: float = 0.0

const CLEAR_DELAY = 2.0

func _ready():
	_set_gameplay_visible(false)

func start_level(level: int):
	current_level = level
	state = State.PLAYING
	clear_timer = 0.0
	_set_gameplay_visible(true)
	get_node("Player").reset_player()
	get_node("Enemies").setup_level(level)

func go_to_menu():
	state = State.MENU
	current_level = -1
	_set_gameplay_visible(false)
	get_node("Enemies").clear_all()

func on_level_cleared():
	if current_level >= 0 and current_level < 3:
		levels_cleared[current_level] = true
	state = State.LEVEL_CLEAR
	clear_timer = CLEAR_DELAY

func _process(delta: float) -> void:
	if state == State.LEVEL_CLEAR:
		clear_timer -= delta
		if clear_timer <= 0.0:
			go_to_menu()

func _set_gameplay_visible(vis: bool):
	get_node("Grid").visible = vis
	get_node("SoundBars").visible = vis
	get_node("Enemies").visible = vis
	get_node("Enemies").set_process(vis)
	get_node("Player").visible = vis
	get_node("Player").set_process(vis)
	get_node("Player").set_process_unhandled_input(vis)
