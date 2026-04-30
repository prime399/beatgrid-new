extends Node

const BPM = 120.0

var beat_interval: float
var timer: float = 0.0

func _ready() -> void:
	beat_interval = 60.0 / BPM

func _process(delta: float) -> void:
	timer += delta
	if timer >= beat_interval:
		timer -= beat_interval
		get_node("../SoundBars").on_beat()
