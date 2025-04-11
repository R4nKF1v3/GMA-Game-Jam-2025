@tool
extends Node
class_name AudioHandler

@export var _test: bool = false:
	set(value):
		_test = false
		_run_test()

@export var _test_index: int = 0:
	set(value):
		_test_index = clamp(value, 0, max(_audio_references.size() - 1, 0))

@export var _audio_references: Array[AudioStream] = []:
	set(value):
		_audio_references = value

@export var _db_volumes: PackedFloat64Array = []:
	set(value):
		_db_volumes = value

@export var _pitch_scales: Array[PackedFloat64Array] = []:
	set(value):
		_pitch_scales = value

func _run_test() -> void:
	if _audio_references.is_empty():
		return

	var audio_stream := AudioStreamPlayer.new()
	add_child(audio_stream)
	audio_stream.stream = _audio_references[_test_index]
	audio_stream.volume_db = _get_db_volume(_test_index)
	audio_stream.pitch_scale = _get_pitch_scale(_test_index)
	audio_stream.play()

	audio_stream.finished.connect(_on_audio_test_finished.bind(audio_stream))


func _on_audio_test_finished(player: AudioStreamPlayer) -> void:
	if not player.playing:
		remove_child(player)
		player.queue_free()


func play(
	delay: float = 0.0,
	id_override = null,
	db_override = null,
	pitch_override = null
) -> void:
	if delay > 0.0:
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(_play.bind(id_override, db_override, pitch_override))
	else:
		_play(id_override, db_override, pitch_override)


func _play(
	id_override = null,
	db_override = null,
	pitch_override = null
) -> void:
	if _audio_references.is_empty():
		return
	var selected_index: int = id_override if typeof(id_override) == TYPE_INT and id_override >= 0 and id_override < _audio_references.size() else randi() % _audio_references.size()
	var db: float = float(db_override) if typeof(db_override) in [TYPE_FLOAT, TYPE_INT] else _get_db_volume(selected_index)
	var pitch: float = float(pitch_override) if typeof(pitch_override) in [TYPE_FLOAT, TYPE_INT] else _get_pitch_scale(selected_index)
	AudioManager.play_sfx(_audio_references[selected_index], db, pitch)


func _get_db_volume(index: int) -> float:
	return _db_volumes[index] if index < _db_volumes.size() else 0.0


func _get_pitch_scale(index: int) -> float:
	if index < _pitch_scales.size():
		var pitches: PackedFloat64Array = _pitch_scales[index]
		if not pitches.is_empty():
			return randf_range(pitches[0], pitches[1]) if pitches.size() > 1 else pitches[0]
	return 1.0
