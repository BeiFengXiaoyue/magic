class_name DeterministicRng
extends RefCounted

## 确定性随机（契约 03）。所有影响持久状态的随机只从这里取。

const STREAM_NAMES: Array[String] = [
	"craft",
	"gather",
	"device",
	"market",
	"event",
	"letters",
]

var world_seed: int = 0

var _streams: Dictionary = {}


func init_world(seed_value: int) -> void:
	world_seed = seed_value
	_streams.clear()
	for stream_name in STREAM_NAMES:
		_streams[stream_name] = _make_stream(stream_name)


func stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		push_error("DeterministicRng: 未知随机流 %s" % stream_name)
		_streams[stream_name] = _make_stream(stream_name)
	return _streams[stream_name]


func snapshot() -> Dictionary:
	var data: Dictionary = {}
	for stream_name in _streams:
		var rng: RandomNumberGenerator = _streams[stream_name]
		data[stream_name] = rng.state
	return data


func restore(data: Dictionary) -> void:
	for stream_name in data:
		if not _streams.has(stream_name):
			_streams[stream_name] = _make_stream(stream_name)
		var rng: RandomNumberGenerator = _streams[stream_name]
		rng.state = int(data[stream_name])


func _make_stream(stream_name: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("codex:%d:%s" % [world_seed, stream_name])
	return rng
