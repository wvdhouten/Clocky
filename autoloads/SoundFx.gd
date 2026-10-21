extends Node

## Soft sound effects synthesized in code (no audio files, no licensing):
## gentle bell-like tones with fast attack and exponential decay. Every
## button press gets a light "tap" automatically. Muting is a saved
## setting (toggled from the top bar).

const MIX_RATE := 22050
const MUTE_SETTING := "sound_muted"

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	# [frequency Hz, start s] per note; then total length, volume, decay rate,
	# and overtone mix (0 = pure sine, softer; >0 = brighter, bell-like).
	_streams["chime"] = _synth([[1046.5, 0.0], [1318.5, 0.08], [1568.0, 0.16]], 0.9, 0.38, 5.0, 0.3)
	_streams["boop"] = _synth([[392.0, 0.0], [329.6, 0.13]], 0.5, 0.30, 7.0, 0.0)
	_streams["tick"] = _synth([[1800.0, 0.0]], 0.035, 0.12, 140.0, 0.0)
	_streams["tap"] = _synth([[660.0, 0.0]], 0.07, 0.16, 55.0, 0.1)
	_streams["star"] = _synth([[1568.0, 0.0]], 0.45, 0.30, 8.0, 0.35)
	_streams["fanfare"] = _synth([[523.3, 0.0], [659.3, 0.12], [784.0, 0.24], [1046.5, 0.36]], 1.4, 0.40, 3.5, 0.3)

	get_tree().node_added.connect(_on_node_added)


func play(sound: String, pitch: float = 1.0) -> void:
	if is_muted() or not _streams.has(sound):
		return
	var player: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = _streams[sound]
	player.pitch_scale = pitch
	player.play()


func is_muted() -> bool:
	return bool(ProgressStore.get_setting(MUTE_SETTING, false))


func set_muted(muted: bool) -> void:
	ProgressStore.set_setting(MUTE_SETTING, muted)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("tap"))


func _synth(notes: Array, length: float, volume: float, decay: float, overtone: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * length)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for note in notes:
		var freq: float = note[0]
		var start: int = int(note[1] * MIX_RATE)
		for i in range(start, n):
			var t: float = float(i - start) / MIX_RATE
			var env: float = exp(-t * decay) * min(1.0, t * 250.0)
			var s: float = sin(TAU * freq * t) + overtone * sin(TAU * 2.0 * freq * t)
			buf[i] += s * env

	var peak: float = 0.0001
	for v in buf:
		peak = max(peak, abs(v))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clamp(buf[i] / peak * volume, -1.0, 1.0) * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
