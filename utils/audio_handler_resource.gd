class_name AudioHandlerResource
extends Resource

@export var _audio_references: Array[AudioStream] = []
@export var _db_volumes: PackedFloat64Array = PackedFloat64Array()
@export var _pitch_scales: Array[PackedFloat64Array] = []


func _init(
	p_audio_references: Array = [],
	p_db_volumes: PackedFloat64Array = PackedFloat64Array(),
	p_pitch_scales: Array[PackedFloat64Array] = []
) -> void:
	_audio_references = p_audio_references
	_db_volumes = p_db_volumes
	_pitch_scales = p_pitch_scales


## Functions

func play(id_override = null, db_override = null, pitch_override = null) -> void:
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
